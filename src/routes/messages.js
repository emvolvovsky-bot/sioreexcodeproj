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

// GET all conversations for current user
router.get("/conversations", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // Support delta queries using updated_after (ISO8601)
    const updatedAfter = req.query.updated_after;

    // Base query returns conversations with last message
    let baseQuery = `
      SELECT DISTINCT
        CASE 
          WHEN c.user1_id = $1 THEN c.user2_id
          ELSE c.user1_id
        END as participant_id,
        c.id as conversation_id,
        u.name as participant_name,
        u.username as participant_username,
        u.avatar as participant_avatar,
        m.text as last_message,
        m.created_at as last_message_time,
        c.updated_at as conversation_updated_at,
        COUNT(CASE WHEN m.is_read = false AND m.sender_id != $1 THEN 1 END) as unread_count
      FROM conversations c
      LEFT JOIN users u ON (
        CASE 
          WHEN c.user1_id = $1 THEN u.id = c.user2_id
          ELSE u.id = c.user1_id
        END
      )
      LEFT JOIN LATERAL (
        SELECT COALESCE(text, content) AS text, created_at, is_read, sender_id
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) m ON true
      WHERE c.user1_id = $1 OR c.user2_id = $1
    `;

    const params = [userId];

    if (updatedAfter) {
      // Filter conversations/messages updated after provided timestamp
      params.push(updatedAfter);
      baseQuery += ` AND (c.updated_at > $2 OR (m.created_at IS NOT NULL AND m.created_at > $2))`;
    }

    baseQuery += `
      GROUP BY c.id, participant_id, u.name, u.username, u.avatar, m.text, m.created_at, c.updated_at
      ORDER BY m.created_at DESC NULLS LAST
    `;

    const result = await db.query(baseQuery, params);

    const conversations = result.rows.map(row => ({
      id: row.conversation_id.toString(),
      participantId: row.participant_id.toString(),
      participantName: row.participant_name || row.participant_username || "Unknown",
      participantAvatar: row.participant_avatar || null,
      lastMessage: row.last_message || "",
      lastMessageTime: row.last_message_time ? new Date(row.last_message_time).toISOString() : new Date().toISOString(),
      updatedAt: row.conversation_updated_at ? new Date(row.conversation_updated_at).toISOString() : null,
      unreadCount: parseInt(row.unread_count) || 0,
      isActive: true
    }));

    res.json({ conversations });
  } catch (err) {
    console.error("Get conversations error:", err);
    res.status(500).json({ error: "Failed to fetch conversations" });
  }
});

// GET messages for a conversation
router.get("/:conversationId", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;
    const updatedAfter = req.query.updated_after;
    const page = parseInt(req.query.page) || 1;
    const limit = 50;
    const offset = (page - 1) * limit;

    // Verify user is part of conversation
    const convCheck = await db.query(
      `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
      [conversationId, userId]
    );

    if (convCheck.rows.length === 0) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    let result;
    if (updatedAfter) {
      // Return messages newer than provided timestamp (delta)
      result = await db.query(
        `SELECT * FROM messages 
         WHERE conversation_id = $1 AND created_at > $2
         ORDER BY created_at ASC`,
        [conversationId, updatedAfter]
      );
      const messages = result.rows.map(row => ({
        id: row.id.toString(),
        conversationId: row.conversation_id.toString(),
        senderId: row.sender_id.toString(),
        receiverId: row.receiver_id.toString(),
        text: row.text || "",
        timestamp: new Date(row.created_at).toISOString(),
        isRead: row.is_read || false,
        messageType: row.message_type || "text",
        clientTempId: row.client_temp_id || null
      }));
      return res.json({ messages, hasMore: false });
    } else {
      result = await db.query(
        `SELECT * FROM messages 
         WHERE conversation_id = $1 
         ORDER BY created_at DESC 
         LIMIT $2 OFFSET $3`,
        [conversationId, limit, offset]
      );

      const messages = result.rows.map(row => ({
        id: row.id.toString(),
        conversationId: row.conversation_id.toString(),
        senderId: row.sender_id.toString(),
        receiverId: row.receiver_id.toString(),
        text: row.text || "",
        timestamp: new Date(row.created_at).toISOString(),
        isRead: row.is_read || false,
        messageType: row.message_type || "text"
      })).reverse();

      res.json({ messages, hasMore: result.rows.length === limit });
    }
  } catch (err) {
    console.error("Get messages error:", err);
    res.status(500).json({ error: "Failed to fetch messages" });
  }
});

// POST create or get conversation with a user
router.post("/conversation", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { userId: otherUserId } = req.body;
    if (!otherUserId) return res.status(400).json({ error: "Missing userId" });

    // Check if conversation already exists
    let result = await db.query(
      `SELECT * FROM conversations 
       WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)`,
      [userId, otherUserId]
    );

    if (result.rows.length > 0) {
      const conv = result.rows[0];
      const otherUser = await db.query(`SELECT name, username, avatar FROM users WHERE id = $1`, [otherUserId]);
      const user = otherUser.rows[0] || {};

      return res.json({
        id: conv.id.toString(),
        participantId: otherUserId.toString(),
        participantName: user.name || user.username || "Unknown",
        participantAvatar: user.avatar || null,
        lastMessage: "",
        lastMessageTime: new Date().toISOString(),
        unreadCount: 0,
        isActive: true
      });
    }

    // Create new conversation
    result = await db.query(
      `INSERT INTO conversations (user1_id, user2_id) VALUES ($1, $2) RETURNING *`,
      [userId, otherUserId]
    );

    const otherUser = await db.query(`SELECT name, username, avatar FROM users WHERE id = $1`, [otherUserId]);
    const user = otherUser.rows[0] || {};

    res.json({
      id: result.rows[0].id.toString(),
      participantId: otherUserId.toString(),
      participantName: user.name || user.username || "Unknown",
      participantAvatar: user.avatar || null,
      lastMessage: "",
      lastMessageTime: new Date().toISOString(),
      unreadCount: 0,
      isActive: true
    });
  } catch (err) {
    console.error("Create conversation error:", err);
    res.status(500).json({ error: "Failed to create conversation" });
  }
});

// POST send a message
router.post("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { conversationId, receiverId, text, messageType, clientTempId } = req.body;
    if (!text) return res.status(400).json({ error: "Message text required" });

    let convId = conversationId;

    // If no conversationId, create or get conversation
    if (!convId && receiverId) {
      let result = await db.query(
        `SELECT * FROM conversations 
         WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)`,
        [userId, receiverId]
      );

      if (result.rows.length === 0) {
        result = await db.query(
          `INSERT INTO conversations (user1_id, user2_id) VALUES ($1, $2) RETURNING *`,
          [userId, receiverId]
        );
      }
      convId = result.rows[0].id.toString();
    }

    if (!convId) return res.status(400).json({ error: "Conversation ID or receiver ID required" });

    // Verify user is part of conversation
    const convCheck = await db.query(
      `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
      [convId, userId]
    );

    if (convCheck.rows.length === 0) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    // Determine receiver
    const conv = convCheck.rows[0];
    const receiver = receiverId || (conv.user1_id.toString() === userId ? conv.user2_id : conv.user1_id);

    // Insert message (store clientTempId if provided for reconciliation)
    const result = await db.query(
      `INSERT INTO messages (conversation_id, sender_id, receiver_id, text, message_type, is_read, client_temp_id)
       VALUES ($1, $2, $3, $4, $5, false, $6) RETURNING *`,
      [convId, userId, receiver, text, messageType || "text", clientTempId || null]
    );

    // Ensure conversation updated_at reflects the new message so clients listing conversations
    // will consistently see the message as the latest item.
    try {
      await db.query(`UPDATE conversations SET updated_at = NOW() WHERE id = $1`, [convId]);
    } catch (e) {
      console.error("Failed to update conversation timestamp:", e);
    }

    const message = result.rows[0];
    res.json({
      id: message.id.toString(),
      conversationId: message.conversation_id.toString(),
      senderId: message.sender_id.toString(),
      receiverId: message.receiver_id.toString(),
      text: message.text,
      timestamp: new Date(message.created_at).toISOString(),
      isRead: message.is_read || false,
      messageType: message.message_type || "text",
      clientTempId: message.client_temp_id || null
    });
  } catch (err) {
    console.error("Send message error:", err);
    res.status(500).json({ error: "Failed to send message" });
  }
});

// POST mark conversation as read
router.post("/:conversationId/read", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;

    await db.query(
      `UPDATE messages SET is_read = true 
       WHERE conversation_id = $1 AND receiver_id = $2 AND is_read = false`,
      [conversationId, userId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Mark as read error:", err);
    res.status(500).json({ error: "Failed to mark as read" });
  }
});

export default router;
