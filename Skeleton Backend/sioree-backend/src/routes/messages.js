import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";

const router = express.Router();

// Ensure required messaging columns exist (safety when migrations missed)
let messageSchemaEnsured = false;
async function ensureMessageColumns() {
  if (messageSchemaEnsured) return;

  try {
    const columns = [
      { name: "sender_role", ddl: "ALTER TABLE messages ADD COLUMN sender_role VARCHAR(50)" },
      { name: "receiver_role", ddl: "ALTER TABLE messages ADD COLUMN receiver_role VARCHAR(50)" },
      { name: "text", ddl: "ALTER TABLE messages ADD COLUMN text TEXT" },
      { name: "message_type", ddl: "ALTER TABLE messages ADD COLUMN message_type VARCHAR(50) DEFAULT 'text'" },
      { name: "is_read", ddl: "ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE" }
    ];

    for (const col of columns) {
      const exists = await db.query(
        `SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = $1 LIMIT 1`,
        [col.name]
      );
      if (exists.rows.length === 0) {
        await db.query(col.ddl);
      }
    }

    // Helpful index for role-aware lookups (safe if column exists)
    await db.query(`CREATE INDEX IF NOT EXISTS idx_messages_sender_role ON messages(sender_id, sender_role)`);

    // Backfill sender_role where missing using current user_type
    await db.query(`
      UPDATE messages m
      SET sender_role = u.user_type
      FROM users u
      WHERE m.sender_role IS NULL AND u.id = m.sender_id
    `);

    messageSchemaEnsured = true;
  } catch (err) {
    console.error("ensureMessageColumns error:", err);
    // Don't block request; still attempt to proceed.
  }
}

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

// GET all conversations for current user
router.get("/conversations", async (req, res) => {
  try {
    await ensureMessageColumns();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // Show all conversations (regular 1-on-1 + group chats)
    const query = `(
      -- Regular 1-on-1 conversations
      SELECT DISTINCT
        CASE 
          WHEN c.user1_id = $1 THEN c.user2_id
          ELSE c.user1_id
        END as participant_id,
        c.id as conversation_id,
        c.is_group,
        c.title as conversation_title,
        u.name as participant_name,
        u.username as participant_username,
        u.avatar as participant_avatar,
        m.text as last_message,
        m.created_at as last_message_time,
        COUNT(CASE WHEN m.is_read = false AND m.sender_id != $1 THEN 1 END) as unread_count
      FROM conversations c
      LEFT JOIN users u ON (
        (c.user1_id = $1 AND u.id = c.user2_id) OR
        (c.user2_id = $1 AND u.id = c.user1_id)
      )
      LEFT JOIN LATERAL (
        SELECT text, created_at, is_read, sender_id
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) m ON true
      WHERE (c.user1_id = $1 OR c.user2_id = $1) AND (c.is_group = false OR c.is_group IS NULL)
      GROUP BY c.id, participant_id, c.is_group, c.title, u.name, u.username, u.avatar, m.text, m.created_at
    )
    UNION ALL
    (
      -- Group chats
      SELECT DISTINCT
        NULL::integer as participant_id,
        c.id as conversation_id,
        c.is_group,
        c.title as conversation_title,
        NULL::text as participant_name,
        NULL::text as participant_username,
        NULL::text as participant_avatar,
        m.text as last_message,
        m.created_at as last_message_time,
        0 as unread_count
      FROM conversations c
      INNER JOIN group_members gm ON c.id = gm.conversation_id
      LEFT JOIN LATERAL (
        SELECT text, created_at, is_read, sender_id
        FROM messages
        WHERE conversation_id = c.id
        ORDER BY created_at DESC
        LIMIT 1
      ) m ON true
      WHERE gm.user_id = $1 AND c.is_group = true
      GROUP BY c.id, c.is_group, c.title, m.text, m.created_at
    )
    ORDER BY last_message_time DESC NULLS LAST`;
    const params = [userId];

    const result = await db.query(query, params);

    // Defensive authorization check:
    // Even though the SQL should already be scoped to the authenticated user, perform an additional
    // server-side verification to guarantee we only return conversations the user is a participant of.
    const convIds = result.rows.map(r => r.conversation_id);
    let authorizedIds = new Set();
    if (convIds.length > 0) {
    try {
        // Use text casting to avoid type mismatch between integer/uuid representations.
        const authCheck = await db.query(
          `SELECT id FROM conversations 
           WHERE id::text = ANY($1::text[]) 
             AND (
               user1_id::text = $2::text OR user2_id::text = $2::text
               OR id::text IN (SELECT conversation_id::text FROM group_members WHERE user_id::text = $2::text)
             )`,
          [convIds.map(String), String(userId)]
        );
        for (const row of authCheck.rows) {
          authorizedIds.add(String(row.id));
        }
      } catch (authErr) {
        console.error("Authorization double-check failed:", authErr);
        // If auth double-check fails, fall back to not returning any conversations to be safe.
        return res.status(500).json({ error: "Authorization verification failed" });
      }
    }

    const conversations = result.rows
      .filter(row => authorizedIds.size === 0 ? false : authorizedIds.has(String(row.conversation_id)))
      .map(row => ({
        id: row.conversation_id.toString(),
        isGroup: row.is_group === true,
        participantId: row.participant_id ? row.participant_id.toString() : null,
        participantName: row.participant_name || row.participant_username || (row.is_group ? row.conversation_title : "Unknown"),
        participantAvatar: row.participant_avatar || null,
        conversationTitle: row.conversation_title || null,
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

// GET messages for a conversation
router.get("/:conversationId", async (req, res) => {
  try {
    await ensureMessageColumns();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;
    const page = parseInt(req.query.page) || 1;
    const limit = 50;
    const offset = (page - 1) * limit;

    // Verify user is part of conversation
    // Handle both string and integer conversationId
    const convId = parseInt(conversationId) || conversationId;
    
    // Check if conversation exists and get its type
    const convCheck = await db.query(
      `SELECT id, is_group, user1_id, user2_id FROM conversations WHERE id = $1`,
      [convId]
    );

    if (convCheck.rows.length === 0) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    const conv = convCheck.rows[0];
    const isGroupChat = conv.is_group === true;

    // Verify user is part of conversation
    if (isGroupChat) {
      // Check group_members for group chats
      const memberCheck = await db.query(
        `SELECT id FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
        [convId, userId]
      );

      if (memberCheck.rows.length === 0) {
        return res.status(403).json({ error: "Not a member of this group chat" });
      }
    } else {
      // Check user1_id/user2_id for regular chats
      const participantCheck = await db.query(
        `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
        [convId, userId]
      );

      if (participantCheck.rows.length === 0) {
        return res.status(403).json({ error: "Not authorized for this conversation" });
      }
    }
    
    // Determine the other participant (for 1-on-1 chats only)
    const otherUserId = !isGroupChat && conv.user1_id ? (conv.user1_id === userId ? conv.user2_id : conv.user1_id) : null;

    // No role filter - show all messages
    const query = `SELECT * FROM messages 
       WHERE conversation_id = $1 
       ORDER BY created_at DESC 
       LIMIT $2 OFFSET $3`;
    const params = [convId, limit, offset];

    const result = await db.query(query, params);

    const messages = result.rows.map(row => {
      // For group chats, use the receiver_id from the message (or sender_id if not set)
      // For 1-on-1 chats, determine receiver based on sender
      let messageReceiverId;
      if (isGroupChat) {
        messageReceiverId = row.receiver_id || row.sender_id;
      } else {
        const messageSenderId = row.sender_id;
        messageReceiverId = messageSenderId === userId ? otherUserId : userId;
      }
      
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
    await ensureMessageColumns();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { conversationId, receiverId, text, messageType } = req.body;
    if (!text) return res.status(400).json({ error: "Message text required" });

    let convId = conversationId ? (parseInt(conversationId) || conversationId) : null;

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

    // Check if conversation exists and get its type
    // Try both integer and string versions to handle type mismatches
    let convCheck = await db.query(
      `SELECT id, is_group, user1_id, user2_id, created_by, title FROM conversations WHERE id = $1`,
      [convId]
    );

    // If not found, try as string
    if (convCheck.rows.length === 0 && typeof convId === 'string') {
      convCheck = await db.query(
        `SELECT id, is_group, user1_id, user2_id, created_by, title FROM conversations WHERE id = $1::integer`,
        [convId]
      );
    }

    // If still not found, try as integer
    if (convCheck.rows.length === 0 && typeof convId !== 'string') {
      convCheck = await db.query(
        `SELECT id, is_group, user1_id, user2_id, created_by, title FROM conversations WHERE id = $1`,
        [parseInt(convId)]
      );
    }

    if (convCheck.rows.length === 0) {
      console.error(`❌ Conversation not found: convId=${convId}, type=${typeof convId}, userId=${userId}`);
      // Try to see if conversation exists at all (debug)
      try {
        const debugCheck = await db.query(`SELECT id, is_group, created_by, title FROM conversations WHERE id = $1 OR CAST(id AS TEXT) = $2`, [convId, String(convId)]);
        console.error(`🔍 Debug check: Found ${debugCheck.rows.length} conversations matching id ${convId}`);
        if (debugCheck.rows.length > 0) {
          console.error(`🔍 Conversation details:`, debugCheck.rows[0]);
        }
      } catch (debugErr) {
        console.error(`🔍 Debug query error:`, debugErr.message);
      }
      return res.status(404).json({ error: "Conversation not found", details: `Conversation ID ${convId} not found` });
    }

    const conv = convCheck.rows[0];
    const isGroupChat = conv.is_group === true;

    let receiver;

    // Verify user is part of conversation
    if (isGroupChat) {
      // Check group_members for group chats
      const memberCheck = await db.query(
        `SELECT id FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
        [convId, userId]
      );

      if (memberCheck.rows.length === 0) {
        return res.status(403).json({ error: "Not a member of this group chat" });
      }

      // For group chats, use sender as receiver (messages are broadcast to all members via Socket.io)
      receiver = receiverId || userId;
    } else {
      // Check participant1_id/participant2_id for regular chats
      const participantCheck = await db.query(
        `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
        [convId, userId]
      );

      if (participantCheck.rows.length === 0) {
        return res.status(403).json({ error: "Not authorized for this conversation" });
      }

      // Determine receiver strictly from the conversation participants to avoid FK errors
      const participantA = conv.user1_id;
      const participantB = conv.user2_id;

      // The only valid receiver is the "other" participant in this 1:1 conversation
      const computedReceiver = String(participantA) === String(userId) ? participantB : participantA;

      // If caller provided a receiverId, ensure it matches the conversation participants
      if (receiverId && String(receiverId) !== String(computedReceiver)) {
        return res.status(400).json({ error: "receiverId does not match this conversation" });
      }

      receiver = computedReceiver;

      if (!receiver) {
        return res.status(400).json({ error: "Conversation participants not set correctly" });
      }
    }

    // Insert message
    const result = await db.query(
      `INSERT INTO messages (conversation_id, sender_id, receiver_id, text, message_type, is_read)
       VALUES ($1, $2, $3, $4, $5, false) RETURNING *`,
      [convId, userId, receiver, text, messageType || "text"]
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
    await ensureMessageColumns();

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
    await ensureMessageColumns();

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

// POST create group chat
router.post("/groups", async (req, res) => {
  try {
    await ensureMessageColumns();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { title, memberIds } = req.body;
    if (!title || !memberIds || !Array.isArray(memberIds) || memberIds.length === 0) {
      return res.status(400).json({ error: "Title and memberIds array required" });
    }

    // Create group conversation
    // Note: user1_id and user2_id should be NULL for group chats
    const convResult = await db.query(
      `INSERT INTO conversations (created_by, is_group, title, user1_id, user2_id) 
       VALUES ($1, true, $2, NULL, NULL) RETURNING *`,
      [userId, title]
    );

    const conversationId = convResult.rows[0].id;
    
    console.log(`✅ Group chat created: id=${conversationId}, title=${title}, created_by=${userId}`);

    // Add creator as admin
    await db.query(
      `INSERT INTO group_members (conversation_id, user_id, role) VALUES ($1, $2, 'admin')`,
      [conversationId, userId]
    );

    // Add other members
    const memberValues = memberIds.map((memberId, index) => 
      `($1, $${index + 2}, 'member')`
    ).join(', ');
    const memberParams = [conversationId, ...memberIds];

    await db.query(
      `INSERT INTO group_members (conversation_id, user_id, role) VALUES ${memberValues}`,
      memberParams
    );

    // Get all members for response
    const membersResult = await db.query(
      `SELECT u.id, u.name, u.username, u.avatar, gm.role
       FROM group_members gm
       JOIN users u ON gm.user_id = u.id
       WHERE gm.conversation_id = $1`,
      [conversationId]
    );

    res.json({
      id: conversationId.toString(),
      title: title,
      isGroup: true,
      members: membersResult.rows.map(row => ({
        id: row.id.toString(),
        name: row.name || row.username || "Unknown",
        username: row.username || "",
        avatar: row.avatar || null,
        role: row.role
      })),
      createdAt: convResult.rows[0].created_at ? new Date(convResult.rows[0].created_at).toISOString() : new Date().toISOString()
    });
  } catch (err) {
    console.error("Create group chat error:", err);
    res.status(500).json({ error: "Failed to create group chat" });
  }
});

// GET group chat members
router.get("/groups/:conversationId/members", async (req, res) => {
  try {
    await ensureMessageColumns();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;

    // Verify user is a member of the group
    const memberCheck = await db.query(
      `SELECT * FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    if (memberCheck.rows.length === 0) {
      return res.status(403).json({ error: "Not a member of this group" });
    }

    // Get all members
    const result = await db.query(
      `SELECT u.id, u.name, u.username, u.avatar, gm.role, gm.joined_at
       FROM group_members gm
       JOIN users u ON gm.user_id = u.id
       WHERE gm.conversation_id = $1
       ORDER BY gm.joined_at ASC`,
      [conversationId]
    );

    res.json({
      members: result.rows.map(row => ({
        id: row.id.toString(),
        name: row.name || row.username || "Unknown",
        username: row.username || "",
        avatar: row.avatar || null,
        role: row.role,
        joinedAt: row.joined_at ? new Date(row.joined_at).toISOString() : new Date().toISOString()
      }))
    });
  } catch (err) {
    console.error("Get group members error:", err);
    res.status(500).json({ error: "Failed to fetch group members" });
  }
});

// POST add members to group chat
router.post("/groups/:conversationId/members", async (req, res) => {
  try {
    await ensureMessageColumns();

    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;
    const { memberIds } = req.body;

    if (!memberIds || !Array.isArray(memberIds) || memberIds.length === 0) {
      return res.status(400).json({ error: "memberIds array required" });
    }

    // Verify user is admin or member of the group
    const memberCheck = await db.query(
      `SELECT role FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    if (memberCheck.rows.length === 0) {
      return res.status(403).json({ error: "Not a member of this group" });
    }

    // Add new members
    for (const memberId of memberIds) {
      await db.query(
        `INSERT INTO group_members (conversation_id, user_id, role) 
         VALUES ($1, $2, 'member')
         ON CONFLICT (conversation_id, user_id) DO NOTHING`,
        [conversationId, memberId]
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error("Add group members error:", err);
    res.status(500).json({ error: "Failed to add members" });
  }
});

// DELETE remove member from group chat
router.delete("/groups/:conversationId/members/:memberId", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const conversationId = req.params.conversationId;
    const memberId = req.params.memberId;

    // Verify user is admin or removing themselves
    const userCheck = await db.query(
      `SELECT role FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(403).json({ error: "Not a member of this group" });
    }

    const isAdmin = userCheck.rows[0].role === 'admin';
    const isRemovingSelf = userId.toString() === memberId;

    if (!isAdmin && !isRemovingSelf) {
      return res.status(403).json({ error: "Only admins can remove other members" });
    }

    // Remove member
    await db.query(
      `DELETE FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, memberId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Remove group member error:", err);
    res.status(500).json({ error: "Failed to remove member" });
  }
});

export default router;