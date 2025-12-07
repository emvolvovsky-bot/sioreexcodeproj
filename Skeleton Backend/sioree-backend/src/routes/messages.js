import express from "express";
import db from "../db/database.js";
import jwt from "jsonwebtoken";

const router = express.Router();

// Helper to get Socket.io instance
function getIO(req) {
  return req.app.get("io");
}

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

// GET all conversations for current user (filtered by role if provided)
router.get("/conversations", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // Get role from query parameter (partier, talent, host, brand)
    const role = req.query.role;

    // Build query with optional role filter
    let query;
    let params;
    
    if (role) {
      // Filter conversations by role - only show conversations where messages were sent with this role
      query = `SELECT DISTINCT
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
        COUNT(CASE WHEN m.is_read = false AND m.sender_id != $1 THEN 1 END) as unread_count
      FROM conversations c
      LEFT JOIN users u ON (
        CASE 
          WHEN c.user1_id = $1 THEN u.id = c.user2_id
          ELSE u.id = c.user1_id
        END
      )
      LEFT JOIN LATERAL (
        SELECT text, created_at, is_read, sender_id
        FROM messages
        WHERE conversation_id = c.id
          AND (sender_id = $1 AND sender_role = $2)
        ORDER BY created_at DESC
        LIMIT 1
      ) m ON true
      WHERE (c.user1_id = $1 OR c.user2_id = $1)
        AND EXISTS (
          SELECT 1 FROM messages msg
          WHERE msg.conversation_id = c.id
            AND msg.sender_id = $1
            AND msg.sender_role = $2
        )
      GROUP BY c.id, participant_id, u.name, u.username, u.avatar, m.text, m.created_at
      ORDER BY m.created_at DESC NULLS LAST`;
      params = [userId, role];
    } else {
      // No role filter - show all conversations (backward compatibility)
      query = `SELECT DISTINCT
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
        COUNT(CASE WHEN m.is_read = false AND m.sender_id != $1 THEN 1 END) as unread_count
      FROM conversations c
      LEFT JOIN users u ON (
        CASE 
          WHEN c.user1_id = $1 THEN u.id = c.user2_id
          ELSE u.id = c.user1_id
        END
      )
      LEFT JOIN LATERAL (
        SELECT text, created_at, is_read, sender_id
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) m ON true
      WHERE c.user1_id = $1 OR c.user2_id = $1
      GROUP BY c.id, participant_id, u.name, u.username, u.avatar, m.text, m.created_at
      ORDER BY m.created_at DESC NULLS LAST`;
      params = [userId];
    }

    const result = await db.query(query, params);

    const conversations = result.rows.map(row => ({
      id: row.conversation_id.toString(),
      participantId: row.participant_id.toString(),
      participantName: row.participant_name || row.participant_username || "Unknown",
      participantAvatar: row.participant_avatar || null,
      lastMessage: row.last_message || "",
      lastMessageTime: row.last_message_time ? new Date(row.last_message_time).toISOString() : new Date().toISOString(),
      unreadCount: parseInt(row.unread_count) || 0,
      isActive: true
    }));

    res.json({ conversations });
  } catch (err) {
    console.error("Get conversations error:", err);
    res.status(500).json({ error: "Failed to fetch conversations" });
  }
});

// GET messages for a conversation (filtered by role if provided)
router.get("/:conversationId", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;
    const page = parseInt(req.query.page) || 1;
    const limit = 50;
    const offset = (page - 1) * limit;
    const role = req.query.role; // Get role from query parameter

    // Verify user is part of conversation and get other participant
    // Handle both string and integer conversationId
    const convId = parseInt(conversationId) || conversationId;
    const convCheck = await db.query(
      `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
      [convId, userId]
    );

    if (convCheck.rows.length === 0) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    const conversation = convCheck.rows[0];
    // Determine the other participant (receiver for messages sent by current user)
    const otherUserId = conversation.user1_id === userId ? conversation.user2_id : conversation.user1_id;

    // Build query with optional role filter
    let query;
    let params;
    
    if (role) {
      // Filter messages by role - show messages sent by current user with this role, or received from others
      query = `SELECT * FROM messages 
       WHERE conversation_id = $1 
         AND (
           (sender_id = $2 AND sender_role = $4) OR
           (sender_id != $2)
         )
       ORDER BY created_at DESC 
       LIMIT $3 OFFSET $5`;
      params = [convId, userId, limit, role, offset];
    } else {
      // No role filter - show all messages (backward compatibility)
      query = `SELECT * FROM messages 
       WHERE conversation_id = $1 
       ORDER BY created_at DESC 
       LIMIT $2 OFFSET $3`;
      params = [convId, limit, offset];
    }

    const result = await db.query(query, params);

    const messages = result.rows.map(row => {
      // Determine receiver_id: if sender is current user, receiver is other user, otherwise receiver is current user
      const messageSenderId = row.sender_id;
      const messageReceiverId = messageSenderId === userId ? otherUserId : userId;
      
      return {
        id: row.id.toString(),
        conversationId: row.conversation_id.toString(),
        senderId: row.sender_id.toString(),
        receiverId: messageReceiverId ? messageReceiverId.toString() : (row.receiver_id ? row.receiver_id.toString() : ""),
        text: row.text || row.content || "",
        timestamp: new Date(row.created_at).toISOString(),
        isRead: row.is_read || false,
        messageType: row.message_type || "text"
      };
    }).reverse();

    res.json({ messages, hasMore: result.rows.length === limit });
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

    const { conversationId, receiverId, text, messageType, senderRole } = req.body;
    if (!text) return res.status(400).json({ error: "Message text required" });
    
    // Get sender role from request body or from user's current user_type
    let role = senderRole;
    if (!role) {
      const userResult = await db.query(`SELECT user_type FROM users WHERE id = $1`, [userId]);
      role = userResult.rows[0]?.user_type || null;
    }

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

    // Insert message
    const result = await db.query(
      `INSERT INTO messages (conversation_id, sender_id, receiver_id, text, message_type, is_read, sender_role)
       VALUES ($1, $2, $3, $4, $5, false, $6) RETURNING *`,
      [convId, userId, receiver, text, messageType || "text", role]
    );

    const message = result.rows[0];
    const messageResponse = {
      id: message.id.toString(),
      conversationId: message.conversation_id.toString(),
      senderId: message.sender_id.toString(),
      receiverId: message.receiver_id.toString(),
      text: message.text,
      timestamp: new Date(message.created_at).toISOString(),
      isRead: message.is_read || false,
      messageType: message.message_type || "text"
    };

    // Emit message via Socket.io for real-time delivery
    const io = getIO(req);
    if (io) {
      io.emit("receive_message", messageResponse);
      // Also emit to specific conversation room
      io.to(`conversation:${convId}`).emit("new_message", messageResponse);
    }

    res.json(messageResponse);
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

// DELETE a message (soft delete - only for the user who deletes it)
router.delete("/:messageId", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const messageId = req.params.messageId;

    // Verify user is the sender of the message
    const messageCheck = await db.query(
      `SELECT sender_id FROM messages WHERE id = $1`,
      [messageId]
    );

    if (messageCheck.rows.length === 0) {
      return res.status(404).json({ error: "Message not found" });
    }

    if (messageCheck.rows[0].sender_id !== userId) {
      return res.status(403).json({ error: "You can only delete your own messages" });
    }

    // Soft delete: Add deleted_by column if it doesn't exist, or use a deleted_messages table
    // For now, we'll use a simple approach: mark as deleted
    await db.query(
      `UPDATE messages SET text = '[Message deleted]', message_type = 'deleted' WHERE id = $1`,
      [messageId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Delete message error:", err);
    res.status(500).json({ error: "Failed to delete message" });
  }
});

export default router;
