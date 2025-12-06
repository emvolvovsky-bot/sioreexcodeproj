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

// GET feed
router.get("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    const filter = req.query.filter || "all"; // 'all', 'following', 'nearby', 'trending'
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    let eventsQuery = "";
    let eventsParams = [];

    if (filter === "following" && userId) {
      // Get events from users you follow
      eventsQuery = `
        SELECT DISTINCT
          e.*,
          u.username as host_username,
          u.name as host_name,
          u.avatar as host_avatar,
          COALESCE(el.likes_count, 0) as likes,
          COALESCE(ela.user_liked, false) as is_liked,
          COALESCE(esa.user_saved, false) as is_saved
        FROM events e
        LEFT JOIN users u ON e.creator_id = u.id
        LEFT JOIN follows f ON f.following_id = e.creator_id AND f.follower_id = $1
        LEFT JOIN (
          SELECT event_id, COUNT(*) as likes_count
          FROM event_likes
          GROUP BY event_id
        ) el ON el.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_liked
          FROM event_likes
          WHERE user_id = $1
        ) ela ON ela.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_saved
          FROM event_saves
          WHERE user_id = $1
        ) esa ON esa.event_id = e.id
        WHERE e.event_date > NOW()
          AND f.follower_id IS NOT NULL
        ORDER BY e.event_date ASC
        LIMIT $2 OFFSET $3
      `;
      eventsParams = [userId, limit, offset];
    } else if (filter === "nearby") {
      // Get nearby events (for now, just upcoming events)
      eventsQuery = `
        SELECT DISTINCT
          e.*,
          u.username as host_username,
          u.name as host_name,
          u.avatar as host_avatar,
          COALESCE(el.likes_count, 0) as likes,
          COALESCE(ela.user_liked, false) as is_liked,
          COALESCE(esa.user_saved, false) as is_saved
        FROM events e
        LEFT JOIN users u ON e.creator_id = u.id
        LEFT JOIN (
          SELECT event_id, COUNT(*) as likes_count
          FROM event_likes
          GROUP BY event_id
        ) el ON el.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_liked
          FROM event_likes
          WHERE user_id = $1
        ) ela ON ela.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_saved
          FROM event_saves
          WHERE user_id = $1
        ) esa ON esa.event_id = e.id
        WHERE e.event_date > NOW()
        ORDER BY e.event_date ASC
        LIMIT $2 OFFSET $3
      `;
      eventsParams = userId ? [userId, limit, offset] : [null, limit, offset];
    } else if (filter === "trending") {
      // Get trending events (most liked/attended)
      eventsQuery = `
        SELECT DISTINCT
          e.*,
          u.username as host_username,
          u.name as host_name,
          u.avatar as host_avatar,
          COALESCE(el.likes_count, 0) as likes,
          COALESCE(ela.user_liked, false) as is_liked,
          COALESCE(esa.user_saved, false) as is_saved
        FROM events e
        LEFT JOIN users u ON e.creator_id = u.id
        LEFT JOIN (
          SELECT event_id, COUNT(*) as likes_count
          FROM event_likes
          GROUP BY event_id
        ) el ON el.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_liked
          FROM event_likes
          WHERE user_id = $1
        ) ela ON ela.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_saved
          FROM event_saves
          WHERE user_id = $1
        ) esa ON esa.event_id = e.id
        WHERE e.event_date > NOW()
        ORDER BY (COALESCE(el.likes_count, 0) + e.attendee_count) DESC, e.event_date ASC
        LIMIT $2 OFFSET $3
      `;
      eventsParams = userId ? [userId, limit, offset] : [null, limit, offset];
    } else {
      // All events
      eventsQuery = `
        SELECT DISTINCT
          e.*,
          u.username as host_username,
          u.name as host_name,
          u.avatar as host_avatar,
          COALESCE(el.likes_count, 0) as likes,
          COALESCE(ela.user_liked, false) as is_liked,
          COALESCE(esa.user_saved, false) as is_saved
        FROM events e
        LEFT JOIN users u ON e.creator_id = u.id
        LEFT JOIN (
          SELECT event_id, COUNT(*) as likes_count
          FROM event_likes
          GROUP BY event_id
        ) el ON el.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_liked
          FROM event_likes
          WHERE user_id = $1
        ) ela ON ela.event_id = e.id
        LEFT JOIN (
          SELECT event_id, true as user_saved
          FROM event_saves
          WHERE user_id = $1
        ) esa ON esa.event_id = e.id
        WHERE e.event_date > NOW()
        ORDER BY e.event_date ASC
        LIMIT $2 OFFSET $3
      `;
      eventsParams = userId ? [userId, limit, offset] : [null, limit, offset];
    }

    const eventsResult = await db.query(eventsQuery, eventsParams);

    // Get posts
    let postsQuery = "";
    let postsParams = [];

    if (filter === "following" && userId) {
      postsQuery = `
        SELECT DISTINCT
          p.*,
          u.username,
          u.name,
          u.avatar,
          COALESCE(pl.likes_count, 0) as likes_count,
          COALESCE(pla.user_liked, false) as is_liked
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN follows f ON f.following_id = p.user_id AND f.follower_id = $1
        LEFT JOIN (
          SELECT post_id, COUNT(*) as likes_count
          FROM post_likes
          GROUP BY post_id
        ) pl ON pl.post_id = p.id
        LEFT JOIN (
          SELECT post_id, true as user_liked
          FROM post_likes
          WHERE user_id = $1
        ) pla ON pla.post_id = p.id
        WHERE f.follower_id IS NOT NULL
        ORDER BY p.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      postsParams = [userId, limit, offset];
    } else {
      postsQuery = `
        SELECT DISTINCT
          p.*,
          u.username,
          u.name,
          u.avatar,
          COALESCE(pl.likes_count, 0) as likes_count,
          COALESCE(pla.user_liked, false) as is_liked
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN (
          SELECT post_id, COUNT(*) as likes_count
          FROM post_likes
          GROUP BY post_id
        ) pl ON pl.post_id = p.id
        LEFT JOIN (
          SELECT post_id, true as user_liked
          FROM post_likes
          WHERE user_id = $1
        ) pla ON pla.post_id = p.id
        ORDER BY p.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      postsParams = userId ? [userId, limit, offset] : [null, limit, offset];
    }

    const postsResult = await db.query(postsQuery, postsParams);

    // Format events
    const events = eventsResult.rows.map(row => ({
      id: row.id.toString(),
      title: row.title,
      description: row.description || "",
      hostId: row.creator_id?.toString() || "",
      hostName: row.host_name || row.host_username || "Unknown Host",
      hostAvatar: row.host_avatar || null,
      date: new Date(row.event_date).toISOString(),
      location: row.location || "",
      images: [],
      ticketPrice: parseFloat(row.ticket_price) || 0,
      capacity: row.capacity || null,
      attendees: row.attendee_count || 0,
      isLiked: row.is_liked || false,
      isSaved: row.is_saved || false,
      likes: parseInt(row.likes) || 0,
      isFeatured: row.is_featured || false,
      status: "published",
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
      talentIds: []
    }));

    // Format posts
    const posts = postsResult.rows.map(row => ({
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

    res.json({ events, posts });
  } catch (err) {
    console.error("Get feed error:", err);
    res.status(500).json({ error: "Failed to fetch feed" });
  }
});

export default router;

