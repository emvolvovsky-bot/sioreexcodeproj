import express from "express";
import db from "../db/database.js";

const router = express.Router();

// 🔹 Create a new conversation between two users
router.post("/conversation", (req, res) => {
  const { user1, user2 } = req.body;

  if (!user1 || !user2) {
    return res.status(400).json({ error: "Missing user IDs" });
  }

  const stmt = db.prepare(
    "INSERT INTO conversations (user1_id, user2_id) VALUES (?, ?)"
  );

  stmt.run([user1, user2], function (err) {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ conversationId: this.lastID });
  });
});

// 🔹 Send a new message
router.post("/send", (req, res) => {
  const { conversationId, senderId, text } = req.body;

  if (!conversationId || !senderId || !text) {
    return res.status(400).json({ error: "Missing fields" });
  }

  const stmt = db.prepare(
    "INSERT INTO messages (conversation_id, sender_id, text) VALUES (?, ?, ?)"
  );

  stmt.run([conversationId, senderId, text], function (err) {
    if (err) {
      r
rm -f messages.js
touch messages.js
cat > messages.js << 'EOF'
import express from "express";
import db from "../db/database.js";

const router = express.Router();

// 🔹 Create a new conversation between two users
router.post("/conversation", (req, res) => {
  const { user1, user2 } = req.body;

  if (!user1 || !user2) {
    return res.status(400).json({ error: "Missing user IDs" });
  }

  const stmt = db.prepare(
    "INSERT INTO conversations (user1_id, user2_id) VALUES (?, ?)"
  );

  stmt.run([user1, user2], function (err) {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ conversationId: this.lastID });
  });
});

// 🔹 Send a new message
router.post("/send", (req, res) => {
  const { conversationId, senderId, text } = req.body;

  if (!conversationId || !senderId || !text) {
    return res.status(400).json({ error: "Missing fields" });
  }

  const stmt = db.prepare(
    "INSERT INTO messages (conversation_id, sender_id, text) VALUES (?, ?, ?)"
  );

  stmt.run([conversationId, senderId, text], function (err) {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ messageId: this.lastID });
  });
});

// 🔹 Get all messages in a conversation
router.get("/:conversationId", (req, res) => {
  const id = req.params.conversationId;

  const stmt = db.prepare(
    "SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC"
  );

  stmt.all([id], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ messages: rows });
  });
});

export default router;
