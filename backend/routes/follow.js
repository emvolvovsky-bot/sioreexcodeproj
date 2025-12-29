const express = require('express');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// POST /api/follow/:userId - Follow a user
router.post('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const followerId = req.user.id;

    // Prevent self-following
    if (parseInt(userId) === followerId) {
      return res.status(400).json({ error: 'Cannot follow yourself' });
    }

    // Check if user exists
    const userResult = await query('SELECT id FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Insert follow relationship (ON CONFLICT DO NOTHING prevents duplicates)
    const followResult = await query(
      `INSERT INTO follows (follower_id, following_id)
       VALUES ($1, $2)
       ON CONFLICT (follower_id, following_id) DO NOTHING
       RETURNING id`,
      [followerId, userId]
    );

    const wasInserted = followResult.rows.length > 0;

    // Get updated counts
    const countsResult = await query(
      `SELECT
        (SELECT COUNT(*) FROM follows WHERE following_id = $1) as follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = $1) as following_count,
        (SELECT COUNT(*) FROM follows WHERE following_id = $2) as target_follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = $2) as target_following_count`,
      [userId, followerId]
    );

    const counts = countsResult.rows[0];

    res.json({
      following: true,
      followerCount: parseInt(counts.target_follower_count),
      followingCount: parseInt(counts.target_following_count),
      targetFollowerCount: parseInt(counts.follower_count),
      targetFollowingCount: parseInt(counts.following_count),
      wasInserted
    });
  } catch (error) {
    console.error('Follow user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/follow/:userId - Unfollow a user
router.delete('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const followerId = req.user.id;

    // Delete follow relationship
    const deleteResult = await query(
      'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2',
      [followerId, userId]
    );

    // Get updated counts
    const countsResult = await query(
      `SELECT
        (SELECT COUNT(*) FROM follows WHERE following_id = $1) as follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = $1) as following_count,
        (SELECT COUNT(*) FROM follows WHERE following_id = $2) as target_follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = $2) as target_following_count`,
      [userId, followerId]
    );

    const counts = countsResult.rows[0];

    res.json({
      following: false,
      followerCount: parseInt(counts.target_follower_count),
      followingCount: parseInt(counts.target_following_count),
      targetFollowerCount: parseInt(counts.follower_count),
      targetFollowingCount: parseInt(counts.following_count)
    });
  } catch (error) {
    console.error('Unfollow user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/following - Get users I follow
router.get('/following', async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT u.id, u.username, u.name, u.bio, u.avatar, u.user_type, u.location,
              u.verified, u.follower_count, u.following_count, u.event_count, u.created_at
       FROM follows f
       JOIN users u ON f.following_id = u.id
       WHERE f.follower_id = $1
       ORDER BY f.created_at DESC`,
      [userId]
    );

    const users = result.rows.map(row => ({
      id: row.id.toString(),
      username: row.username,
      name: row.name,
      bio: row.bio,
      avatar: row.avatar,
      userType: row.user_type,
      location: row.location,
      verified: row.verified,
      followerCount: parseInt(row.follower_count) || 0,
      followingCount: parseInt(row.following_count) || 0,
      eventCount: parseInt(row.event_count) || 0,
      createdAt: row.created_at
    }));

    res.json({ users });
  } catch (error) {
    console.error('Get following error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/followers/:userId - Get followers of a user
router.get('/followers/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.id;

    const result = await query(
      `SELECT u.id, u.username, u.name, u.bio, u.avatar, u.user_type, u.location,
              u.verified, u.follower_count, u.following_count, u.event_count, u.created_at,
              EXISTS(SELECT 1 FROM follows WHERE follower_id = $2 AND following_id = u.id) as is_following_back
       FROM follows f
       JOIN users u ON f.follower_id = u.id
       WHERE f.following_id = $1
       ORDER BY f.created_at DESC`,
      [userId, currentUserId]
    );

    const users = result.rows.map(row => ({
      id: row.id.toString(),
      username: row.username,
      name: row.name,
      bio: row.bio,
      avatar: row.avatar,
      userType: row.user_type,
      location: row.location,
      verified: row.verified,
      followerCount: parseInt(row.follower_count) || 0,
      followingCount: parseInt(row.following_count) || 0,
      eventCount: parseInt(row.event_count) || 0,
      createdAt: row.created_at,
      isFollowingBack: row.is_following_back
    }));

    res.json({ users });
  } catch (error) {
    console.error('Get followers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/following-list/:userId - Get users a user follows (legacy endpoint)
router.get('/following-list/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.id;

    const result = await query(
      `SELECT u.id, u.username, u.name, u.bio, u.avatar, u.user_type, u.location,
              u.verified, u.follower_count, u.following_count, u.event_count, u.created_at,
              EXISTS(SELECT 1 FROM follows WHERE follower_id = $2 AND following_id = u.id) as is_following_back
       FROM follows f
       JOIN users u ON f.following_id = u.id
       WHERE f.follower_id = $1
       ORDER BY f.created_at DESC`,
      [userId, currentUserId]
    );

    const users = result.rows.map(row => ({
      id: row.id.toString(),
      username: row.username,
      name: row.name,
      bio: row.bio,
      avatar: row.avatar,
      userType: row.user_type,
      location: row.location,
      verified: row.verified,
      followerCount: parseInt(row.follower_count) || 0,
      followingCount: parseInt(row.following_count) || 0,
      eventCount: parseInt(row.event_count) || 0,
      createdAt: row.created_at,
      isFollowingBack: row.is_following_back
    }));

    res.json({ users });
  } catch (error) {
    console.error('Get following list error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/follow/status/:userId - Check if current user follows target user
router.get('/status/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.id;

    const result = await query(
      'SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2) as following',
      [currentUserId, userId]
    );

    res.json({
      following: result.rows[0].following,
      userId: userId
    });
  } catch (error) {
    console.error('Check follow status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/following - Get following IDs (for compatibility)
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT following_id FROM follows WHERE follower_id = $1 ORDER BY created_at DESC',
      [userId]
    );

    const followingIds = result.rows.map(row => row.following_id.toString());

    res.json({ followingIds });
  } catch (error) {
    console.error('Get following IDs error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
