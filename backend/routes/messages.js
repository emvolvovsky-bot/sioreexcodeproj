const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// GET /api/messages/conversations
router.get('/conversations', async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    
    // Get both regular conversations and group chats
    const result = await query(
      `(
        -- Regular 1-on-1 conversations
        SELECT
          c.id,
          c.is_group,
          c.title as conversation_title,
          CASE
            WHEN c.participant1_id = $1 THEN c.participant2_id
            ELSE c.participant1_id
          END as participant_id,
          u.name as participant_name,
          u.avatar_url as participant_avatar,
          c.last_message,
          c.last_message_time,
          CASE
            WHEN c.participant1_id = $1 THEN c.participant1_unread_count
            ELSE c.participant2_unread_count
          END as unread_count,
          c.is_active,
          c.event_id,
          c.booking_id,
          e.title as event_title,
          e.date as event_date
        FROM conversations c
        JOIN users u ON (
          (c.participant1_id = $1 AND u.id = c.participant2_id) OR
          (c.participant2_id = $1 AND u.id = c.participant1_id)
        )
        LEFT JOIN events e ON c.event_id = e.id
        WHERE (c.participant1_id = $1 OR c.participant2_id = $1)
          AND c.is_active = true
          AND c.is_group = false
      )
      UNION ALL
      (
        -- Group chats
        SELECT
          c.id,
          c.is_group,
          c.title as conversation_title,
          NULL::uuid as participant_id,
          NULL::text as participant_name,
          NULL::text as participant_avatar,
          c.last_message,
          c.last_message_time,
          0 as unread_count, -- Group chats don't have per-participant unread counts yet
          c.is_active,
          c.event_id,
          c.booking_id,
          e.title as event_title,
          e.date as event_date
        FROM conversations c
        LEFT JOIN events e ON c.event_id = e.id
        INNER JOIN group_members gm ON c.id = gm.conversation_id
        WHERE gm.user_id = $1
          AND c.is_active = true
          AND c.is_group = true
      )
      ORDER BY last_message_time DESC NULLS LAST
      LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    
    // Count total conversations (regular + group)
    const countResult = await query(
      `SELECT COUNT(*) as total FROM (
        SELECT c.id
        FROM conversations c
        WHERE (c.participant1_id = $1 OR c.participant2_id = $1)
          AND c.is_active = true
          AND c.is_group = false
        UNION
        SELECT c.id
        FROM conversations c
        INNER JOIN group_members gm ON c.id = gm.conversation_id
        WHERE gm.user_id = $1
          AND c.is_active = true
          AND c.is_group = true
      ) combined`,
      [userId]
    );
    
    const conversations = result.rows.map(row => ({
      id: row.id,
      isGroup: row.is_group,
      participantId: row.participant_id ? row.participant_id.toString() : null,
      participantName: row.participant_name,
      participantAvatar: row.participant_avatar,
      lastMessage: row.last_message || '',
      lastMessageTime: row.last_message_time,
      unreadCount: parseInt(row.unread_count) || 0,
      isActive: row.is_active,
      eventId: row.event_id,
      bookingId: row.booking_id,
      conversationTitle: row.conversation_title,
      eventTitle: row.event_title,
      eventDate: row.event_date,
    }));
    
    res.json({
      conversations,
      total: parseInt(countResult.rows[0].total),
      page,
      limit,
    });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/messages/:conversationId
router.get('/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;
    
    // Check if conversation exists and get its type
    const convResult = await query(
      'SELECT id, is_group FROM conversations WHERE id = $1',
      [conversationId]
    );
    
    if (convResult.rows.length === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    const conversation = convResult.rows[0];
    const isGroupChat = conversation.is_group;
    
    // Verify user is part of conversation
    if (isGroupChat) {
      // Check group_members for group chats
      const memberCheck = await query(
        'SELECT id FROM group_members WHERE conversation_id = $1 AND user_id = $2',
        [conversationId, userId]
      );
      
      if (memberCheck.rows.length === 0) {
        return res.status(403).json({ error: 'Not a member of this group chat' });
      }
    } else {
      // Check participant1_id/participant2_id for regular chats
      const participantCheck = await query(
        'SELECT id FROM conversations WHERE id = $1 AND (participant1_id = $2 OR participant2_id = $2)',
        [conversationId, userId]
      );
      
      if (participantCheck.rows.length === 0) {
        return res.status(403).json({ error: 'Not authorized for this conversation' });
      }
    }
    
    const result = await query(
      `SELECT id, conversation_id, sender_id, receiver_id, text, message_type, is_read, created_at
       FROM messages
       WHERE conversation_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [conversationId, limit, offset]
    );
    
    const messages = result.rows.map(row => ({
      id: row.id,
      conversationId: row.conversation_id,
      senderId: row.sender_id,
      receiverId: row.receiver_id,
      text: row.text,
      timestamp: row.created_at,
      isRead: row.is_read,
      messageType: row.message_type,
    }));
    
    res.json({
      messages: messages.reverse(), // Oldest first
      hasMore: messages.length === limit,
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/messages
router.post('/', [
  body('text').trim().notEmpty(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { conversationId, receiverId, text, messageType = 'text' } = req.body;
    const senderId = req.user.id;
    
    let finalConversationId = conversationId;
    let isGroupChat = false;
    
    // If conversationId is provided, verify it exists and user has access
    if (finalConversationId) {
      const convCheck = await query(
        `SELECT id, is_group FROM conversations WHERE id = $1`,
        [finalConversationId]
      );
      
      if (convCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Conversation not found' });
      }
      
      isGroupChat = convCheck.rows[0].is_group;
      
      // Verify user is part of the conversation
      if (isGroupChat) {
        // Check group_members for group chats
        const memberCheck = await query(
          `SELECT id FROM group_members WHERE conversation_id = $1 AND user_id = $2`,
          [finalConversationId, senderId]
        );
        
        if (memberCheck.rows.length === 0) {
          return res.status(403).json({ error: 'Not a member of this group chat' });
        }
      } else {
        // Check participant1_id/participant2_id for regular chats
        const participantCheck = await query(
          `SELECT id FROM conversations WHERE id = $1 AND (participant1_id = $2 OR participant2_id = $2)`,
          [finalConversationId, senderId]
        );
        
        if (participantCheck.rows.length === 0) {
          return res.status(403).json({ error: 'Not authorized for this conversation' });
        }
      }
    } else {
      // No conversationId provided - create or find a 1-on-1 conversation
      if (!receiverId) {
        return res.status(400).json({ error: 'Either conversationId or receiverId is required' });
      }
      
      // Check if conversation exists
      const existingConv = await query(
        `SELECT id FROM conversations 
         WHERE is_group = false
           AND ((participant1_id = $1 AND participant2_id = $2)
            OR (participant1_id = $2 AND participant2_id = $1))`,
        [senderId, receiverId]
      );
      
      if (existingConv.rows.length > 0) {
        finalConversationId = existingConv.rows[0].id;
      } else {
        // Create new conversation
        const newConv = await query(
          `INSERT INTO conversations (participant1_id, participant2_id, is_group, created_at, updated_at, is_active)
           VALUES ($1, $2, false, NOW(), NOW(), true)
           RETURNING id`,
          [senderId, receiverId]
        );
        finalConversationId = newConv.rows[0].id;
      }
    }
    
    // For group chats, receiverId is not required, use senderId as placeholder
    // For regular chats, use the actual receiverId
    const finalReceiverId = isGroupChat ? senderId : (receiverId || senderId);
    
    // Create message
    const messageResult = await query(
      `INSERT INTO messages (conversation_id, sender_id, receiver_id, text, message_type, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING id, conversation_id, sender_id, receiver_id, text, message_type, is_read, created_at`,
      [finalConversationId, senderId, finalReceiverId, text, messageType]
    );
    
    const message = messageResult.rows[0];
    
    // Update conversation last message
    if (isGroupChat) {
      // For group chats, just update last_message and last_message_time
      await query(
        `UPDATE conversations 
         SET last_message = $1, 
             last_message_time = NOW(),
             updated_at = NOW()
         WHERE id = $2`,
        [text, finalConversationId]
      );
    } else {
      // For regular chats, update unread counts
      await query(
        `UPDATE conversations 
         SET last_message = $1, 
             last_message_time = NOW(),
             participant1_unread_count = CASE 
               WHEN participant1_id = $2 THEN participant1_unread_count 
               ELSE participant1_unread_count + 1 
             END,
             participant2_unread_count = CASE 
               WHEN participant2_id = $2 THEN participant2_unread_count 
               ELSE participant2_unread_count + 1 
             END,
             updated_at = NOW()
         WHERE id = $3`,
        [text, finalReceiverId, finalConversationId]
      );
    }
    
    res.status(201).json({
      id: message.id,
      conversationId: message.conversation_id,
      senderId: message.sender_id,
      receiverId: message.receiver_id,
      text: message.text,
      timestamp: message.created_at,
      isRead: message.is_read,
      messageType: message.message_type,
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/messages/conversation
router.post('/conversation', [
  body('userId').notEmpty(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId, eventId, bookingId } = req.body;
    const currentUserId = req.user.id;

    // If bookingId is provided, check if conversation already exists for this booking
    let existingConv;
    if (bookingId) {
      existingConv = await query(
        `SELECT id FROM conversations WHERE booking_id = $1`,
        [bookingId]
      );
    } else {
      // Check if conversation exists between these users
      existingConv = await query(
        `SELECT id FROM conversations
         WHERE (participant1_id = $1 AND participant2_id = $2)
            OR (participant1_id = $2 AND participant2_id = $1)`,
        [currentUserId, userId]
      );
    }

    let conversationId;
    let conversation;

    if (existingConv.rows.length > 0) {
      conversationId = existingConv.rows[0].id;

      // Update conversation with event/booking info if not already set
      if (eventId || bookingId) {
        await query(
          `UPDATE conversations
           SET event_id = COALESCE(event_id, $2), booking_id = COALESCE(booking_id, $3)
           WHERE id = $1`,
          [conversationId, eventId, bookingId]
        );
      }
    } else {
      // Create new conversation with event/booking context
      let title = null;
      if (bookingId) {
        // Get event title for conversation title
        const bookingResult = await query(
          `SELECT e.title as event_title
           FROM bookings b
           JOIN events e ON b.event_id = e.id
           WHERE b.id = $1`,
          [bookingId]
        );
        if (bookingResult.rows.length > 0) {
          title = bookingResult.rows[0].event_title;
        }
      }

      const newConv = await query(
        `INSERT INTO conversations (participant1_id, participant2_id, event_id, booking_id, title, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
         RETURNING id`,
        [currentUserId, userId, eventId, bookingId, title]
      );
      conversationId = newConv.rows[0].id;
    }
    
    // Get conversation with participant info
    const convResult = await query(
      `SELECT 
        c.id,
        CASE 
          WHEN c.participant1_id = $1 THEN c.participant2_id
          ELSE c.participant1_id
        END as participant_id,
        u.name as participant_name,
        u.avatar_url as participant_avatar,
        c.last_message,
        c.last_message_time,
        CASE 
          WHEN c.participant1_id = $1 THEN c.participant1_unread_count
          ELSE c.participant2_unread_count
        END as unread_count,
        c.is_active
      FROM conversations c
      JOIN users u ON (
        (c.participant1_id = $1 AND u.id = c.participant2_id) OR
        (c.participant2_id = $1 AND u.id = c.participant1_id)
      )
      WHERE c.id = $2`,
      [currentUserId, conversationId]
    );
    
    conversation = convResult.rows[0];
    
    res.json({
      id: conversation.id,
      participantId: conversation.participant_id,
      participantName: conversation.participant_name,
      participantAvatar: conversation.participant_avatar,
      lastMessage: conversation.last_message || '',
      lastMessageTime: conversation.last_message_time,
      unreadCount: parseInt(conversation.unread_count) || 0,
      isActive: conversation.is_active,
    });
  } catch (error) {
    console.error('Get/create conversation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/messages/groups - Create a group chat
router.post('/groups', [
  body('title').trim().notEmpty(),
  body('memberIds').isArray().notEmpty(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { title, memberIds } = req.body;
    const userId = req.user.id;

    // Validate memberIds array
    if (!Array.isArray(memberIds) || memberIds.length === 0) {
      return res.status(400).json({ error: 'memberIds must be a non-empty array' });
    }

    // Verify all member IDs exist
    const memberIdsWithCreator = [...new Set([userId, ...memberIds])];
    const usersResult = await query(
      `SELECT id FROM users WHERE id = ANY($1::uuid[])`,
      [memberIdsWithCreator]
    );

    if (usersResult.rows.length !== memberIdsWithCreator.length) {
      return res.status(400).json({ error: 'One or more member IDs are invalid' });
    }

    // Create group conversation
    const convResult = await query(
      `INSERT INTO conversations (created_by, is_group, title, created_at, updated_at, is_active) 
       VALUES ($1, true, $2, NOW(), NOW(), true) RETURNING *`,
      [userId, title]
    );

    const conversationId = convResult.rows[0].id;

    // Add creator as admin
    await query(
      `INSERT INTO group_members (conversation_id, user_id, role) VALUES ($1, $2, 'admin')`,
      [conversationId, userId]
    );

    // Add other members
    const memberIdsToAdd = memberIds.filter(id => id !== userId);
    if (memberIdsToAdd.length > 0) {
      const memberValues = memberIdsToAdd.map((_, index) => 
        `($1, $${index + 2}::uuid, 'member')`
      ).join(', ');
      const memberParams = [conversationId, ...memberIdsToAdd];

      await query(
        `INSERT INTO group_members (conversation_id, user_id, role) VALUES ${memberValues}`,
        memberParams
      );
    }

    // Get all members for response
    const membersResult = await query(
      `SELECT u.id, u.name, u.avatar_url as avatar, gm.role
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
        name: row.name || "Unknown",
        username: "",
        avatar: row.avatar || null,
        role: row.role
      })),
      createdAt: convResult.rows[0].created_at ? new Date(convResult.rows[0].created_at).toISOString() : new Date().toISOString()
    });
  } catch (error) {
    console.error('Create group chat error:', error);
    res.status(500).json({ error: 'Failed to create group chat' });
  }
});

// POST /api/messages/:conversationId/read
router.post('/:conversationId/read', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;
    
    // Verify user is part of conversation
    const convResult = await query(
      'SELECT id, participant1_id, participant2_id, is_group FROM conversations WHERE id = $1',
      [conversationId]
    );
    
    if (convResult.rows.length === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    const conversation = convResult.rows[0];
    const isGroupChat = conversation.is_group;
    
    // Verify user has access
    if (isGroupChat) {
      const memberCheck = await query(
        'SELECT id FROM group_members WHERE conversation_id = $1 AND user_id = $2',
        [conversationId, userId]
      );
      
      if (memberCheck.rows.length === 0) {
        return res.status(403).json({ error: 'Not a member of this group chat' });
      }
    } else {
      if (conversation.participant1_id !== userId && conversation.participant2_id !== userId) {
        return res.status(403).json({ error: 'Not authorized' });
      }
    }
    
    // Mark messages as read
    await query(
      `UPDATE messages 
       SET is_read = true 
       WHERE conversation_id = $1 AND receiver_id = $2 AND is_read = false`,
      [conversationId, userId]
    );
    
    // Reset unread count (only for regular chats)
    if (!isGroupChat) {
      await query(
        `UPDATE conversations 
         SET participant1_unread_count = CASE WHEN participant1_id = $1 THEN 0 ELSE participant1_unread_count END,
             participant2_unread_count = CASE WHEN participant2_id = $1 THEN 0 ELSE participant2_unread_count END
         WHERE id = $2`,
        [userId, conversationId]
      );
    }
    
    res.json({ success: true });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;



