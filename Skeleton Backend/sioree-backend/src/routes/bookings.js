import express from "express";
import db from "../db/database.js";
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

// GET USER BOOKINGS
router.get("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const result = await db.query(
      `SELECT 
        b.*,
        t.category as talent_category,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        tu.username as talent_username,
        tu.name as talent_name,
        tu.avatar as talent_avatar
      FROM bookings b
      LEFT JOIN talent t ON b.talent_id = t.id
      LEFT JOIN users u ON b.host_id = u.id
      LEFT JOIN users tu ON t.user_id = tu.id
      WHERE b.host_id = $1 OR t.user_id = $1
      ORDER BY b.date DESC`,
      [userId]
    );

    const bookings = result.rows.map(row => ({
      id: row.id.toString(),
      talentId: row.talent_id.toString(),
      hostId: row.host_id.toString(),
      eventId: row.event_id?.toString() || null,
      date: new Date(row.date).toISOString(),
      duration: row.duration || null,
      price: parseFloat(row.price) || 0,
      status: row.status || "pending",
      notes: row.notes || null,
      talentName: row.talent_name || row.talent_username || "Unknown",
      talentCategory: row.talent_category || null,
      talentAvatar: row.talent_avatar || null,
      hostName: row.host_name || row.host_username || "Unknown",
      hostAvatar: row.host_avatar || null,
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
    }));

    res.json({ bookings });
  } catch (err) {
    console.error("Get bookings error:", err);
    res.status(500).json({ error: "Failed to fetch bookings" });
  }
});

// CREATE BOOKING
router.post("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { talentId, eventId, date, duration, price, notes } = req.body;

    // Get talent user_id from talent table
    const talentResult = await db.query(`SELECT id FROM talent WHERE id = $1 OR user_id = $1`, [talentId]);
    if (talentResult.rows.length === 0) {
      return res.status(404).json({ error: "Talent not found" });
    }
    const actualTalentId = talentResult.rows[0].id;

    const result = await db.query(
      `INSERT INTO bookings (talent_id, host_id, event_id, date, duration, price, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [actualTalentId, userId, eventId || null, date, duration || null, price, notes || null]
    );

    const booking = result.rows[0];
    res.json({
      id: booking.id.toString(),
      talentId: booking.talent_id.toString(),
      hostId: booking.host_id.toString(),
      eventId: booking.event_id?.toString() || null,
      date: new Date(booking.date).toISOString(),
      duration: booking.duration || null,
      price: parseFloat(booking.price) || 0,
      status: booking.status || "pending",
      notes: booking.notes || null,
      createdAt: booking.created_at ? new Date(booking.created_at).toISOString() : new Date().toISOString()
    });
  } catch (err) {
    console.error("Create booking error:", err);
    res.status(500).json({ error: "Failed to create booking" });
  }
});

// UPDATE BOOKING STATUS
router.patch("/:id/status", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { status } = req.body;
    const bookingId = req.params.id;

    await db.query(
      `UPDATE bookings SET status = $1, updated_at = NOW() WHERE id = $2`,
      [status, bookingId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Update booking status error:", err);
    res.status(500).json({ error: "Failed to update booking status" });
  }
});

export default router;

