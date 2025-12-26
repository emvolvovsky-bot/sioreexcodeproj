import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";
import crypto from "crypto";

const router = express.Router();

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

// GET ALL TALENT
router.get("/", async (req, res) => {
  try {
    const category = req.query.category;
    const search = req.query.search;

    let query = `
      SELECT 
        t.*,
        u.username,
        u.name,
        u.avatar,
        u.location,
        u.verified
      FROM talent t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;

    if (category) {
      query += ` AND t.category = $${paramCount}`;
      params.push(category);
      paramCount++;
    }

    if (search) {
      query += ` AND (LOWER(u.name) LIKE LOWER($${paramCount}) OR LOWER(u.username) LIKE LOWER($${paramCount}) OR LOWER(t.bio) LIKE LOWER($${paramCount}))`;
      params.push(`%${search}%`);
      paramCount++;
    }

    query += ` ORDER BY t.rating DESC, t.review_count DESC LIMIT 50`;

    const result = await db.query(query, params);

    const talent = result.rows.map(row => ({
      id: row.id.toString(),
      userId: row.user_id.toString(),
      name: row.name || row.username || "Unknown",
      category: row.category,
      bio: row.bio || null,
      avatar: row.avatar || null,
      location: row.location || null,
      rating: parseFloat(row.rating) || 0,
      reviewCount: row.review_count || 0,
      priceRange: {
        min: parseFloat(row.price_min) || 0,
        max: parseFloat(row.price_max) || 0
      },
      portfolio: row.portfolio_urls || [],
      verified: row.verified || false,
      availability: row.availability || [],
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
    }));

    res.json(talent);
  } catch (err) {
    console.error("Get talent error:", err);
    res.status(500).json({ error: "Failed to fetch talent" });
  }
});

// GET SINGLE TALENT
router.get("/:id", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT 
        t.*,
        u.username,
        u.name,
        u.avatar,
        u.location,
        u.verified
      FROM talent t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE t.id = $1 OR t.user_id = $1`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Talent not found" });
    }

    const row = result.rows[0];
    const talent = {
      id: row.id.toString(),
      userId: row.user_id.toString(),
      name: row.name || row.username || "Unknown",
      category: row.category,
      bio: row.bio || null,
      avatar: row.avatar || null,
      location: row.location || null,
      rating: parseFloat(row.rating) || 0,
      reviewCount: row.review_count || 0,
      priceRange: {
        min: parseFloat(row.price_min) || 0,
        max: parseFloat(row.price_max) || 0
      },
      portfolio: row.portfolio_urls || [],
      verified: row.verified || false,
      availability: row.availability || [],
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
    };

    res.json(talent);
  } catch (err) {
    console.error("Get talent profile error:", err);
    res.status(500).json({ error: "Failed to fetch talent profile" });
  }
});

// GET COMPLETED EVENTS FOR TALENT
router.get("/:id/completed-events", async (req, res) => {
  try {
    const talentUserId = req.params.id;
    
    // Get completed bookings for this talent user
    const result = await db.query(
      `SELECT DISTINCT e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar
      FROM bookings b
      INNER JOIN talent t ON b.talent_id = t.id
      LEFT JOIN events e ON b.event_id = e.id
      LEFT JOIN users u ON e.creator_id = u.id
      WHERE t.user_id = $1 
        AND b.status = 'completed'
        AND e.id IS NOT NULL
        AND e.event_date < NOW()
      ORDER BY e.event_date DESC`,
      [talentUserId]
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
        date: row.event_date ? new Date(row.event_date).toISOString() : new Date().toISOString(),
        location: row.location || "",
        images: [],
        ticketPrice: row.ticket_price && parseFloat(row.ticket_price) > 0 ? parseFloat(row.ticket_price) : null,
        capacity: row.capacity || null,
        attendees: 0,
        talentIds: [],
        status: "completed",
        created_at: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
        likes: row.likes || 0,
        isLiked: false,
        isSaved: false,
        isFeatured: false,
        qrCode: qrCode,
        isRSVPed: false
      };
    });

    res.json({ events });
  } catch (err) {
    console.error("Get completed events for talent error:", err);
    res.status(500).json({ error: "Failed to fetch completed events" });
  }
});

// POST - Register/Update talent in marketplace
router.post("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { category, bio, priceMin, priceMax } = req.body;

    if (!category) {
      return res.status(400).json({ error: "Category is required" });
    }

    // Check if talent already exists for this user
    const existingTalent = await db.query(
      "SELECT id FROM talent WHERE user_id = $1",
      [userId]
    );

    if (existingTalent.rows.length > 0) {
      // Update existing talent
      const talentId = existingTalent.rows[0].id;
      const result = await db.query(
        `UPDATE talent 
         SET category = $1, 
             bio = $2, 
             price_min = $3, 
             price_max = $4,
             updated_at = NOW()
         WHERE id = $5
         RETURNING *`,
        [category, bio || null, priceMin || 0, priceMax || 0, talentId]
      );

      const row = result.rows[0];
      const talent = {
        id: row.id.toString(),
        userId: row.user_id.toString(),
        category: row.category,
        bio: row.bio || null,
        priceRange: {
          min: parseFloat(row.price_min) || 0,
          max: parseFloat(row.price_max) || 0
        },
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      };

      return res.json({ talent, message: "Talent profile updated" });
    } else {
      // Create new talent entry
      const result = await db.query(
        `INSERT INTO talent (user_id, category, bio, price_min, price_max, rating, review_count, created_at)
         VALUES ($1, $2, $3, $4, $5, 0, 0, NOW())
         RETURNING *`,
        [userId, category, bio || null, priceMin || 0, priceMax || 0]
      );

      const row = result.rows[0];
      const talent = {
        id: row.id.toString(),
        userId: row.user_id.toString(),
        category: row.category,
        bio: row.bio || null,
        priceRange: {
          min: parseFloat(row.price_min) || 0,
          max: parseFloat(row.price_max) || 0
        },
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      };

      return res.status(201).json({ talent, message: "Talent profile created" });
    }
  } catch (err) {
    console.error("Register talent error:", err);
    res.status(500).json({ error: "Failed to register talent" });
  }
});

export default router;

