import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";
import stripe from "../lib/stripe.js";

const router = express.Router();

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

const resolveStripeClient = (req) => {
  const mode = req.body?.mode || req.query?.mode || req.headers["x-stripe-mode"];
  if (typeof stripe.getStripeClient === "function") {
    return stripe.getStripeClient(mode);
  }
  return stripe;
};

// GET current user's earnings and withdrawals
router.get("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const talentResult = await db.query(`SELECT id FROM talent WHERE user_id = $1`, [userId]);
    if (talentResult.rows.length === 0) {
      return res.json({ totalEarnings: 0, earnings: [], withdrawals: [] });
    }
    const talentId = talentResult.rows[0].id;

    const earningsResult = await db.query(
      `SELECT te.*, b.event_id 
       FROM talent_earnings te 
       LEFT JOIN bookings b ON te.booking_id = b.id
       WHERE te.talent_id = $1
       ORDER BY te.created_at DESC`,
      [talentId]
    );

    const withdrawalsResult = await db.query(
      `SELECT w.*, b.institution_name, b.last4
       FROM withdrawals w
       LEFT JOIN bank_accounts b ON w.bank_account_id = b.id
       WHERE w.user_id = $1
       ORDER BY w.created_at DESC`,
      [userId]
    );

    const earnings = earningsResult.rows.map(row => ({
      id: row.id.toString(),
      amount: parseFloat(row.amount) || 0,
      source: "Booking",
      date: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
      eventId: row.event_id ? row.event_id.toString() : null
    }));

    const withdrawals = withdrawalsResult.rows.map(row => ({
      id: row.id.toString(),
      amount: parseFloat(row.amount) || 0,
      bankAccountName: row.institution_name
        ? `${row.institution_name}${row.last4 ? ` •••• ${row.last4}` : ""}`
        : "Bank Account",
      date: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
      status: row.status || "pending"
    }));

    const availableTotal = earningsResult.rows
      .filter(row => row.status === "available" || row.status === "pending_withdrawal")
      .reduce((sum, row) => sum + (parseFloat(row.amount) || 0), 0);

    res.json({
      totalEarnings: availableTotal,
      earnings,
      withdrawals
    });
  } catch (err) {
    console.error("Get earnings error:", err);
    res.status(500).json({ error: "Failed to fetch earnings" });
  }
});

// POST withdraw earnings to a bank account
router.post("/withdraw", async (req, res) => {
  const client = await db.connect();
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { amount, bankAccountId } = req.body;
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      client.release();
      return res.status(400).json({ error: "Withdrawal amount must be greater than zero" });
    }

    await client.query("BEGIN");

    const talentResult = await client.query(
      `SELECT id FROM talent WHERE user_id = $1`,
      [userId]
    );
    if (talentResult.rows.length === 0) {
      await client.query("ROLLBACK");
      client.release();
      return res.status(400).json({ error: "No talent profile found for withdrawals" });
    }
    const talentId = talentResult.rows[0].id;

    const availableRows = await client.query(
      `SELECT * FROM talent_earnings 
       WHERE talent_id = $1 AND status = 'available'
       ORDER BY created_at ASC`,
      [talentId]
    );

    let remaining = parsedAmount;
    const earningIdsToLock = [];
    for (const row of availableRows.rows) {
      if (remaining <= 0) break;
      remaining -= parseFloat(row.amount) || 0;
      earningIdsToLock.push(row.id);
    }

    if (remaining > 0) {
      await client.query("ROLLBACK");
      client.release();
      return res.status(400).json({ error: "Insufficient available balance to withdraw" });
    }

    if (earningIdsToLock.length > 0) {
      await client.query(
        `UPDATE talent_earnings 
         SET status = 'pending_withdrawal' 
         WHERE id = ANY($1::int[])`,
        [earningIdsToLock]
      );
    }

    const withdrawalResult = await client.query(
      `INSERT INTO withdrawals (user_id, amount, bank_account_id, status)
       VALUES ($1, $2, $3, 'processing')
       RETURNING *`,
      [userId, parsedAmount, bankAccountId || null]
    );

    await client.query("COMMIT");
    const withdrawal = withdrawalResult.rows[0];
    client.release();

    try {
      const stripeClient = resolveStripeClient(req);
      if (!stripeClient || !stripeClient.payouts || !stripeClient.accounts) {
        throw new Error("Stripe is not configured");
      }

      const userResult = await db.query(
        "SELECT stripe_account_id FROM users WHERE id = $1",
        [userId]
      );
      const stripeAccountId = userResult.rows[0]?.stripe_account_id;
      if (!stripeAccountId) {
        throw new Error("No connected Stripe account for user");
      }

      if (bankAccountId) {
        const bankResult = await db.query(
          `SELECT stripe_external_account_id
           FROM bank_accounts
           WHERE id = $1 AND user_id = $2`,
          [bankAccountId, userId]
        );
        const externalId = bankResult.rows[0]?.stripe_external_account_id;
        if (externalId) {
          await stripeClient.accounts.updateExternalAccount(
            stripeAccountId,
            externalId,
            { default_for_currency: true }
          );
        }
      }

      const payout = await stripeClient.payouts.create(
        {
          amount: Math.round(parsedAmount * 100),
          currency: "usd",
          method: "standard"
        },
        { stripeAccount: stripeAccountId }
      );

      await db.query(
        `UPDATE withdrawals
         SET stripe_payout_id = $1
         WHERE id = $2`,
        [payout.id, withdrawal.id]
      );
    } catch (stripeError) {
      console.error("Stripe payout error:", stripeError);
      await db.query(
        `UPDATE withdrawals
         SET status = 'failed'
         WHERE id = $1`,
        [withdrawal.id]
      );
    }

    let bankAccountName = "Bank Account";
    if (bankAccountId) {
      const bankResult = await db.query(
        `SELECT institution_name, last4
         FROM bank_accounts
         WHERE id = $1 AND user_id = $2`,
        [bankAccountId, userId]
      );
      const bankRow = bankResult.rows[0];
      if (bankRow?.institution_name) {
        bankAccountName = `${bankRow.institution_name}${
          bankRow.last4 ? ` •••• ${bankRow.last4}` : ""
        }`;
      }
    }

    res.json({
      success: true,
      withdrawal: {
        id: withdrawal.id.toString(),
        amount: parseFloat(withdrawal.amount) || 0,
        status: withdrawal.status,
        bankAccountName,
        date: withdrawal.created_at ? new Date(withdrawal.created_at).toISOString() : new Date().toISOString()
      }
    });
  } catch (err) {
    await client.query("ROLLBACK");
    client.release();
    console.error("Withdraw earnings error:", err);
    res.status(500).json({ error: "Failed to submit withdrawal" });
  }
});

export default router;


