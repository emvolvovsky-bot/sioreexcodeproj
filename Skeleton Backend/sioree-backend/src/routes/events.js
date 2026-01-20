import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import stripe from "../lib/stripe.js";

const router = express.Router();
const STRIPE_ERRORS = {
  onboardingRequired: "STRIPE_ONBOARDING_REQUIRED"
};

// Ensure promo schema exists if migrations lag in production
let promoSchemaEnsured = false;
async function ensureEventPromoSchema() {
  if (promoSchemaEnsured) return;
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS event_promotions (
        id SERIAL PRIMARY KEY,
        event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        brand_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        promoted_at TIMESTAMP DEFAULT NOW(),
        expires_at TIMESTAMP,
        is_active BOOLEAN DEFAULT true,
        promotion_budget DECIMAL(10, 2) DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(event_id, brand_id)
      );
      CREATE INDEX IF NOT EXISTS idx_event_promotions_event_id ON event_promotions(event_id);
      CREATE INDEX IF NOT EXISTS idx_event_promotions_brand_id ON event_promotions(brand_id);
      CREATE INDEX IF NOT EXISTS idx_event_promotions_active ON event_promotions(is_active, expires_at);
      ALTER TABLE events ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
    `);
    promoSchemaEnsured = true;
  } catch (err) {
    console.error("ensureEventPromoSchema error:", err);
    // continue without blocking request
  }
}

let eventImagesColumnEnsured = false;
async function ensureEventImagesColumn() {
  if (eventImagesColumnEnsured) return true;
  try {
    await db.query(`ALTER TABLE events ADD COLUMN IF NOT EXISTS images TEXT[];`);
    eventImagesColumnEnsured = true;
    return true;
  } catch (err) {
    console.error("ensureEventImagesColumn error:", err);
    return false;
  }
}

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

const ensureHostStripeReady = async (userId) => {
  if (!stripe || !stripe.accounts) {
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

  const account = await stripe.accounts.retrieve(stripeAccountId);
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
      message: STRIPE_ERRORS.onboardingRequired
    };
  }

  return { ok: true };
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

// GET FEATURED EVENTS (promoted by brands)
router.get("/featured", async (req, res) => {
  try {
    await ensureEventPromoSchema();

    // Get events that are actively promoted by brands
    // Use window function to get most recent promotion per event, then join for full details
    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        b.name as brand_name,
        b.avatar as brand_avatar,
        promo.promoted_at
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      INNER JOIN (
        SELECT DISTINCT ON (event_id)
          event_id,
          brand_id,
          promoted_at
        FROM event_promotions
        WHERE is_active = true
          AND (expires_at IS NULL OR expires_at > NOW())
        ORDER BY event_id, promoted_at DESC
      ) promo ON e.id = promo.event_id
      INNER JOIN users b ON promo.brand_id = b.id
      WHERE e.event_date > NOW()
        AND b.user_type = 'brand'
      ORDER BY promo.promoted_at DESC, e.event_date ASC
      LIMIT 20`
    );

    // Format events to match iOS expectations
    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
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
        isFeatured: true, // These are featured events (promoted by brands)
        qrCode: qrCode,
        lookingForTalentType: row.looking_for_talent_type || null
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get featured events error:", err);
    console.error("Error details:", {
      message: err.message,
      code: err.code,
      detail: err.detail,
      hint: err.hint
    });
    res.status(500).json({ error: "Failed to fetch featured events" });
  }
});

// GET NEARBY EVENTS (requires authentication)
router.get("/nearby", async (req, res) => {
  try {
    await ensureEventPromoSchema();

    // Get user location from query params or headers (in production, get from user's profile)
    const { latitude, longitude, radius = 50 } = req.query; // radius in km, default 50km

    // Get user ID if authenticated (to exclude events they're attending)
    let userId = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      try {
        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
        userId = decoded.userId;
      } catch (err) {
        // Invalid token, continue without filtering
      }
    }

    // Return upcoming events (excluding featured ones, or include them but mark them)
    // EXCLUDE events the user is already attending (they should see those in "Upcoming Events" instead)
    // In production, filter by location using PostGIS or calculate distance
    let query = `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        CASE WHEN ep.id IS NOT NULL THEN true ELSE false END as is_featured,
        COALESCE(attendee_count_actual.count, 0) as attendee_count_actual
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      LEFT JOIN event_promotions ep ON e.id = ep.event_id 
        AND ep.is_active = true 
        AND (ep.expires_at IS NULL OR ep.expires_at > NOW())
      LEFT JOIN (
        SELECT event_id, COUNT(DISTINCT user_id) as count
        FROM event_attendees
        GROUP BY event_id
      ) attendee_count_actual ON attendee_count_actual.event_id = e.id
      WHERE e.event_date > NOW()`;
    
    // Exclude events user is already attending
    if (userId) {
      query += ` AND NOT EXISTS (
        SELECT 1 FROM event_attendees ea 
        WHERE ea.event_id = e.id AND ea.user_id = $1
      )`;
    }
    
    query += ` ORDER BY e.event_date ASC LIMIT 50`;
    
    const result = await db.query(query, userId ? [userId] : []);

    // Format events to match iOS expectations
    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
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
        attendees: parseInt(row.attendee_count_actual) || 0, // Use actual count from event_attendees table
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured: row.is_featured || false,
        qrCode: qrCode,
        isRSVPed: false // User is not RSVPed (otherwise it wouldn't be in "Near Me")
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get nearby events error:", err);
    res.status(500).json({ error: "Failed to fetch events" });
  }
});

// CREATE EVENT
router.post("/", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");

    const body = req.body || {};
    // Normalize optional looking-for field so it is always defined (string) to avoid ReferenceError
    const lookingForTalentType = (
      body.lookingForTalentType ||
      body.looking_for_talent_type ||
      body.talentNeeded ||
      ""
    ).toString().trim() || "General talent";
    // Support both event_date and date fields
    const eventDate = body.event_date || body.date || body.eventDate;
    const talentIds = Array.isArray(body.talentIds)
      ? body.talentIds
      : Array.isArray(body.talent_ids)
        ? body.talent_ids
        : [];
    const images = body.images || body.cover_photo || (body.coverPhoto ? [body.coverPhoto] : []) || [];
    const imagesArray = normalizeImages(images);
    const { title, description, location, ticket_price, ticketPrice, capacity } = body;
    console.log("📥 Received event creation request:");
    console.log("   Title:", title);
    console.log("   Description:", description);
    console.log("   Location:", location);
    console.log("   Event Date:", eventDate);
    console.log("   Ticket Price:", ticket_price || ticketPrice);
    console.log("   Capacity:", capacity);
    console.log("   Talent IDs:", talentIds);
    console.log("   Images:", imagesArray);
    console.log("   Cover Photo (body.cover_photo):", body.cover_photo);
    console.log("   Cover Photo (body.coverPhoto):", body.coverPhoto);
    console.log("   Cover Photo (first image):", Array.isArray(imagesArray) ? imagesArray[0] : imagesArray);
    console.log("   Looking For Talent Type:", lookingForTalentType);

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
      const stripeCheck = await ensureHostStripeReady(decoded.userId);
      if (!stripeCheck.ok) {
        return res.status(stripeCheck.status).json({ error: stripeCheck.message });
      }
    }

    // Check if looking_for_talent_type column exists before including it in INSERT
    let columnExists = false;
    try {
      const checkResult = await db.query(
        `SELECT column_name 
         FROM information_schema.columns 
         WHERE table_name = 'events' 
         AND column_name = 'looking_for_talent_type'`
      );
      columnExists = checkResult.rows.length > 0;
    } catch (checkErr) {
      // If we can't check, assume it doesn't exist to be safe
      columnExists = false;
    }

    const imagesColumnExists = await ensureEventImagesColumn();

    const insertColumns = [
      "creator_id",
      "title",
      "description",
      "location",
      "event_date",
      "ticket_price",
      "capacity"
    ];
    const insertValues = [
      decoded.userId,
      title,
      description || null,
      location || null,
      eventDate,
      dbTicketPrice,
      capacity || null
    ];

    if (columnExists) {
      insertColumns.push("looking_for_talent_type");
      insertValues.push(lookingForTalentType || null);
    }

    if (imagesColumnExists) {
      insertColumns.push("images");
      insertValues.push(imagesArray);
    }

    const placeholders = insertColumns.map((_, index) => `$${index + 1}`).join(", ");
    const result = await db.query(
      `INSERT INTO events (${insertColumns.join(", ")})
       VALUES (${placeholders})
       RETURNING *`,
      insertValues
    );

    const eventRow = result.rows[0];
    
    // Handle talent IDs if provided (specific talent selected)
    if (talentIds && Array.isArray(talentIds) && talentIds.length > 0) {
      // Check if event_talent table exists
      try {
        const tableExists = await db.query(
          `SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = 'event_talent'
          )`
        );
        
        if (tableExists.rows[0]?.exists) {
          // Insert talent relationships
          for (const talentId of talentIds) {
            try {
              const numericTalentId = parseInt(talentId, 10);
              if (Number.isNaN(numericTalentId)) {
                console.warn(`Skipping invalid talentId: ${talentId}`);
                continue;
              }
              await db.query(
                `INSERT INTO event_talent (event_id, talent_id) 
                 VALUES ($1, $2)
                 ON CONFLICT (event_id, talent_id) DO NOTHING`,
                [eventRow.id, numericTalentId]
              );
            } catch (talentErr) {
              console.error(`Failed to link talent ${talentId}:`, talentErr);
            }
          }
          console.log(`✅ Linked ${talentIds.length} talent(s) to event`);
        } else {
          console.log("⚠️ event_talent table doesn't exist, skipping talent linking");
        }
      } catch (err) {
        console.error("Error checking/creating talent relationships:", err);
      }
    }
    
    // Get host info
    const hostResult = await db.query(`SELECT username, name, avatar FROM users WHERE id = $1`, [decoded.userId]);
    const host = hostResult.rows[0] || {};

    // Generate unique QR code for the event (only for future events)
    const eventId = eventRow.id.toString();
    let qrCode = null;
    
    // Only generate QR code if event is in the future
    if (eventDate > new Date()) {
      qrCode = `sioree:event:${eventId}:${crypto.randomUUID()}`;
      
      // Save QR code to database if column exists
      try {
        const qrCodeColumnExists = await db.query(
          `SELECT column_name 
           FROM information_schema.columns 
           WHERE table_name = 'events' 
           AND column_name = 'qr_code'`
        );
        if (qrCodeColumnExists.rows.length > 0) {
          await db.query(
            `UPDATE events SET qr_code = $1 WHERE id = $2`,
            [qrCode, eventRow.id]
          );
        }
      } catch (qrErr) {
        // Column doesn't exist, that's okay - QR code is still in response
        console.log("⚠️ QR code column doesn't exist, skipping database update");
      }
    }
    
    // Format event to match iOS Event model expectations
    // Required fields (using try container.decode): id, title, description, hostId, hostName, date, location
    // Optional fields (using decodeIfPresent): hostAvatar, locationDetails, images, ticketPrice, capacity, attendeeCount, talentIds, status, createdAt, likes, isLiked, isSaved, isFeatured, qrCode
    const event = {
      id: eventId,
      title: eventRow.title || "",
      description: eventRow.description || "",
      hostId: eventRow.creator_id?.toString() || decoded.userId.toString(),
      hostName: host.name || host.username || "Unknown Host",
      hostAvatar: host.avatar || null,
      date: toISOString(eventRow.event_date),
      location: eventRow.location || "",
      images: normalizeImages(eventRow.images || imagesArray),
      ticketPrice: eventRow.ticket_price && parseFloat(eventRow.ticket_price) > 0 ? parseFloat(eventRow.ticket_price) : null,
      capacity: eventRow.capacity || null,
      attendees: 0,  // Maps to attendeeCount via CodingKeys
      talentIds: talentIds && Array.isArray(talentIds) ? talentIds : [],
      status: "published",
      created_at: toISOString(eventRow.created_at),  // Maps to createdAt via CodingKeys
      likes: 0,
      isLiked: false,
      isSaved: false,
      isFeatured: eventRow.is_featured || false,
      qrCode: qrCode || null,  // Unique QR code for the event (only for future events)
      lookingForTalentType: eventRow.looking_for_talent_type || lookingForTalentType || null
    };
    
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
        u.avatar as host_avatar
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      ORDER BY e.event_date ASC
      LIMIT 100`
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
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
        isFeatured: row.is_featured || false,
        qrCode: qrCode,
        lookingForTalentType: row.looking_for_talent_type || null
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
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    return decoded.userId;
  } catch (err) {
    return null;
  }
}

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
        COALESCE(el.likes_count, 0) as likes,
        CASE WHEN ela.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        CASE WHEN esa.user_id IS NOT NULL THEN true ELSE false END as is_saved,
        CASE WHEN ea.user_id IS NOT NULL THEN true ELSE false END as is_rsvped,
        COALESCE(attendee_count_actual.count, 0) as attendee_count_actual
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
      LEFT JOIN (
        SELECT event_id, user_id
        FROM event_attendees
        WHERE user_id = $2
      ) ea ON ea.event_id = e.id
      LEFT JOIN (
        SELECT event_id, COUNT(DISTINCT user_id) as count
        FROM event_attendees
        GROUP BY event_id
      ) attendee_count_actual ON attendee_count_actual.event_id = e.id
      WHERE e.id = $1`,
      [req.params.id, userId]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: "Event not found" });

    const row = result.rows[0];
    const eventId = row.id.toString();
    // Generate QR code if not stored in DB (for backward compatibility)
    const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
    
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
      attendees: parseInt(row.attendee_count_actual) || 0, // Use actual count from event_attendees table
      isLiked: row.is_liked || false,
      isSaved: row.is_saved || false,
      likes: parseInt(row.likes) || 0,
      lookingForTalentType: row.looking_for_talent_type || null,
      isFeatured: row.is_featured || false,
      status: "published",
      createdAt: toISOString(row.created_at),
      talentIds: [],
      qrCode: qrCode,
      isRSVPed: row.is_rsvped || false  // Include RSVP status in response
    };

    res.json(event);
  } catch (err) {
    console.error("Get event error:", err);
    res.status(500).json({ error: "Failed to fetch event" });
  }
});

// GET recent signups for host's events (for host home page notifications)
router.get("/host/recent-signups", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    const hostId = decoded.userId;

    // Get recent signups (last 24 hours) for events created by this host
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
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
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
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
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

    // Add attendee (use ON CONFLICT to prevent duplicates even if race condition occurs)
    await db.query(
      `INSERT INTO event_attendees (event_id, user_id) 
       VALUES ($1, $2)
       ON CONFLICT (event_id, user_id) DO NOTHING`,
      [eventId, userId]
    );

    // Generate unique QR code for this ticket
    const ticketQRCode = `sioree:ticket:${eventId}:${userId}:${crypto.randomUUID()}`;
    
    // Update attendee record with QR code if column exists
    try {
      const qrColumnExists = await db.query(
        `SELECT column_name 
         FROM information_schema.columns 
         WHERE table_name = 'event_attendees' 
         AND column_name = 'qr_code'`
      );
      if (qrColumnExists.rows.length > 0) {
        await db.query(
          `UPDATE event_attendees SET qr_code = $1 WHERE event_id = $2 AND user_id = $3`,
          [ticketQRCode, eventId, userId]
        );
      }
    } catch (qrErr) {
      // Column doesn't exist, that's okay
      console.log("⚠️ QR code column doesn't exist in event_attendees, skipping");
    }

    // Recalculate attendee count from actual table to ensure accuracy
    const countResult = await db.query(
      `SELECT COUNT(DISTINCT user_id) as count FROM event_attendees WHERE event_id = $1`,
      [eventId]
    );
    const actualCount = parseInt(countResult.rows[0]?.count || 0);
    
    // Update attendee count with actual count
    await db.query(
      `UPDATE events SET attendee_count = $1 WHERE id = $2`,
      [actualCount, eventId]
    );

    res.json({ success: true, qrCode: ticketQRCode });
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
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    const userId = decoded.userId;
    const eventId = req.params.id;

    // Remove attendee
    await db.query(
      `DELETE FROM event_attendees WHERE event_id = $1 AND user_id = $2`,
      [eventId, userId]
    );

    // Recalculate attendee count from actual table to ensure accuracy
    const countResult = await db.query(
      `SELECT COUNT(DISTINCT user_id) as count FROM event_attendees WHERE event_id = $1`,
      [eventId]
    );
    const actualCount = parseInt(countResult.rows[0]?.count || 0);
    
    // Update attendee count with actual count
    await db.query(
      `UPDATE events SET attendee_count = $1 WHERE id = $2`,
      [actualCount, eventId]
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

// POST promote event (for brands)
router.post("/:id/promote", async (req, res) => {
  try {
    await ensureEventPromoSchema();

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    
    // Check if user is a brand
    const userResult = await db.query(`SELECT user_type FROM users WHERE id = $1`, [decoded.userId]);
    if (userResult.rows.length === 0 || userResult.rows[0].user_type !== 'brand') {
      return res.status(403).json({ error: "Only brands can promote events" });
    }
    
    const eventId = req.params.id;
    const { expiresAt, promotionBudget } = req.body;
    
    // Check if event exists and get location
    const eventResult = await db.query(`SELECT id, location FROM events WHERE id = $1`, [eventId]);
    if (eventResult.rows.length === 0) {
      return res.status(404).json({ error: "Event not found" });
    }
    
    const eventLocation = eventResult.rows[0].location || "";
    const isNYC = eventLocation.toLowerCase().includes("new york") || 
                  eventLocation.toLowerCase().includes("nyc") || 
                  eventLocation.toLowerCase().includes("new york city");
    
    // Create or update promotion
    const promotionResult = await db.query(
      `INSERT INTO event_promotions (event_id, brand_id, expires_at, promotion_budget, is_active)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (event_id, brand_id) 
       DO UPDATE SET 
         expires_at = $3,
         promotion_budget = $4,
         is_active = true,
         promoted_at = NOW()
       RETURNING *`,
      [eventId, decoded.userId, expiresAt || null, promotionBudget || 0]
    );
    
    // Update event's is_featured flag
    await db.query(`UPDATE events SET is_featured = true WHERE id = $1`, [eventId]);
    
    // Track city activation if event is in NYC
    if (isNYC) {
      await db.query(
        `INSERT INTO brand_cities (brand_id, city, activated_at)
         VALUES ($1, 'New York City', NOW())
         ON CONFLICT (brand_id, city) DO NOTHING`,
        [decoded.userId]
      );
    }
    
    res.json({ 
      success: true, 
      promotion: promotionResult.rows[0],
      message: "Event promoted successfully"
    });
  } catch (err) {
    console.error("Promote event error:", err);
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: "Invalid or expired token" });
    }
    res.status(500).json({ error: "Failed to promote event" });
  }
});

// GET events looking for specific talent type (for talent users)
router.get("/looking-for/:talentType", async (req, res) => {
  try {
    const talentType = req.params.talentType;
    
    // First check if the column exists
    let columnExists = false;
    try {
      const checkResult = await db.query(
        `SELECT column_name 
         FROM information_schema.columns 
         WHERE table_name = 'events' 
         AND column_name = 'looking_for_talent_type'`
      );
      columnExists = checkResult.rows.length > 0;
    } catch (checkErr) {
      console.warn("Could not check for column existence:", checkErr);
    }
    
    // If column doesn't exist, return empty array (migration not run yet)
    if (!columnExists) {
      console.warn("Column looking_for_talent_type does not exist. Please run migration 007_add_event_talent_needs.sql");
      return res.json({ events: [] });
    }
    
    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar
      FROM events e
      LEFT JOIN users u ON e.creator_id = u.id
      WHERE e.looking_for_talent_type = $1
        AND e.event_date > NOW()
      ORDER BY e.event_date ASC
      LIMIT 50`,
      [talentType]
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
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
        isFeatured: row.is_featured || false,
        qrCode: qrCode,
        lookingForTalentType: row.looking_for_talent_type || null
      };
    });

    res.json({ events });
  } catch (err) {
    // If error is about missing column, return empty array instead of error
    if (err.code === '42703' || err.message?.includes('does not exist')) {
      console.warn("Column looking_for_talent_type does not exist. Please run migration 007_add_event_talent_needs.sql");
      return res.json({ events: [] });
    }
    console.error("Get events looking for talent error:", err);
    res.status(500).json({ error: "Failed to fetch events" });
  }
});

// GET EVENTS USER IS ATTENDING (upcoming events)
router.get("/attending/upcoming", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // Get events user is attending that are in the future
    const result = await db.query(
      `SELECT 
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        CASE WHEN ep.id IS NOT NULL THEN true ELSE false END as is_featured
      FROM events e
      INNER JOIN event_attendees ea ON e.id = ea.event_id
      LEFT JOIN users u ON e.creator_id = u.id
      LEFT JOIN event_promotions ep ON e.id = ep.event_id 
        AND ep.is_active = true 
        AND (ep.expires_at IS NULL OR ep.expires_at > NOW())
      WHERE ea.user_id = $1
        AND e.event_date > NOW()
      ORDER BY e.event_date ASC`,
      [userId]
    );

    // Format events to match iOS expectations
    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
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
        isFeatured: row.is_featured || false,
        isRSVPed: true, // User is attending these events
        qrCode: qrCode,
        lookingForTalentType: row.looking_for_talent_type || null
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get attending events error:", err);
    res.status(500).json({ error: "Failed to fetch attending events" });
  }
});

// GET UPCOMING EVENTS ASSIGNED TO TALENT USER
router.get("/talent/upcoming", async (req, res) => {
  try {
    await ensureEventPromoSchema();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // Ensure event_talent table exists
    const tableCheck = await db.query(
      `SELECT EXISTS (
         SELECT FROM information_schema.tables 
         WHERE table_name = 'event_talent'
       )`
    );

    if (!tableCheck.rows[0]?.exists) {
      console.warn("event_talent table missing. Run migration 011_add_event_talent_table.sql");
      return res.json({ events: [] });
    }

    // Find the talent id for this user
    const talentResult = await db.query(
      `SELECT id FROM talent WHERE user_id = $1 LIMIT 1`,
      [userId]
    );

    if (talentResult.rows.length === 0) {
      // User hasn't created a talent profile yet
      return res.json({ events: [] });
    }

    const talentId = talentResult.rows[0].id;

    const result = await db.query(
      `SELECT 
         e.*,
         u.username as host_username,
         u.name as host_name,
         u.avatar as host_avatar,
         CASE WHEN ep.id IS NOT NULL THEN true ELSE false END as is_featured,
         COALESCE(COUNT(DISTINCT ea.user_id), 0) as attendee_count,
         ARRAY_REMOVE(ARRAY_AGG(DISTINCT et_all.talent_id), NULL) as talent_ids
       FROM event_talent et
       INNER JOIN events e ON et.event_id = e.id
       LEFT JOIN users u ON e.creator_id = u.id
       LEFT JOIN event_promotions ep ON e.id = ep.event_id 
         AND ep.is_active = true 
         AND (ep.expires_at IS NULL OR ep.expires_at > NOW())
       LEFT JOIN event_attendees ea ON e.id = ea.event_id
       LEFT JOIN event_talent et_all ON et_all.event_id = e.id
       WHERE et.talent_id = $1
         AND e.event_date > NOW()
       GROUP BY e.id, u.username, u.name, u.avatar, ep.id
       ORDER BY e.event_date ASC`,
      [talentId]
    );

    const events = result.rows.map(row => {
      const eventId = row.id.toString();
      const qrCode = row.qr_code || `sioree:event:${eventId}:${crypto.randomUUID()}`;
      return {
        id: eventId,
        title: row.title || "",
        description: row.description || "",
        hostId: row.creator_id?.toString() || "",
        hostName: row.host_name || row.host_username || "Unknown Host",
        hostAvatar: row.host_avatar || null,
        date: toISOString(row.event_date),
        location: row.location || "",
        images: normalizeImages(row.images),
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: parseInt(row.attendee_count) || 0,
        isLiked: false,
        isSaved: false,
        likes: row.likes || 0,
        isFeatured: row.is_featured || false,
        isRSVPed: false,
        qrCode: qrCode,
        talentIds: Array.isArray(row.talent_ids) ? row.talent_ids.map(id => id.toString()) : [],
        lookingForTalentType: row.looking_for_talent_type || null
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get upcoming events for talent error:", err);
    res.status(500).json({ error: "Failed to fetch talent events" });
  }
});

// DELETE EVENT (host only)
router.delete("/:id", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    const userId = decoded.userId;
    const eventId = req.params.id;
    
    // Check if user is the creator of this event
    const eventResult = await db.query(
      `SELECT creator_id FROM events WHERE id = $1`,
      [eventId]
    );
    
    if (eventResult.rows.length === 0) {
      return res.status(404).json({ error: "Event not found" });
    }
    
    if (eventResult.rows[0].creator_id.toString() !== userId) {
      return res.status(403).json({ error: "Only the event creator can delete this event" });
    }
    
    // Delete event (cascade will handle related records)
    // First delete related records to avoid foreign key constraints
    await db.query(`DELETE FROM event_attendees WHERE event_id = $1`, [eventId]);
    await db.query(`DELETE FROM event_likes WHERE event_id = $1`, [eventId]);
    await db.query(`DELETE FROM event_saves WHERE event_id = $1`, [eventId]);
    await db.query(`DELETE FROM event_promotions WHERE event_id = $1`, [eventId]);
    // Now delete the event
    await db.query(`DELETE FROM events WHERE id = $1`, [eventId]);
    
    console.log(`✅ Event ${eventId} deleted successfully by user ${userId}`);
    res.json({ success: true, message: "Event deleted successfully" });
  } catch (err) {
    console.error("Delete event error:", err);
    res.status(500).json({ error: "Failed to delete event" });
  }
});

// DELETE unpromote event (for brands)
router.delete("/:id/promote", async (req, res) => {
  try {
    await ensureEventPromoSchema();

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    
    const eventId = req.params.id;
    
    // Deactivate promotion
    await db.query(
      `UPDATE event_promotions 
       SET is_active = false 
       WHERE event_id = $1 AND brand_id = $2`,
      [eventId, decoded.userId]
    );
    
    // Check if any other brands are promoting this event
    const activePromotions = await db.query(
      `SELECT COUNT(*) as count FROM event_promotions 
       WHERE event_id = $1 AND is_active = true`,
      [eventId]
    );
    
    // If no active promotions, unfeature the event
    if (parseInt(activePromotions.rows[0].count) === 0) {
      await db.query(`UPDATE events SET is_featured = false WHERE id = $1`, [eventId]);
    }
    
    res.json({ success: true, message: "Event promotion removed" });
  } catch (err) {
    console.error("Unpromote event error:", err);
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: "Invalid or expired token" });
    }
    res.status(500).json({ error: "Failed to remove promotion" });
  }
});

export default router;
