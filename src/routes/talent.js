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

export default router;

