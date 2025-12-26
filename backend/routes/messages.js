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
    
    const result = await query(
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
      WHERE (c.participant1_id = $1 OR c.participant2_id = $1)
        AND c.is_active = true
      ORDER BY c.last_message_time DESC
      LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    
    const countResult = await query(
      `SELECT COUNT(*) FROM conversations 
       WHERE (participant1_id = $1 OR participant2_id = $1) AND is_active = true`,
      [userId]
    );
    
    const conversations = result.rows.map(row => ({
      id: row.id,
      participantId: row.participant_id,
      participantName: row.participant_name,
      participantAvatar: row.participant_avatar,
      lastMessage: row.last_message || '',
      lastMessageTime: row.last_message_time,
      unreadCount: parseInt(row.unread_count) || 0,
      isActive: row.is_active,
    }));
    
    res.json({
      conversations,
      total: parseInt(countResult.rows[0].count),
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
    
    // Verify user is part of conversation
    const convResult = await query(
      'SELECT id FROM conversations WHERE id = $1 AND (participant1_id = $2 OR participant2_id = $2)',
      [conversationId, userId]
    );
    
    if (convResult.rows.length === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
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
  body('receiverId').notEmpty(),
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
    
    // Get or create conversation
    if (!finalConversationId) {
      // Check if conversation exists
      const existingConv = await query(
        `SELECT id FROM conversations 
         WHERE (participant1_id = $1 AND participant2_id = $2)
            OR (participant1_id = $2 AND participant2_id = $1)`,
        [senderId, receiverId]
      );
      
      if (existingConv.rows.length > 0) {
        finalConversationId = existingConv.rows[0].id;
      } else {
        // Create new conversation
        const newConv = await query(
          `INSERT INTO conversations (participant1_id, participant2_id, created_at, updated_at)
           VALUES ($1, $2, NOW(), NOW())
           RETURNING id`,
          [senderId, receiverId]
        );
        finalConversationId = newConv.rows[0].id;
      }
    }
    
    // Create message
    const messageResult = await query(
      `INSERT INTO messages (conversation_id, sender_id, receiver_id, text, message_type, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING id, conversation_id, sender_id, receiver_id, text, message_type, is_read, created_at`,
      [finalConversationId, senderId, receiverId, text, messageType]
    );
    
    const message = messageResult.rows[0];
    
    // Update conversation
    await query(
      `UPDATE conversations 
       SET last_message = $1, 
           last_message_time = NOW(),
           participant1_unread_count = CASE WHEN participant1_id = $2 THEN participant1_unread_count ELSE participant1_unread_count + 1 END,
           participant2_unread_count = CASE WHEN participant2_id = $2 THEN participant2_unread_count ELSE participant2_unread_count + 1 END,
           updated_at = NOW()
       WHERE id = $3`,
      [text, receiverId, finalConversationId]
    );
    
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
    
    const { userId } = req.body;
    const currentUserId = req.user.id;
    
    // Check if conversation exists
    const existingConv = await query(
      `SELECT id FROM conversations 
       WHERE (participant1_id = $1 AND participant2_id = $2)
          OR (participant1_id = $2 AND participant2_id = $1)`,
      [currentUserId, userId]
    );
    
    let conversationId;
    let conversation;
    
    if (existingConv.rows.length > 0) {
      conversationId = existingConv.rows[0].id;
    } else {
      // Create new conversation
      const newConv = await query(
        `INSERT INTO conversations (participant1_id, participant2_id, created_at, updated_at)
         VALUES ($1, $2, NOW(), NOW())
         RETURNING id`,
        [currentUserId, userId]
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

// POST /api/messages/:conversationId/read
router.post('/:conversationId/read', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;
    
    // Verify user is part of conversation
    const convResult = await query(
      'SELECT id, participant1_id, participant2_id FROM conversations WHERE id = $1',
      [conversationId]
    );
    
    if (convResult.rows.length === 0) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    const conversation = convResult.rows[0];
    
    if (conversation.participant1_id !== userId && conversation.participant2_id !== userId) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    
    // Mark messages as read
    await query(
      `UPDATE messages 
       SET is_read = true 
       WHERE conversation_id = $1 AND receiver_id = $2 AND is_read = false`,
      [conversationId, userId]
    );
    
    // Reset unread count
    await query(
      `UPDATE conversations 
       SET participant1_unread_count = CASE WHEN participant1_id = $1 THEN 0 ELSE participant1_unread_count END,
           participant2_unread_count = CASE WHEN participant2_id = $1 THEN 0 ELSE participant2_unread_count END
       WHERE id = $2`,
      [userId, conversationId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;



