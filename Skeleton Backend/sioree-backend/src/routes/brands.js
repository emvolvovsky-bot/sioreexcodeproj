import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";

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

// GET brand insights
router.get("/insights", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Check if user is a brand
    const userResult = await db.query(`SELECT user_type FROM users WHERE id = $1`, [userId]);
    if (userResult.rows.length === 0 || userResult.rows[0].user_type !== 'brand') {
      return res.status(403).json({ error: "Only brands can view insights" });
    }

    // Get total impressions (clicks on promoted events)
    const impressionsResult = await db.query(
      `SELECT COUNT(*) as count 
       FROM event_impressions ei
       INNER JOIN event_promotions ep ON ei.event_id = ep.event_id
       WHERE ep.brand_id = $1 AND ep.is_active = true`,
      [userId]
    );
    const totalImpressions = parseInt(impressionsResult.rows[0]?.count || 0);

    // Get cities activated (count unique cities from brand_cities table)
    const citiesResult = await db.query(
      `SELECT COUNT(*) as count
       FROM brand_cities
       WHERE brand_id = $1`,
      [userId]
    );
    const citiesActivated = parseInt(citiesResult.rows[0]?.count || 0);

    res.json({
      totalImpressions,
      citiesActivated,
      avgCostPerAttendee: null,
      campaignROI: null,
      engagementRate: null
    });
  } catch (err) {
    console.error("Get brand insights error:", err);
    res.status(500).json({ error: "Failed to fetch insights" });
  }
});

// GET promoted events for a brand (to show event dates in campaigns)
router.get("/promoted-events", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Check if user is a brand
    const userResult = await db.query(`SELECT user_type FROM users WHERE id = $1`, [userId]);
    if (userResult.rows.length === 0 || userResult.rows[0].user_type !== 'brand') {
      return res.status(403).json({ error: "Only brands can view promoted events" });
    }

    // Get events promoted by this brand
    const result = await db.query(
      `SELECT 
        e.id,
        e.title,
        e.location,
        e.event_date,
        ep.promoted_at,
        ep.expires_at,
        ep.promotion_budget
      FROM event_promotions ep
      INNER JOIN events e ON ep.event_id = e.id
      WHERE ep.brand_id = $1 AND ep.is_active = true
      ORDER BY ep.promoted_at DESC`,
      [userId]
    );

    const events = result.rows.map(row => ({
      id: row.id.toString(),
      title: row.title,
      location: row.location || "",
      date: row.event_date ? new Date(row.event_date).toISOString() : null,
      promotedAt: row.promoted_at ? new Date(row.promoted_at).toISOString() : null,
      expiresAt: row.expires_at ? new Date(row.expires_at).toISOString() : null,
      budget: parseFloat(row.promotion_budget) || 0
    }));

    res.json({ events });
  } catch (err) {
    console.error("Get promoted events error:", err);
    res.status(500).json({ error: "Failed to fetch promoted events" });
  }
});

// POST track event impression (when partier clicks on event)
router.post("/track-impression", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    const { eventId } = req.body;

    if (!eventId) {
      return res.status(400).json({ error: "Event ID is required" });
    }

    // Check if event is promoted by a brand
    const promotionResult = await db.query(
      `SELECT brand_id FROM event_promotions 
       WHERE event_id = $1 AND is_active = true 
       LIMIT 1`,
      [eventId]
    );

    if (promotionResult.rows.length > 0) {
      const brandId = promotionResult.rows[0].brand_id;
      
      // Track impression (only count once per user per event per day)
      await db.query(
        `INSERT INTO event_impressions (event_id, user_id, brand_id, created_at)
         SELECT $1, $2, $3, NOW()
         WHERE NOT EXISTS (
           SELECT 1 FROM event_impressions 
           WHERE event_id = $1 
           AND user_id = $2 
           AND DATE(created_at) = CURRENT_DATE
         )`,
        [eventId, userId || null, brandId]
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Track impression error:", err);
    res.status(500).json({ error: "Failed to track impression" });
  }
});

export default router;
