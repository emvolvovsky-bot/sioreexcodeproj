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

// GET earnings for current user (host or talent)
router.get("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Get user type
    const userResult = await db.query(`SELECT user_type FROM users WHERE id = $1`, [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const userType = userResult.rows[0].user_type;
    if (userType !== 'host' && userType !== 'talent') {
      return res.status(403).json({ error: "Only hosts and talents can view earnings" });
    }

    // Calculate total earnings from completed bookings/payments
    // For hosts: earnings from ticket sales
    // For talent: earnings from bookings
    let earningsQuery;
    if (userType === 'host') {
      // Host earnings from ticket sales (event_attendees where event was created by host)
      earningsQuery = `
        SELECT 
          ea.id,
          ea.event_id,
          e.title as source,
          e.ticket_price as amount,
          ea.created_at as date
        FROM event_attendees ea
        INNER JOIN events e ON ea.event_id = e.id
        WHERE e.creator_id = $1 
          AND e.ticket_price > 0
          AND e.event_date < NOW()
        ORDER BY ea.created_at DESC
      `;
    } else {
      // Talent earnings from completed bookings
      earningsQuery = `
        SELECT 
          b.id,
          b.event_id,
          COALESCE(e.title, 'Booking') as source,
          b.price as amount,
          b.date
        FROM bookings b
        LEFT JOIN events e ON b.event_id = e.id
        WHERE b.talent_id = (SELECT id FROM talent WHERE user_id = $1)
          AND b.status = 'completed'
        ORDER BY b.date DESC
      `;
    }

    const earningsResult = await db.query(earningsQuery, [userId]);
    
    const earnings = earningsResult.rows.map(row => ({
      id: row.id.toString(),
      amount: parseFloat(row.amount) || 0,
      source: row.source || "Payment",
      date: row.date ? new Date(row.date).toISOString() : new Date().toISOString(),
      eventId: row.event_id ? row.event_id.toString() : null
    }));

    // Calculate total earnings
    const totalEarnings = earnings.reduce((sum, e) => sum + e.amount, 0);

    // Get withdrawal history
    const withdrawalsResult = await db.query(
      `SELECT 
        w.id,
        w.amount,
        ba.bank_name as bank_account_name,
        w.created_at as date,
        w.status
      FROM withdrawals w
      INNER JOIN bank_accounts ba ON w.bank_account_id = ba.id
      WHERE w.user_id = $1
      ORDER BY w.created_at DESC`,
      [userId]
    );

    const withdrawals = withdrawalsResult.rows.map(row => ({
      id: row.id.toString(),
      amount: parseFloat(row.amount) || 0,
      bankAccountName: row.bank_account_name || "Bank Account",
      date: row.date ? new Date(row.date).toISOString() : new Date().toISOString(),
      status: row.status || "pending"
    }));

    // Subtract withdrawn amounts from total
    const totalWithdrawn = withdrawals
      .filter(w => w.status === 'completed')
      .reduce((sum, w) => sum + w.amount, 0);
    
    const availableBalance = totalEarnings - totalWithdrawn;

    res.json({
      totalEarnings: availableBalance,
      earnings,
      withdrawals
    });
  } catch (err) {
    console.error("Get earnings error:", err);
    res.status(500).json({ error: "Failed to fetch earnings" });
  }
});

// POST withdraw earnings
router.post("/withdraw", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { amount, bankAccountId } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }
    if (!bankAccountId) {
      return res.status(400).json({ error: "Bank account required" });
    }

    // Verify bank account belongs to user
    const bankAccountResult = await db.query(
      `SELECT id FROM bank_accounts WHERE id = $1 AND user_id = $2`,
      [bankAccountId, userId]
    );

    if (bankAccountResult.rows.length === 0) {
      return res.status(404).json({ error: "Bank account not found" });
    }

    // Get available balance
    const earningsResult = await db.query(
      `SELECT 
        COALESCE(SUM(CASE 
          WHEN u.user_type = 'host' THEN 
            (SELECT COALESCE(SUM(e.ticket_price), 0) 
             FROM event_attendees ea 
             INNER JOIN events e ON ea.event_id = e.id 
             WHERE e.creator_id = u.id AND e.ticket_price > 0 AND e.event_date < NOW())
          WHEN u.user_type = 'talent' THEN
            (SELECT COALESCE(SUM(b.price), 0)
             FROM bookings b
             INNER JOIN talent t ON b.talent_id = t.id
             WHERE t.user_id = u.id AND b.status = 'completed')
          ELSE 0
        END), 0) as total_earnings
      FROM users u
      WHERE u.id = $1`,
      [userId]
    );

    const totalEarnings = parseFloat(earningsResult.rows[0]?.total_earnings || 0);

    const withdrawalsResult = await db.query(
      `SELECT COALESCE(SUM(amount), 0) as total_withdrawn
       FROM withdrawals
       WHERE user_id = $1 AND status = 'completed'`,
      [userId]
    );

    const totalWithdrawn = parseFloat(withdrawalsResult.rows[0]?.total_withdrawn || 0);
    const availableBalance = totalEarnings - totalWithdrawn;

    if (amount > availableBalance) {
      return res.status(400).json({ error: "Insufficient balance" });
    }

    // Create withdrawal record
    const withdrawalResult = await db.query(
      `INSERT INTO withdrawals (user_id, bank_account_id, amount, status, created_at)
       VALUES ($1, $2, $3, 'pending', NOW())
       RETURNING id`,
      [userId, bankAccountId, amount]
    );

    // In production, this would trigger a Stripe payout or bank transfer
    // For now, we'll just mark it as processing
    await db.query(
      `UPDATE withdrawals SET status = 'processing' WHERE id = $1`,
      [withdrawalResult.rows[0].id]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Withdraw earnings error:", err);
    res.status(500).json({ error: "Failed to process withdrawal" });
  }
});

export default router;








