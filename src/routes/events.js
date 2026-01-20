import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import stripe from "../lib/stripe.js";

const router = express.Router();
const FEATURED_FOLLOWER_THRESHOLD = 500;
const isFeaturedByFollowers = (user) => {
  if (!user) return false;
  const followerCount = Number(user.follower_count || 0);
  const userType = (user.user_type || user.userType || "").toLowerCase();
  return (userType === "host" || userType === "talent") && followerCount >= FEATURED_FOLLOWER_THRESHOLD;
};

// Helper function to safely convert date to ISO8601 string
const toISOString = (dateValue) => {
  if (!dateValue) return new Date().toISOString();
  try {
    const date = dateValue instanceof Date ? dateValue : new Date(dateValue);
    if (isNaN(date.getTime())) {
      console.warn("Invalid date value:", dateValue);
      return new Date().toISOString();
    }
    return date.toISOString();
  } catch (err) {
    console.error("Error converting date to ISO8601:", err, dateValue);
    return new Date().toISOString();
  }
};

const normalizeTalentIds = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) return value.map(id => id?.toString()).filter(Boolean);
  if (typeof value === "string") {
    return value
      .split(",")
      .map(id => id.trim())
      .filter(id => id.length > 0);
  }
  return [value.toString()].filter(Boolean);
};

const normalizeRoles = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) {
    return value
      .map(role => (role ?? "").toString().trim())
      .filter(role => role.length > 0);
  }
  if (typeof value === "string") {
    return value
      .split(/[,|]/)
      .map(role => role.trim())
      .filter(role => role.length > 0);
  }
  return [value.toString()].filter(Boolean);
};

const normalizeImages = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) return value.filter(Boolean);
  if (typeof value === "string") {
    return value
      .split(",")
      .map(item => item.trim())
      .filter(item => item.length > 0);
  }
  return [value.toString()].filter(Boolean);
};

const verifyJwtToken = (token) => {
  const secrets = [];
  if (process.env.JWT_SECRET) secrets.push(process.env.JWT_SECRET);
  if (process.env.JWT_SECRET_FALLBACK) secrets.push(process.env.JWT_SECRET_FALLBACK);
  if (!process.env.JWT_SECRET || process.env.NODE_ENV !== "production") {
    secrets.push("your-secret-key-change-in-production");
  }

  let lastError;
  for (const secret of secrets) {
    try {
      return jwt.verify(token, secret);
    } catch (err) {
      lastError = err;
    }
  }

  throw lastError || new Error("Invalid token");
};

const resolveStripeClient = (req) => {
  const mode = req.body?.mode || req.query?.mode || req.headers["x-stripe-mode"];
  if (typeof stripe.getStripeClient === "function") {
    return stripe.getStripeClient(mode);
  }
  return stripe;
};

const ensureHostStripeReady = async (req, userId) => {
  const stripeClient = resolveStripeClient(req);
  if (!stripeClient || !stripeClient.accounts) {
    return { ok: false, status: 500, message: "Stripe is not configured" };
  }

  const userResult = await db.query(
    "SELECT stripe_account_id FROM users WHERE id = $1",
    [userId]
  );
  const stripeAccountId = userResult.rows[0]?.stripe_account_id;
  if (!stripeAccountId) {
    return { ok: false, status: 400, message: "Connect Stripe before creating ticketed events." };
  }

  const account = await stripeClient.accounts.retrieve(stripeAccountId);
  const capabilities = account?.capabilities || {};
  const hasTransferCapability = ["transfers", "legacy_payments", "crypto_transfers"].some(
    capability => capabilities[capability] === "active"
  );
  const hasOutstandingRequirements = Array.isArray(account?.requirements?.currently_due) &&
    account.requirements.currently_due.length > 0;

  if (!hasTransferCapability || hasOutstandingRequirements) {
    return {
      ok: false,
      status: 400,
      message: "Complete Stripe onboarding to enable payouts before hosting ticketed events."
    };
  }

  return { ok: true, stripeAccountId };
};

const buildLookingForLabel = (roles = [], legacy = null, notes = null) => {
  const cleanRoles = normalizeRoles(roles);
  const parts = [];

  if (cleanRoles.length > 0) {
    parts.push(cleanRoles.join(", "));
  } else if (legacy && legacy.trim()) {
    parts.push(legacy.trim());
  }

  if (notes && notes.trim()) {
    parts.push(notes.trim());
  }

  const label = parts.join(" — ").trim();
  return label.length > 0 ? label : null;
};

let eventsLookingForColumnsEnsured = false;
let eventsLookingForColumnsPromise = null;
const ensureEventsLookingForColumns = async () => {
  if (eventsLookingForColumnsEnsured) return;
  if (eventsLookingForColumnsPromise) return eventsLookingForColumnsPromise;

  eventsLookingForColumnsPromise = (async () => {
    await db.query(
      `ALTER TABLE events
       ADD COLUMN IF NOT EXISTS looking_for_roles TEXT[] DEFAULT '{}'::text[]`
    );
    await db.query(
      `ALTER TABLE events
       ADD COLUMN IF NOT EXISTS looking_for_notes TEXT`
    );
    await db.query(
      `ALTER TABLE events
       ADD COLUMN IF NOT EXISTS looking_for_talent_type TEXT`
    );
    await db.query(
      `ALTER TABLE events
       ADD COLUMN IF NOT EXISTS talent_ids TEXT[] DEFAULT '{}'::text[]`
    );
    await db.query(
      `ALTER TABLE events
       ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}'::text[]`
    );
    await db.query(
      `UPDATE events
       SET looking_for_roles = ARRAY[looking_for_talent_type]
       WHERE looking_for_talent_type IS NOT NULL
         AND looking_for_talent_type <> ''
         AND (looking_for_roles IS NULL OR array_length(looking_for_roles, 1) = 0)`
    );
    await db.query(
      `UPDATE events
       SET looking_for_roles = '{}'::text[]
       WHERE looking_for_roles IS NULL`
    );
    await db.query(
      `UPDATE events
       SET talent_ids = '{}'::text[]
       WHERE talent_ids IS NULL`
    );
    await db.query(
      `UPDATE events
       SET images = '{}'::text[]
       WHERE images IS NULL`
    );

    eventsLookingForColumnsEnsured = true;
  })().catch((err) => {
    eventsLookingForColumnsPromise = null;
    throw err;
  });

  return eventsLookingForColumnsPromise;
};

// GET FEATURED EVENTS (hosts/talent with 500+ followers)
router.get("/featured", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT DISTINCT
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.follower_count,
        u.user_type
      FROM events e
      INNER JOIN users u ON e.creator_id = u.id
      WHERE e.event_date > NOW()
        AND u.user_type IN ('host', 'talent')
        AND COALESCE(u.follower_count, 0) >= $1
        AND COALESCE(e.status, 'published') <> 'cancelled'
      ORDER BY u.follower_count DESC, e.event_date ASC
      LIMIT 20`,
      [FEATURED_FOLLOWER_THRESHOLD]
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
      const lookingForRoles = normalizeRoles(row.looking_for_roles);
      const lookingForNotes = row.looking_for_notes || null;
      const lookingForLabel = buildLookingForLabel(lookingForRoles, row.looking_for_talent_type, lookingForNotes);
      const isFeatured = isFeaturedByFollowers(row);
      return {
        id: eventId,
        title: row.title,
        description: row.description || "",
        hostId: row.creator_id?.toString() || "",
        hostName: row.host_name || row.host_username || "Unknown Host",
        hostAvatar: row.host_avatar || null,
        date: toISOString(row.event_date),
        location: row.location || "",
        images: normalizeImages(row.images),
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: row.attendee_count || 0,
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured,
        qrCode: qrCode,
        talentIds: normalizeTalentIds(row.talent_ids),
        lookingForRoles,
        lookingForNotes,
        lookingForTalentType: lookingForLabel
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get featured events error:", err);
    res.status(500).json({ error: "Failed to fetch featured events" });
  }
});

// GET NEARBY EVENTS (requires authentication)
router.get("/nearby", async (req, res) => {
  try {
    // Get user location from query params or headers (in production, get from user's profile)
    const { latitude, longitude, radius = 50 } = req.query; // radius in km, default 50km

    // Return upcoming events (excluding featured ones, or include them but mark them)
    // In production, filter by location using PostGIS or calculate distance
    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.follower_count,
        u.user_type,
        CASE 
          WHEN u.user_type IN ('host','talent') AND COALESCE(u.follower_count, 0) >= $1 THEN true 
          ELSE false 
        END as auto_featured
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      WHERE e.event_date > NOW()
        AND COALESCE(e.status, 'published') <> 'cancelled'
      ORDER BY e.event_date ASC
      LIMIT 50`,
      [FEATURED_FOLLOWER_THRESHOLD]
    );

    // Format events to match iOS expectations
    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
      const lookingForRoles = normalizeRoles(row.looking_for_roles);
      const lookingForNotes = row.looking_for_notes || null;
      const lookingForLabel = buildLookingForLabel(lookingForRoles, row.looking_for_talent_type, lookingForNotes);
      return {
        id: eventId,
        title: row.title,
        description: row.description || "",
        hostId: row.creator_id?.toString() || "",
        hostName: row.host_name || row.host_username || "Unknown Host",
        hostAvatar: row.host_avatar || null,
        date: toISOString(row.event_date),
        location: row.location || "",
        images: normalizeImages(row.images),
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: row.attendee_count || 0,
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured: row.auto_featured || false,
        qrCode: qrCode,
        talentIds: normalizeTalentIds(row.talent_ids),
        lookingForRoles,
        lookingForNotes,
        lookingForTalentType: lookingForLabel
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get nearby events error:", err);
    res.status(500).json({ error: "Failed to fetch events" });
  }
});

// GET EVENTS LOOKING FOR TALENT (by role list or single role)
router.get("/looking-for/:role?", async (req, res) => {
  try {
    await ensureEventsLookingForColumns();
    const roleParam = req.params.role;
    const roleQuery = req.query.roles;

    const roleListFromQuery = roleQuery
      ? roleQuery.split(",").map(r => r.trim()).filter(Boolean)
      : [];
    const normalizedRoles = normalizeRoles(roleParam ? [roleParam, ...roleListFromQuery] : roleListFromQuery);
    const loweredRoles = normalizedRoles.map(r => r.toLowerCase());

    let roleFilter = "";
    const params = [FEATURED_FOLLOWER_THRESHOLD];

    if (loweredRoles.length > 0) {
      params.push(loweredRoles);
      const roleParamIndex = params.length;
      roleFilter = `
        AND (
          EXISTS (
            SELECT 1 FROM unnest(e.looking_for_roles) AS role
            WHERE LOWER(role) = ANY($${roleParamIndex}::text[])
          )
          OR LOWER(e.looking_for_talent_type) = ANY($${roleParamIndex}::text[])
        )
      `;
    }

    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.follower_count,
        u.user_type,
        CASE 
          WHEN u.user_type IN ('host','talent') AND COALESCE(u.follower_count, 0) >= $1 THEN true 
          ELSE false 
        END as auto_featured
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      WHERE e.event_date > NOW()
        AND COALESCE(e.status, 'published') <> 'cancelled'
        AND (
          array_length(e.looking_for_roles, 1) > 0
          OR (e.looking_for_talent_type IS NOT NULL AND e.looking_for_talent_type <> '')
        )
        ${roleFilter}
      ORDER BY e.event_date ASC
      LIMIT 50`,
      params
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
      const lookingForRoles = normalizeRoles(row.looking_for_roles);
      const lookingForNotes = row.looking_for_notes || null;
      const lookingForLabel = buildLookingForLabel(lookingForRoles, row.looking_for_talent_type, lookingForNotes);
      return {
        id: eventId,
        title: row.title,
        description: row.description || "",
        hostId: row.creator_id?.toString() || "",
        hostName: row.host_name || row.host_username || "Unknown Host",
        hostAvatar: row.host_avatar || null,
        date: toISOString(row.event_date),
        location: row.location || "",
        images: normalizeImages(row.images),
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: row.attendee_count || 0,
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured: row.auto_featured || row.is_featured || false,
        qrCode: qrCode,
        talentIds: normalizeTalentIds(row.talent_ids),
        lookingForRoles,
        lookingForNotes,
        lookingForTalentType: lookingForLabel
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get events looking for talent error:", err);
    res.status(500).json({ error: "Failed to fetch events looking for talent" });
  }
});

// CREATE EVENT
router.post("/", async (req, res) => {
  try {
    await ensureEventsLookingForColumns();
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = verifyJwtToken(token);

    // Support both event_date and date fields
    const body = req.body || {};
    const eventDate = body.event_date || body.date || body.eventDate;
    const { title, description, location, ticket_price, ticketPrice, capacity } = body;
    // Extract images array from request body - support both camelCase and snake_case
    const images = body.images || body.cover_photo || (body.coverPhoto ? [body.coverPhoto] : []) || [];
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/a26ee9fb-9a8b-4833-8f7f-13ddff24387c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'src/routes/events.js:328',message:'createEvent received body',data:{hasImages:Array.isArray(body.images),imagesCount:Array.isArray(body.images)?body.images.length:0,hasCoverPhoto:!!body.coverPhoto,hasCoverPhotoSnake:!!body.cover_photo,eventDate:!!eventDate},timestamp:Date.now(),sessionId:'debug-session',runId:'pre-fix',hypothesisId:'H1'})}).catch(()=>{});
    // #endregion agent log
    const lookingForTalentType =
      body.lookingForTalentType ||
      body.looking_for_talent_type ||
      body.talentNeeded ||
      null;
    const lookingForRoles = normalizeRoles(
      body.lookingForRoles ||
      body.looking_for_roles ||
      body.lookingForTalentRoles ||
      body.looking_for_talent_roles
    );
    const lookingForNotes =
      body.lookingForNotes ||
      body.looking_for_notes ||
      body.lookingForTalentNotes ||
      null;
    const lookingForLabel = buildLookingForLabel(lookingForRoles, lookingForTalentType, lookingForNotes);
    const talentIds = normalizeTalentIds(body.talent_ids || body.talentIds || body.talentId);

    console.log("📥 Received event creation request:");
    console.log("   Title:", title);
    console.log("   Description:", description);
    console.log("   Location:", location);
    console.log("   Event Date:", eventDate);
    console.log("   Ticket Price:", ticket_price || ticketPrice);
    console.log("   Capacity:", capacity);
    console.log("   Images:", images);
    console.log("   Cover Photo (body.cover_photo):", body.cover_photo);
    console.log("   Cover Photo (body.coverPhoto):", body.coverPhoto);
    console.log("   Cover Photo (first image):", Array.isArray(images) ? images[0] : images);
    console.log("   Looking For Talent Type:", lookingForTalentType);
    console.log("   Looking For Roles:", lookingForRoles);
    console.log("   Looking For Notes:", lookingForNotes);
    console.log("   Talent IDs:", talentIds);

    if (!title || !title.trim()) {
      console.error("❌ Missing title");
      return res.status(400).json({ error: "Title is required" });
    }
    
    if (!eventDate) {
      console.error("❌ Missing event date");
      return res.status(400).json({ error: "Event date is required" });
    }
    
    if (!location || !location.trim()) {
      console.error("❌ Missing location");
      return res.status(400).json({ error: "Location is required" });
    }
    
    // Handle ticket price - ensure it's a number
    let ticketPriceValue = 0;
    // Check both ticket_price and ticketPrice fields
    const ticketPriceField = ticket_price !== undefined ? ticket_price : ticketPrice;
    
    if (ticketPriceField !== undefined && ticketPriceField !== null && ticketPriceField !== "") {
      // Parse as number - handle both string and number types
      let parsed;
      if (typeof ticketPriceField === 'string') {
        parsed = parseFloat(ticketPriceField);
      } else if (typeof ticketPriceField === 'number') {
        parsed = ticketPriceField;
      } else {
        parsed = Number(ticketPriceField);
      }
      
      // Ensure it's a valid number and >= 0
      if (!isNaN(parsed) && parsed >= 0) {
        ticketPriceValue = parsed;
      }
    }
    
    // Ensure it's a number type (not string) for database
    const dbTicketPrice = Number(ticketPriceValue);
    
    console.log("💰 Ticket price received:", ticketPriceField, "→ parsed:", ticketPriceValue, "→ DB:", dbTicketPrice);

    if (dbTicketPrice > 0) {
      const stripeCheck = await ensureHostStripeReady(req, decoded.userId);
      if (!stripeCheck.ok) {
        return res.status(stripeCheck.status).json({ error: stripeCheck.message });
      }
    }

    // Ensure images is an array and save to database
    const imagesArray = Array.isArray(images) ? images : (images ? [images] : []);
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/a26ee9fb-9a8b-4833-8f7f-13ddff24387c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'src/routes/events.js:407',message:'createEvent images normalized',data:{imagesType:typeof images,imagesArrayCount:imagesArray.length,firstImage:imagesArray[0]||null},timestamp:Date.now(),sessionId:'debug-session',runId:'pre-fix',hypothesisId:'H2'})}).catch(()=>{});
    // #endregion agent log
    
    const result = await db.query(
      `INSERT INTO events (creator_id, title, description, location, event_date, ticket_price, capacity, talent_ids, looking_for_talent_type, looking_for_roles, looking_for_notes, images)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        decoded.userId,
        title,
        description || null,
        location || null,
        eventDate,
        dbTicketPrice,
        capacity || null,
        talentIds,
        lookingForTalentType || lookingForLabel || null,
        lookingForRoles,
        lookingForNotes || null,
        imagesArray // Save images array to database
      ]
    );

    const eventRow = result.rows[0];
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/a26ee9fb-9a8b-4833-8f7f-13ddff24387c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'src/routes/events.js:429',message:'createEvent db row images',data:{dbImagesPresent:Array.isArray(eventRow?.images),dbImagesCount:Array.isArray(eventRow?.images)?eventRow.images.length:0},timestamp:Date.now(),sessionId:'debug-session',runId:'pre-fix',hypothesisId:'H3'})}).catch(()=>{});
    // #endregion agent log
    
    // Get host info
    const hostResult = await db.query(
      `SELECT username, name, avatar, follower_count, user_type FROM users WHERE id = $1`, 
      [decoded.userId]
    );
    const host = hostResult.rows[0] || {};
    const qualifiesFeatured = isFeaturedByFollowers(host);

    // Generate unique QR code for the event
    const eventId = eventRow.id.toString();
    const qrCode = `sioree:event:${eventId}:${crypto.randomUUID()}`;
    const eventLookingForRoles = normalizeRoles(eventRow?.looking_for_roles || lookingForRoles);
    const eventLookingForNotes = eventRow?.looking_for_notes || lookingForNotes || null;
    const eventLookingForTalentType = eventRow?.looking_for_talent_type || lookingForLabel || lookingForTalentType || null;
    const eventLookingForLabel = buildLookingForLabel(
      eventLookingForRoles,
      eventLookingForTalentType,
      eventLookingForNotes
    );
    
    // Format event to match iOS Event model expectations
    // Required fields (using try container.decode): id, title, description, hostId, hostName, date, location
    // Optional fields (using decodeIfPresent): hostAvatar, locationDetails, images, ticketPrice, capacity, attendeeCount, talentIds, status, createdAt, likes, isLiked, isSaved, isFeatured, qrCode
    // Persist the computed featured flag so subsequent reads stay consistent
    await db.query(`UPDATE events SET is_featured = $1 WHERE id = $2`, [qualifiesFeatured, eventId]);

    // Get images from database result or use the ones from request body
    const finalImages = normalizeImages(eventRow.images || imagesArray);
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/a26ee9fb-9a8b-4833-8f7f-13ddff24387c',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'src/routes/events.js:459',message:'createEvent final images',data:{finalCount:finalImages.length,firstFinal:finalImages[0]||null},timestamp:Date.now(),sessionId:'debug-session',runId:'pre-fix',hypothesisId:'H3'})}).catch(()=>{});
    // #endregion agent log
    
    const event = {
      id: eventId,
      title: eventRow.title || "",
      description: eventRow.description || "",
      hostId: eventRow.creator_id?.toString() || decoded.userId.toString(),
      hostName: host.name || host.username || "Unknown Host",
      hostAvatar: host.avatar || null,
      date: toISOString(eventRow.event_date),
      location: eventRow.location || "",
      images: finalImages, // Use the actual images array - NOT empty!
      ticketPrice: eventRow.ticket_price && parseFloat(eventRow.ticket_price) > 0 ? parseFloat(eventRow.ticket_price) : null,
      capacity: eventRow.capacity || null,
      attendees: 0,  // Maps to attendeeCount via CodingKeys
      talentIds: normalizeTalentIds(eventRow.talent_ids),
      status: "published",
      created_at: toISOString(eventRow.created_at),  // Maps to createdAt via CodingKeys
      likes: 0,
      isLiked: false,
      isSaved: false,
      isFeatured: qualifiesFeatured,
      qrCode: qrCode,  // Unique QR code for the event
      lookingForTalentType: eventLookingForLabel,
      lookingForRoles: eventLookingForRoles,
      lookingForNotes: eventLookingForNotes
    };
    
    console.log("📸 Event images:", finalImages);
    
    // Validate all required fields are present
    if (!event.id || !event.title || !event.hostId || !event.hostName || !event.date || !event.location) {
      console.error("❌ Missing required fields in event:", event);
      return res.status(500).json({ error: "Failed to create event: missing required fields" });
    }

    console.log("✅ Created event:", JSON.stringify(event, null, 2));
    res.json(event);
  } catch (err) {
    console.error("❌ Create event error:", err);
    console.error("   Error message:", err.message);
    console.error("   Error stack:", err.stack);
    const errorMessage = err.message || "Failed to create event";
    res.status(500).json({ error: errorMessage });
  }
});

// LIST EVENTS
router.get("/", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.follower_count,
        u.user_type,
        CASE 
          WHEN u.user_type IN ('host','talent') AND COALESCE(u.follower_count, 0) >= $1 THEN true 
          ELSE false 
        END as auto_featured
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      WHERE COALESCE(e.status, 'published') <> 'cancelled'
      ORDER BY e.event_date ASC
      LIMIT 100`,
      [FEATURED_FOLLOWER_THRESHOLD]
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
      const lookingForRoles = normalizeRoles(row.looking_for_roles);
      const lookingForNotes = row.looking_for_notes || null;
      const lookingForLabel = buildLookingForLabel(lookingForRoles, row.looking_for_talent_type, lookingForNotes);
      return {
        id: eventId,
        title: row.title,
        description: row.description || "",
        hostId: row.creator_id?.toString() || "",
        hostName: row.host_name || row.host_username || "Unknown Host",
        hostAvatar: row.host_avatar || null,
        date: toISOString(row.event_date),
        location: row.location || "",
        images: normalizeImages(row.images),
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: row.attendee_count || 0,
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured: row.auto_featured || false,
        qrCode: qrCode,
        talentIds: normalizeTalentIds(row.talent_ids),
        lookingForRoles,
        lookingForNotes,
        lookingForTalentType: lookingForLabel
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("List events error:", err);
    res.status(500).json({ error: "Failed to fetch events" });
  }
});

// Helper to get user ID from token
function getUserIdFromToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const token = authHeader.substring(7);
  try {
    const decoded = verifyJwtToken(token);
    return decoded.userId;
  } catch (err) {
    return null;
  }
}

// GET EVENTS USER IS ATTENDING (upcoming events)
router.get("/attending/upcoming", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const result = await db.query(
      `SELECT DISTINCT
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.follower_count,
        u.user_type,
        CASE
          WHEN u.user_type IN ('host','talent') AND COALESCE(u.follower_count, 0) >= $2 THEN true
          ELSE false
        END as auto_featured
      FROM events e
      INNER JOIN event_attendees ea ON e.id = ea.event_id
      LEFT JOIN users u ON e.creator_id = u.id
      WHERE ea.user_id = $1
        AND e.event_date > NOW()
        AND COALESCE(e.status, 'published') <> 'cancelled'
      ORDER BY e.event_date ASC`,
      [userId, FEATURED_FOLLOWER_THRESHOLD]
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
      const lookingForRoles = normalizeRoles(row.looking_for_roles);
      const lookingForNotes = row.looking_for_notes || null;
      const lookingForLabel = buildLookingForLabel(lookingForRoles, row.looking_for_talent_type, lookingForNotes);
      return {
        id: eventId,
        title: row.title,
        description: row.description || "",
        hostId: row.creator_id?.toString() || "",
        hostName: row.host_name || row.host_username || "Unknown Host",
        hostAvatar: row.host_avatar || null,
        date: toISOString(row.event_date),
        location: row.location || "",
        images: normalizeImages(row.images),
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: row.attendee_count || 0,
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured: row.auto_featured || false,
        isRSVPed: true,
        qrCode: qrCode,
        talentIds: normalizeTalentIds(row.talent_ids),
        lookingForRoles,
        lookingForNotes,
        lookingForTalentType: lookingForLabel
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get attending events error:", err);
    res.status(500).json({ error: "Failed to fetch attending events" });
  }
});

// GET SINGLE EVENT
router.get("/:id", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    
    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.follower_count,
        u.user_type,
        CASE 
          WHEN u.user_type IN ('host','talent') AND COALESCE(u.follower_count, 0) >= $3 THEN true 
          ELSE false 
        END as auto_featured,
        COALESCE(el.likes_count, 0) as likes,
        CASE WHEN ela.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        CASE WHEN esa.user_id IS NOT NULL THEN true ELSE false END as is_saved
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      LEFT JOIN (
        SELECT event_id, COUNT(*) as likes_count
        FROM event_likes
        GROUP BY event_id
      ) el ON el.event_id = e.id
      LEFT JOIN (
        SELECT event_id, user_id
        FROM event_likes
        WHERE user_id = $2
      ) ela ON ela.event_id = e.id
      LEFT JOIN (
        SELECT event_id, user_id
        FROM event_saves
        WHERE user_id = $2
      ) esa ON esa.event_id = e.id
      WHERE e.id = $1`,
      [req.params.id, userId, FEATURED_FOLLOWER_THRESHOLD]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: "Event not found" });

    const row = result.rows[0];
    const eventId = row.id.toString();
    // Generate QR code if not stored in DB (for backward compatibility)
    const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
    const lookingForRoles = normalizeRoles(row.looking_for_roles);
    const lookingForNotes = row.looking_for_notes || null;
    const lookingForLabel = buildLookingForLabel(lookingForRoles, row.looking_for_talent_type, lookingForNotes);
    
    const event = {
      id: eventId,
      title: row.title,
      description: row.description || "",
      hostId: row.creator_id?.toString() || "",
      hostName: row.host_name || row.host_username || "Unknown Host",
      hostAvatar: row.host_avatar || null,
      date: toISOString(row.event_date),
      location: row.location || "",
      images: normalizeImages(row.images),
      ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
      capacity: row.capacity || null,
      attendees: row.attendee_count || 0,
      isLiked: row.is_liked || false,
      isSaved: row.is_saved || false,
      likes: parseInt(row.likes) || 0,
      isFeatured: row.auto_featured || row.is_featured || false,
      status: "published",
      createdAt: toISOString(row.created_at),
      talentIds: normalizeTalentIds(row.talent_ids),
      qrCode: qrCode,
      lookingForTalentType: lookingForLabel,
      lookingForRoles,
      lookingForNotes
    };

    res.json(event);
  } catch (err) {
    console.error("Get event error:", err);
    res.status(500).json({ error: "Failed to fetch event" });
  }
});

// GET recent signups for host's events (for host notifications)
router.get("/host/recent-signups", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = verifyJwtToken(token);
    const hostId = decoded.userId;

    const result = await db.query(
      `SELECT 
        ea.id as signup_id,
        ea.created_at as signed_up_at,
        ea.event_id,
        e.title as event_title,
        e.event_date,
        u.id as user_id,
        u.name as user_name,
        u.username as user_username,
        u.avatar as user_avatar
      FROM event_attendees ea
      INNER JOIN events e ON ea.event_id = e.id
      INNER JOIN users u ON ea.user_id = u.id
      WHERE e.creator_id = $1
        AND ea.created_at > NOW() - INTERVAL '24 hours'
      ORDER BY ea.created_at DESC
      LIMIT 50`,
      [hostId]
    );

    const signups = result.rows.map(row => ({
      id: row.signup_id.toString(),
      signedUpAt: toISOString(row.signed_up_at),
      eventId: row.event_id.toString(),
      eventTitle: row.event_title,
      eventDate: toISOString(row.event_date),
      userId: row.user_id.toString(),
      userName: row.user_name || row.user_username,
      userUsername: row.user_username,
      userAvatar: row.user_avatar || null
    }));

    res.json({ signups });
  } catch (err) {
    console.error("Get recent signups error:", err);
    if (err.name === "JsonWebTokenError" || err.name === "TokenExpiredError") {
      return res.status(401).json({ error: "Invalid or expired token" });
    }
    res.status(500).json({ error: "Failed to fetch recent signups" });
  }
});

// GET event attendees
router.get("/:id/attendees", async (req, res) => {
  try {
    const eventId = req.params.id;
    const result = await db.query(
      `SELECT u.id, u.name, u.username, u.avatar, u.verified
       FROM event_attendees ea
       JOIN users u ON ea.user_id = u.id
       WHERE ea.event_id = $1
       ORDER BY ea.created_at DESC`,
      [eventId]
    );

    const attendees = result.rows.map(row => ({
      id: row.id.toString(),
      name: row.name || row.username || "Unknown",
      username: row.username || "",
      avatar: row.avatar || null,
      isVerified: row.verified || false
    }));

    res.json({ attendees });
  } catch (err) {
    console.error("Get attendees error:", err);
    res.status(500).json({ error: "Failed to fetch attendees" });
  }
});

// RSVP to event (POST)
router.post("/:id/rsvp", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = verifyJwtToken(token);
    const userId = decoded.userId;
    const eventId = req.params.id;

    // Check if already RSVPed
    const checkResult = await db.query(
      `SELECT * FROM event_attendees WHERE event_id = $1 AND user_id = $2`,
      [eventId, userId]
    );

    if (checkResult.rows.length > 0) {
      return res.json({ success: true, message: "Already RSVPed" });
    }

    // Add attendee
    await db.query(
      `INSERT INTO event_attendees (event_id, user_id) VALUES ($1, $2)`,
      [eventId, userId]
    );

    // Update attendee count
    await db.query(
      `UPDATE events SET attendee_count = attendee_count + 1 WHERE id = $1`,
      [eventId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("RSVP error:", err);
    res.status(500).json({ error: "Failed to RSVP" });
  }
});

// Cancel RSVP (DELETE)
router.delete("/:id/rsvp", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = verifyJwtToken(token);
    const userId = decoded.userId;
    const eventId = req.params.id;

    // Remove attendee
    await db.query(
      `DELETE FROM event_attendees WHERE event_id = $1 AND user_id = $2`,
      [eventId, userId]
    );

    // Update attendee count
    await db.query(
      `UPDATE events SET attendee_count = GREATEST(0, attendee_count - 1) WHERE id = $1`,
      [eventId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Cancel RSVP error:", err);
    res.status(500).json({ error: "Failed to cancel RSVP" });
  }
});

// LIKE/UNLIKE EVENT
router.post("/:id/like", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const eventId = req.params.id;

    // Check if already liked
    const checkResult = await db.query(
      `SELECT * FROM event_likes WHERE event_id = $1 AND user_id = $2`,
      [eventId, userId]
    );

    if (checkResult.rows.length > 0) {
      // Unlike
      await db.query(
        `DELETE FROM event_likes WHERE event_id = $1 AND user_id = $2`,
        [eventId, userId]
      );
      await db.query(
        `UPDATE events SET likes = GREATEST(0, likes - 1) WHERE id = $1`,
        [eventId]
      );
      res.json({ liked: false });
    } else {
      // Like
      await db.query(
        `INSERT INTO event_likes (event_id, user_id) VALUES ($1, $2)`,
        [eventId, userId]
      );
      await db.query(
        `UPDATE events SET likes = likes + 1 WHERE id = $1`,
        [eventId]
      );
      res.json({ liked: true });
    }
  } catch (err) {
    console.error("Like event error:", err);
    res.status(500).json({ error: "Failed to like/unlike event" });
  }
});

// SAVE/UNSAVE EVENT
router.post("/:id/save", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const eventId = req.params.id;

    // Check if already saved
    const checkResult = await db.query(
      `SELECT * FROM event_saves WHERE event_id = $1 AND user_id = $2`,
      [eventId, userId]
    );

    if (checkResult.rows.length > 0) {
      // Unsave
      await db.query(
        `DELETE FROM event_saves WHERE event_id = $1 AND user_id = $2`,
        [eventId, userId]
      );
      res.json({ saved: false });
    } else {
      // Save
      await db.query(
        `INSERT INTO event_saves (event_id, user_id) VALUES ($1, $2)`,
        [eventId, userId]
      );
      res.json({ saved: true });
    }
  } catch (err) {
    console.error("Save event error:", err);
    res.status(500).json({ error: "Failed to save/unsave event" });
  }
});

// CANCEL EVENT (notify + mark refunds)
router.post("/:id/cancel", async (req, res) => {
  const client = await db.connect();
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      client.release();
      return res.status(401).json({ error: "Unauthorized" });
    }

    const token = authHeader.substring(7);
    const decoded = verifyJwtToken(token);
    const eventId = req.params.id;
    const { reason } = req.body || {};

    const eventResult = await client.query(`SELECT creator_id FROM events WHERE id = $1`, [eventId]);
    if (eventResult.rows.length === 0) {
      client.release();
      return res.status(404).json({ error: "Event not found" });
    }
    if (eventResult.rows[0].creator_id?.toString() !== decoded.userId.toString()) {
      client.release();
      return res.status(403).json({ error: "Only the host can cancel this event" });
    }

    await client.query("BEGIN");

    await client.query(
      `UPDATE events 
       SET status = 'cancelled', cancelled_at = NOW(), cancellation_reason = $1 
       WHERE id = $2`,
      [reason || null, eventId]
    );

    await client.query(
      `UPDATE bookings 
       SET status = 'cancelled',
           payment_status = CASE WHEN payment_status = 'paid' THEN 'refund_pending' ELSE payment_status END,
           refund_status = CASE WHEN payment_status = 'paid' THEN 'pending_refund' ELSE refund_status END,
           updated_at = NOW()
       WHERE event_id = $1`,
      [eventId]
    );

    await client.query(
      `UPDATE talent_earnings 
       SET status = 'refunded' 
       WHERE booking_id IN (SELECT id FROM bookings WHERE event_id = $1)`,
      [eventId]
    );

    await client.query("COMMIT");
    client.release();

    res.json({ success: true, status: "cancelled" });
  } catch (err) {
    await client.query("ROLLBACK");
    client.release();
    console.error("Cancel event error:", err);
    res.status(500).json({ error: "Failed to cancel event" });
  }
});

export default router;
