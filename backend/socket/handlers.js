const { query } = require('../config/database');

function initializeSocketHandlers(io, socket) {
  const userId = socket.userId;
  
  // Join user's personal room
  socket.join(`user:${userId}`);
  
  // Handle sending messages
  socket.on('send_message', async (data) => {
    try {
      const { conversationId, receiverId, text, messageType = 'text' } = data;
      
      // Create message in database
      const messageResult = await query(
        `INSERT INTO messages (conversation_id, sender_id, receiver_id, text, message_type, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING id, conversation_id, sender_id, receiver_id, text, message_type, is_read, created_at`,
        [conversationId, userId, receiverId, text, messageType]
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
        [text, receiverId, conversationId]
      );
      
      // Emit to receiver
      io.to(`user:${receiverId}`).emit('new_message', {
        id: message.id,
        conversationId: message.conversation_id,
        senderId: message.sender_id,
        receiverId: message.receiver_id,
        text: message.text,
        timestamp: message.created_at,
        isRead: message.is_read,
        messageType: message.message_type,
      });
      
      // Confirm to sender
      socket.emit('message_sent', {
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
      console.error('Socket send_message error:', error);
      socket.emit('message_error', { error: 'Failed to send message' });
    }
  });
  
  // Handle typing indicator
  socket.on('typing', (data) => {
    const { receiverId, isTyping } = data;
    socket.to(`user:${receiverId}`).emit('user_typing', {
      userId: userId,
      isTyping: isTyping,
    });
  });
  
  // Handle read receipts
  socket.on('mark_read', async (data) => {
    try {
      const { conversationId } = data;
      
      await query(
        `UPDATE messages 
         SET is_read = true 
         WHERE conversation_id = $1 AND receiver_id = $2 AND is_read = false`,
        [conversationId, userId]
      );
      
      await query(
        `UPDATE conversations 
         SET participant1_unread_count = CASE WHEN participant1_id = $1 THEN 0 ELSE participant1_unread_count END,
             participant2_unread_count = CASE WHEN participant2_id = $1 THEN 0 ELSE participant2_unread_count END
         WHERE id = $2`,
        [userId, conversationId]
      );
    } catch (error) {
      console.error('Socket mark_read error:', error);
    }
  });
  
  // Handle disconnect
  socket.on('disconnect', () => {
    console.log(`User ${userId} disconnected`);
  });
}

module.exports = { initializeSocketHandlers };



