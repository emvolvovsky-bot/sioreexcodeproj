const express = require('express');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// GET /api/posts - Get feed posts
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    const postsResult = await query(
      `SELECT
        p.*,
        u.username,
        u.name,
        u.avatar,
        u.verified,
        e.title as event_title,
        e.location as event_location,
        e.event_date as event_date
       FROM posts p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN events e ON p.event_id = e.id
       ORDER BY p.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    const posts = postsResult.rows.map(row => ({
      id: row.id.toString(),
      userId: row.user_id.toString(),
      userName: row.name,
      userAvatar: row.avatar,
      images: row.images || [],
      caption: row.caption,
      location: row.location,
      eventId: row.event_id?.toString(),
      eventTitle: row.event_title,
      eventLocation: row.event_location,
      eventDate: row.event_date,
      likes: row.likes,
      comments: row.comments,
      createdAt: row.created_at
    }));

    res.json({ posts });
  } catch (error) {
    console.error('Get posts error:', error);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

// GET /api/posts/event/:eventId - Get posts for a specific event
router.get('/event/:eventId', async (req, res) => {
  try {
    const { eventId } = req.params;
    console.log('🔍 Fetching posts for event:', eventId);

    const postsResult = await query(
      `SELECT
        p.*,
        u.username,
        u.name,
        u.avatar,
        u.verified
       FROM posts p
       JOIN users u ON p.user_id = u.id
       WHERE p.event_id = $1
       ORDER BY p.created_at DESC`,
      [eventId]
    );

    const posts = postsResult.rows.map(row => ({
      id: row.id.toString(),
      userId: row.user_id.toString(),
      userName: row.name,
      userAvatar: row.avatar,
      images: row.images || [],
      caption: row.caption,
      location: row.location,
      eventId: row.event_id?.toString(),
      likes: row.likes,
      comments: row.comments,
      createdAt: row.created_at
    }));

    res.json({ posts });
  } catch (error) {
    console.error('Get event posts error:', error);
    res.status(500).json({ error: 'Failed to fetch event posts' });
  }
});

// POST /api/posts - Create a new post
router.post('/', async (req, res) => {
  try {
    console.log('📝 Creating post for user:', req.user.id);
    const { caption, images, location, eventId } = req.body;
    console.log('📝 Post data:', { caption, images: images?.length, location, eventId });
    const userId = req.user.id;

    const result = await query(
      `INSERT INTO posts (user_id, images, caption, location, event_id, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
       RETURNING id, created_at`,
      [userId, images || [], caption, location, eventId]
    );

    const post = result.rows[0];

    // Update user's event count if this post is attached to an event
    if (eventId) {
      await query(
        `UPDATE users SET event_count = event_count + 1 WHERE id = $1`,
        [userId]
      );
    }

    res.json({
      id: post.id.toString(),
      createdAt: post.created_at
    });
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// DELETE /api/posts/:postId - Delete a post
router.delete('/:postId', async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.id;

    // First check if the post belongs to the user
    const postResult = await query(
      'SELECT id, event_id FROM posts WHERE id = $1 AND user_id = $2',
      [postId, userId]
    );

    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const post = postResult.rows[0];

    // Delete the post
    await query('DELETE FROM posts WHERE id = $1', [postId]);

    // Update user's event count if this post was attached to an event
    if (post.event_id) {
      await query(
        `UPDATE users SET event_count = GREATEST(event_count - 1, 0) WHERE id = $1`,
        [userId]
      );
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete post error:', error);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});

// POST /api/posts/:postId/like - Like/unlike a post
router.post('/:postId/like', async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.id;

    // Check if user already liked this post (simplified - in production you'd have a likes table)
    // For now, just toggle the like count
    const postResult = await query(
      'SELECT likes FROM posts WHERE id = $1',
      [postId]
    );

    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const currentLikes = postResult.rows[0].likes;
    // This is a simplified implementation - in production you'd track individual likes
    const newLikes = currentLikes > 0 ? currentLikes - 1 : currentLikes + 1;

    await query(
      'UPDATE posts SET likes = $1 WHERE id = $2',
      [newLikes, postId]
    );

    res.json({ liked: newLikes > currentLikes });
  } catch (error) {
    console.error('Like post error:', error);
    res.status(500).json({ error: 'Failed to like post' });
  }
});

module.exports = router;
