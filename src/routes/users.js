import express from "express";
import db from "../db/database.js";
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

// GET search users - MUST be before /:id route to avoid route conflict
router.get("/search", async (req, res) => {
  try {
    const query = req.query.q || "";
    const currentUserId = getUserIdFromToken(req);
    
    // If query is empty or "*", return all users (for inbox "all users" feature)
    const returnAllUsers = !query || query === "" || query === "*";
    
    // Build query - handle null currentUserId properly
    let result;
    if (returnAllUsers) {
      // Return all users (excluding current user if logged in)
      if (currentUserId) {
        result = await db.query(
          `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
                  follower_count, following_count, event_count, created_at
           FROM users 
           WHERE id != $1
           ORDER BY username
           LIMIT 100`,
          [currentUserId]
        );
      } else {
        result = await db.query(
          `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
                  follower_count, following_count, event_count, created_at
           FROM users 
           ORDER BY username
           LIMIT 100`
        );
      }
    } else if (query.length < 2) {
      return res.json({ users: [] });
    } else {
      // Search by username or name (case-insensitive, partial match)
      const searchPattern = `%${query}%`;
      
      if (currentUserId) {
        result = await db.query(
          `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
                  follower_count, following_count, event_count, created_at
           FROM users 
           WHERE (LOWER(username) LIKE LOWER($1) OR LOWER(name) LIKE LOWER($1))
             AND id != $2
           ORDER BY 
             CASE 
               WHEN LOWER(username) = LOWER($3) THEN 1
               WHEN LOWER(username) LIKE LOWER($4) THEN 2
               WHEN LOWER(name) LIKE LOWER($4) THEN 3
               ELSE 4
             END,
             username
           LIMIT 20`,
          [searchPattern, currentUserId, query, `%${query}%`]
        );
      } else {
        result = await db.query(
          `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
                  follower_count, following_count, event_count, created_at
           FROM users 
           WHERE (LOWER(username) LIKE LOWER($1) OR LOWER(name) LIKE LOWER($1))
           ORDER BY 
             CASE 
               WHEN LOWER(username) = LOWER($2) THEN 1
               WHEN LOWER(username) LIKE LOWER($3) THEN 2
               WHEN LOWER(name) LIKE LOWER($3) THEN 3
               ELSE 4
             END,
             username
           LIMIT 20`,
          [searchPattern, query, `%${query}%`]
        );
      }
    }
    
    const users = result.rows.map(row => ({
      id: row.id.toString(),
      email: row.email,
      username: row.username,
      name: row.name || row.username,
      userType: row.user_type || "partier",
      bio: row.bio || null,
      avatar: row.avatar || null,
      location: row.location || null,
      verified: row.verified || false,
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
      followerCount: row.follower_count || 0,
      followingCount: row.following_count || 0,
      eventCount: row.event_count || 0,
      badges: []
    }));
    
    res.json({ users });
  } catch (err) {
    console.error("Search users error:", err);
    res.status(500).json({ error: "Failed to search users" });
  }
});

// GET user profile
router.get("/:id", async (req, res) => {
  try {
    const userId = req.params.id;
    const result = await db.query(
      `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
              follower_count, following_count, event_count, created_at
       FROM users WHERE id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const userRow = result.rows[0];
    const user = {
      id: userRow.id.toString(),
      email: userRow.email,
      username: userRow.username,
      name: userRow.name || userRow.username,
      userType: userRow.user_type || "partier",
      bio: userRow.bio || null,
      avatar: userRow.avatar || null,
      location: userRow.location || null,
      verified: userRow.verified || false,
      createdAt: userRow.created_at ? new Date(userRow.created_at).toISOString() : new Date().toISOString(),
      followerCount: userRow.follower_count || 0,
      followingCount: userRow.following_count || 0,
      eventCount: userRow.event_count || 0,
      badges: []
    };

    res.json(user);
  } catch (err) {
    console.error("Get user profile error:", err);
    res.status(500).json({ error: "Failed to fetch user profile" });
  }
});

// POST follow/unfollow user
router.post("/:id/follow", async (req, res) => {
  try {
    const followerId = getUserIdFromToken(req);
    if (!followerId) return res.status(401).json({ error: "Unauthorized" });

    const followingId = req.params.id;
    if (followerId.toString() === followingId) {
      return res.status(400).json({ error: "Cannot follow yourself" });
    }

    // Check if already following
    const checkResult = await db.query(
      `SELECT * FROM follows WHERE follower_id = $1 AND following_id = $2`,
      [followerId, followingId]
    );

    if (checkResult.rows.length > 0) {
      // Unfollow
      await db.query(
        `DELETE FROM follows WHERE follower_id = $1 AND following_id = $2`,
        [followerId, followingId]
      );
      
      // Update counts
      await db.query(
        `UPDATE users SET follower_count = GREATEST(0, follower_count - 1) WHERE id = $1`,
        [followingId]
      );
      await db.query(
        `UPDATE users SET following_count = GREATEST(0, following_count - 1) WHERE id = $1`,
        [followerId]
      );

      res.json({ following: false });
    } else {
      // Follow
      await db.query(
        `INSERT INTO follows (follower_id, following_id) VALUES ($1, $2)`,
        [followerId, followingId]
      );
      
      // Update counts
      await db.query(
        `UPDATE users SET follower_count = follower_count + 1 WHERE id = $1`,
        [followingId]
      );
      await db.query(
        `UPDATE users SET following_count = following_count + 1 WHERE id = $1`,
        [followerId]
      );

      res.json({ following: true });
    }
  } catch (err) {
    console.error("Follow/unfollow error:", err);
    res.status(500).json({ error: "Failed to follow/unfollow user" });
  }
});

// GET check if following
router.get("/:id/following", async (req, res) => {
  try {
    const followerId = getUserIdFromToken(req);
    if (!followerId) return res.status(401).json({ error: "Unauthorized" });

    const followingId = req.params.id;
    const result = await db.query(
      `SELECT * FROM follows WHERE follower_id = $1 AND following_id = $2`,
      [followerId, followingId]
    );

    res.json({ following: result.rows.length > 0 });
  } catch (err) {
    console.error("Check following error:", err);
    res.status(500).json({ error: "Failed to check follow status" });
  }
});

// GET user attended events (events user RSVPed to)
router.get("/:id/attended", async (req, res) => {
  try {
    const userId = req.params.id;
    const result = await db.query(
      `SELECT DISTINCT
        e.*,
        u.username as host_username,
        u.name as host_name,
        u.avatar as host_avatar,
        u.user_type as host_user_type,
        COALESCE(el.likes_count, 0) as likes,
        CASE WHEN ela.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        CASE WHEN esa.user_id IS NOT NULL THEN true ELSE false END as is_saved
      FROM event_attendees ea
      INNER JOIN events e ON ea.event_id = e.id
      LEFT JOIN users u ON e.creator_id = u.id
      LEFT JOIN (
        SELECT event_id, COUNT(*) as likes_count
        FROM event_likes
        GROUP BY event_id
      ) el ON el.event_id = e.id
      LEFT JOIN (
        SELECT event_id, user_id
        FROM event_likes
        WHERE user_id = $1
      ) ela ON ela.event_id = e.id
      LEFT JOIN (
        SELECT event_id, user_id
        FROM event_saves
        WHERE user_id = $1
      ) esa ON esa.event_id = e.id
      WHERE ea.user_id = $1
        AND e.event_date < NOW()
      ORDER BY e.event_date DESC`,
      [userId]
    );

    const toISOString = (dateValue) => {
      if (!dateValue) return new Date().toISOString();
      try {
        const date = dateValue instanceof Date ? dateValue : new Date(dateValue);
        if (isNaN(date.getTime())) {
          return new Date().toISOString();
        }
        return date.toISOString();
      } catch (err) {
        return new Date().toISOString();
      }
    };

    const events = result.rows.map(row => ({
      id: row.id.toString(),
      title: row.title,
      description: row.description || "",
      hostId: row.creator_id?.toString() || "",
      hostName: row.host_name || row.host_username || "Unknown Host",
      hostAvatar: row.host_avatar || null,
      date: toISOString(row.event_date),
      location: row.location || "",
      images: [],
      ticketPrice: row.ticket_price > 0 ? row.ticket_price : null,
      capacity: row.capacity || null,
      attendees: row.attendee_count || 0,
      talentIds: [],
      status: "completed",
      createdAt: toISOString(row.created_at),
      likes: parseInt(row.likes) || 0,
      isLiked: row.is_liked || false,
      isSaved: row.is_saved || false,
      isFeatured: row.is_featured || false
    }));

    res.json({ events });
  } catch (err) {
    console.error("Get attended events error:", err);
    res.status(500).json({ error: "Failed to fetch attended events" });
  }
});

// GET user events
router.get("/:id/events", async (req, res) => {
  try {
    const userId = req.params.id;
    const result = await db.query(
      `SELECT e.*, u.username as host_username, u.name as host_name, u.avatar as host_avatar
       FROM events e
       LEFT JOIN users u ON e.creator_id = u.id
       WHERE e.creator_id = $1
       ORDER BY e.event_date DESC`,
      [userId]
    );

    const events = result.rows.map(row => ({
      id: row.id.toString(),
      title: row.title,
      description: row.description || "",
      hostId: row.creator_id.toString(),
      hostName: row.host_name || row.host_username || "Unknown Host",
      hostAvatar: row.host_avatar || null,
      date: new Date(row.event_date).toISOString(),
      location: row.location || "",
      images: [],
      ticketPrice: row.ticket_price || 0,
      capacity: row.capacity || null,
      attendees: row.attendee_count || 0,
      talentIds: [],
      status: "published",
      created_at: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
      likes: row.likes || 0,
      isLiked: false,
      isSaved: false,
      isFeatured: row.is_featured || false
    }));

    res.json({ events });
  } catch (err) {
    console.error("Get user events error:", err);
    res.status(500).json({ error: "Failed to fetch user events" });
  }
});

// GET user posts
router.get("/:id/posts", async (req, res) => {
  try {
    const userId = req.params.id;
    const currentUserId = getUserIdFromToken(req);

    const result = await db.query(
      `SELECT DISTINCT
        p.*,
        u.username,
        u.name,
        u.avatar,
        COALESCE(pl.likes_count, 0) as likes_count,
        COALESCE(pc.comments_count, 0) as comments_count,
        CASE WHEN pla.user_id IS NOT NULL THEN true ELSE false END as is_liked
      FROM posts p
      LEFT JOIN users u ON p.user_id = u.id
      LEFT JOIN (
        SELECT post_id, COUNT(*) as likes_count
        FROM post_likes
        GROUP BY post_id
      ) pl ON pl.post_id = p.id
      LEFT JOIN (
        SELECT post_id, COUNT(*) as comments_count
        FROM comments
        GROUP BY post_id
      ) pc ON pc.post_id = p.id
      LEFT JOIN (
        SELECT post_id, user_id
        FROM post_likes
        WHERE user_id = $2
      ) pla ON pla.post_id = p.id
      WHERE p.user_id = $1
      ORDER BY p.created_at DESC`,
      [userId, currentUserId]
    );

    const posts = result.rows.map(row => ({
      id: row.id.toString(),
      userId: row.user_id.toString(),
      username: row.username || "",
      name: row.name || row.username || "",
      avatar: row.avatar || null,
      caption: row.caption || "",
      images: row.media_urls || [],
      location: row.location || null,
      likes: parseInt(row.likes_count) || 0,
      comments: parseInt(row.comments_count) || 0,
      isLiked: row.is_liked || false,
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
    }));

    res.json({ posts });
  } catch (err) {
    console.error("Get user posts error:", err);
    res.status(500).json({ error: "Failed to fetch user posts" });
  }
});

// UPDATE PROFILE
// POST upload profile avatar
router.post("/profile/avatar", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { avatar } = req.body;
    
    if (!avatar) {
      return res.status(400).json({ error: "Avatar is required" });
    }

    // Update user's avatar in database
    // For now, store the base64 string directly. In production, upload to S3/Cloudinary/etc.
    await db.query(
      `UPDATE users SET avatar = $1 WHERE id = $2`,
      [avatar, userId]
    );

    // Return updated user
    const result = await db.query(
      `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
              follower_count, following_count, event_count, created_at
       FROM users WHERE id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const userRow = result.rows[0];
    const user = {
      id: userRow.id.toString(),
      email: userRow.email,
      username: userRow.username,
      name: userRow.name || userRow.username,
      userType: userRow.user_type || "partier",
      bio: userRow.bio || null,
      avatar: userRow.avatar || null,
      location: userRow.location || null,
      verified: userRow.verified || false,
      createdAt: userRow.created_at ? new Date(userRow.created_at).toISOString() : new Date().toISOString(),
      followerCount: userRow.follower_count || 0,
      followingCount: userRow.following_count || 0,
      eventCount: userRow.event_count || 0,
      badges: []
    };

    res.json({ avatar: user.avatar });
  } catch (err) {
    console.error("Upload avatar error:", err);
    res.status(500).json({ error: "Failed to upload avatar" });
  }
});

router.patch("/profile", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { name, bio, location } = req.body;
    const updates = [];
    const params = [];
    let paramCount = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramCount}`);
      params.push(name);
      paramCount++;
    }
    if (bio !== undefined) {
      updates.push(`bio = $${paramCount}`);
      params.push(bio);
      paramCount++;
    }
    if (location !== undefined) {
      updates.push(`location = $${paramCount}`);
      params.push(location);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    params.push(userId);
    const query = `UPDATE users SET ${updates.join(", ")}, updated_at = NOW() WHERE id = $${paramCount} RETURNING *`;
    
    const result = await db.query(query, params);
    const userRow = result.rows[0];

    const user = {
      id: userRow.id.toString(),
      email: userRow.email,
      username: userRow.username,
      name: userRow.name || userRow.username,
      userType: userRow.user_type || "partier",
      bio: userRow.bio || null,
      avatar: userRow.avatar || null,
      location: userRow.location || null,
      verified: userRow.verified || false,
      createdAt: userRow.created_at ? new Date(userRow.created_at).toISOString() : new Date().toISOString(),
      followerCount: userRow.follower_count || 0,
      followingCount: userRow.following_count || 0,
      eventCount: userRow.event_count || 0,
      badges: []
    };

    res.json(user);
  } catch (err) {
    console.error("Update profile error:", err);
    res.status(500).json({ error: "Failed to update profile" });
  }
});

export default router;


