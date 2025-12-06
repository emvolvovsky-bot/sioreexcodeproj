import express from "express";
import db from "../db/database.js";

const router = express.Router();

// 🔹 Store a new Plaid-linked bank account
router.post("/connect", (req, res) => {
  const { userId, bankName, accountMask } = req.body;

  if (!userId || !bankName || !accountMask) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const stmt = db.prepare(
    "INSERT INTO bank_accounts (user_id, bank_name, account_mask) VALUES (?, ?, ?)"
  );

  stmt.run([userId, bankName, accountMask], function (err) {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ success: true, accountId: this.lastID });
  });
});

// 🔹 Get all bank accounts for a user
router.get("/:userId", (req, res) => {
  const userId = req.params.userId;

  const stmt = db.prepare("SELECT * FROM bank_accounts WHERE user_id = ?");
  stmt.all([userId], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ accounts: rows });
  });
});

export default router;
