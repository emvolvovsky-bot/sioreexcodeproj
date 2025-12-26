import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";
import { createPaymentIntent } from "../services/payments.js";

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
      paymentStatus: row.payment_status || "pending_payment",
      paymentIntentId: row.payment_intent_id || null,
      paidAt: row.paid_at ? new Date(row.paid_at).toISOString() : null,
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
    const parsedPrice = parseFloat(price);
    
    if (isNaN(parsedPrice) || parsedPrice <= 0) {
      return res.status(400).json({ error: "Price must be greater than 0 for prepayment" });
    }

    // Get talent user_id from talent table
    const talentResult = await db.query(`SELECT id FROM talent WHERE id = $1 OR user_id = $1`, [talentId]);
    if (talentResult.rows.length === 0) {
      return res.status(404).json({ error: "Talent not found" });
    }
    const actualTalentId = talentResult.rows[0].id;

    // Create booking first to get an ID
    const bookingInsert = await db.query(
      `INSERT INTO bookings (talent_id, host_id, event_id, date, duration, price, status, payment_status, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        actualTalentId,
        userId,
        eventId || null,
        date,
        duration || null,
        parsedPrice,
        "pending_payment",
        "requires_payment",
        notes || null
      ]
    );

    const booking = bookingInsert.rows[0];

    // Create a payment intent so host prepays before the booking is confirmed
    let paymentIntent;
    try {
      paymentIntent = await createPaymentIntent(parsedPrice, null, {
        bookingId: booking.id,
        hostId: userId,
        talentId: actualTalentId,
        eventId: eventId || ""
      });
    } catch (err) {
      console.warn("⚠️ Payment intent creation failed, falling back to mock intent:", err?.message || err);
      paymentIntent = { id: `pi_mock_${Date.now()}`, client_secret: "mock_client_secret" };
    }

    // Persist payment_intent_id on the booking
    await db.query(
      `UPDATE bookings SET payment_intent_id = $1 WHERE id = $2`,
      [paymentIntent.id, booking.id]
    );

    res.json({
      id: booking.id.toString(),
      talentId: booking.talent_id.toString(),
      hostId: booking.host_id.toString(),
      eventId: booking.event_id?.toString() || null,
      date: new Date(booking.date).toISOString(),
      duration: booking.duration || null,
      price: parseFloat(booking.price) || 0,
      status: booking.status || "pending_payment",
      paymentStatus: booking.payment_status || "requires_payment",
      paymentIntentId: booking.payment_intent_id || paymentIntent.id,
      paymentIntentClientSecret: paymentIntent.client_secret,
      notes: booking.notes || null,
      createdAt: booking.created_at ? new Date(booking.created_at).toISOString() : new Date().toISOString()
    });
  } catch (err) {
    console.error("Create booking error:", err);
    res.status(500).json({ error: "Failed to create booking" });
  }
});

// CONFIRM BOOKING PAYMENT (host pays upfront, funds held for talent)
router.post("/:id/confirm-payment", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const bookingId = req.params.id;
    const bookingResult = await db.query(
      `SELECT b.*, t.user_id as talent_user_id 
       FROM bookings b 
       LEFT JOIN talent t ON b.talent_id = t.id
       WHERE b.id = $1`,
      [bookingId]
    );

    if (bookingResult.rows.length === 0) {
      return res.status(404).json({ error: "Booking not found" });
    }

    const booking = bookingResult.rows[0];
    if (booking.host_id?.toString() !== userId.toString()) {
      return res.status(403).json({ error: "Only the host can confirm and pay for this booking" });
    }

    // Prevent duplicate confirmations
    if (booking.payment_status === "paid") {
      return res.json({ success: true, status: booking.status || "confirmed" });
    }

    await db.query(
      `UPDATE bookings 
       SET payment_status = 'paid', status = 'confirmed', paid_at = NOW() 
       WHERE id = $1`,
      [bookingId]
    );

    // Credit the talent's available earnings
    const earningsCheck = await db.query(
      `SELECT id FROM talent_earnings WHERE booking_id = $1`,
      [bookingId]
    );
    if (earningsCheck.rows.length === 0) {
      await db.query(
        `INSERT INTO talent_earnings (talent_id, booking_id, amount, status)
         VALUES ($1, $2, $3, 'available')`,
        [booking.talent_id, bookingId, booking.price]
      );
    }

    res.json({ success: true, status: "confirmed" });
  } catch (err) {
    console.error("Confirm booking payment error:", err);
    res.status(500).json({ error: "Failed to confirm booking payment" });
  }
});

// UPDATE BOOKING STATUS
router.patch("/:id/status", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { status } = req.body;
    const bookingId = req.params.id;

    const bookingResult = await db.query(
      `UPDATE bookings 
       SET status = $1, 
           payment_status = CASE WHEN $1 = 'cancelled' THEN 'refund_pending' ELSE payment_status END,
           updated_at = NOW() 
       WHERE id = $2
       RETURNING *`,
      [status, bookingId]
    );

    if (status === "cancelled") {
      await db.query(
        `UPDATE talent_earnings SET status = 'refunded' WHERE booking_id = $1`,
        [bookingId]
      );
      await db.query(
        `UPDATE bookings SET refund_status = 'pending_refund' WHERE id = $1 AND payment_status = 'paid'`,
        [bookingId]
      );
    }

    res.json({ success: true, booking: bookingResult.rows[0] });
  } catch (err) {
    console.error("Update booking status error:", err);
    res.status(500).json({ error: "Failed to update booking status" });
  }
});

export default router;



