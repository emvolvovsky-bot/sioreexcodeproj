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

// POST /api/bank/link-token - Get Plaid Link token
router.post("/link-token", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // In production, this would call Plaid API to get a link token
    // For now, return a mock token that can be used for testing
    const linkToken = `link_token_${Date.now()}_${userId}`;
    
    res.json({ linkToken });
  } catch (err) {
    console.error("Get link token error:", err);
    res.status(500).json({ error: "Failed to get link token" });
  }
});

// POST /api/bank/exchange-token - Exchange Plaid public token for access token
router.post("/exchange-token", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { public_token } = req.body;
    if (!public_token) {
      return res.status(400).json({ error: "Public token required" });
    }

    // In production, this would call Plaid API to exchange the public token
    // For now, create a mock bank account entry
    const result = await db.query(
      `INSERT INTO bank_accounts (user_id, bank_name, account_type, last4, is_verified, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING id, bank_name, account_type, last4, is_verified, created_at`,
      [userId, "Mock Bank", "checking", "1234", true]
    );

    const account = result.rows[0];
    res.json({
      id: account.id.toString(),
      bankName: account.bank_name,
      accountType: account.account_type,
      last4: account.last4,
      isVerified: account.is_verified,
      createdAt: account.created_at
    });
  } catch (err) {
    console.error("Exchange token error:", err);
    res.status(500).json({ error: "Failed to exchange token" });
  }
});

// GET /api/bank/accounts - Get all bank accounts for current user
router.get("/accounts", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const result = await db.query(
      `SELECT id, bank_name, account_type, last4, is_verified, created_at
       FROM bank_accounts
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    const accounts = result.rows.map(row => ({
      id: row.id.toString(),
      bankName: row.bank_name,
      accountType: row.account_type || "checking",
      last4: row.last4 || "0000",
      isVerified: row.is_verified || false,
      createdAt: row.created_at
    }));

    res.json({ accounts });
  } catch (err) {
    console.error("Get bank accounts error:", err);
    res.status(500).json({ error: "Failed to fetch bank accounts" });
  }
});

// DELETE /api/bank/accounts/:accountId - Remove bank account
router.delete("/accounts/:accountId", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const accountId = req.params.accountId;

    // Verify the account belongs to the user
    const checkResult = await db.query(
      `SELECT id FROM bank_accounts WHERE id = $1 AND user_id = $2`,
      [accountId, userId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: "Bank account not found" });
    }

    await db.query(
      `DELETE FROM bank_accounts WHERE id = $1 AND user_id = $2`,
      [accountId, userId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Delete bank account error:", err);
    res.status(500).json({ error: "Failed to delete bank account" });
  }
});

export default router;
