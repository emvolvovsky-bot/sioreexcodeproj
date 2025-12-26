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

// GET search
router.get("/", async (req, res) => {
  try {
    const query = req.query.q || "";
    const category = req.query.category || "all"; // 'all', 'events', 'hosts', 'talent', 'posts'
    const userId = getUserIdFromToken(req);

    if (!query || query.length < 2) {
      return res.json({ events: [], hosts: [], talent: [], posts: [] });
    }

    const searchPattern = `%${query}%`;
    const results = {
      events: [],
      hosts: [],
      talent: [],
      posts: []
    };

    // Search events
    if (category === "all" || category === "events") {
      const eventsResult = await db.query(
        `SELECT DISTINCT
          e.*,
          u.username as host_username,
          u.name as host_name,
          u.avatar as host_avatar,
          COALESCE(el.likes_count, 0) as likes
        FROM events e
        LEFT JOIN users u ON e.creator_id = u.id
        LEFT JOIN (
          SELECT event_id, COUNT(*) as likes_count
          FROM event_likes
          GROUP BY event_id
        ) el ON el.event_id = e.id
        WHERE (LOWER(e.title) LIKE LOWER($1) OR LOWER(e.description) LIKE LOWER($1) OR LOWER(e.location) LIKE LOWER($1))
          AND e.event_date > NOW()
        ORDER BY e.event_date ASC
        LIMIT 20`,
        [searchPattern]
      );

      results.events = eventsResult.rows.map(row => ({
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
        isLiked: false,
        isSaved: false,
        likes: parseInt(row.likes) || 0,
        isFeatured: row.is_featured || false,
        status: "published",
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
        talentIds: []
      }));
    }

    // Search hosts (users with user_type = 'host')
    if (category === "all" || category === "hosts") {
      const hostsResult = await db.query(
        `SELECT id, username, email, name, bio, avatar, user_type, location, verified, 
                follower_count, following_count, event_count, created_at
         FROM users 
         WHERE user_type = 'host'
           AND (LOWER(username) LIKE LOWER($1) OR LOWER(name) LIKE LOWER($1))
         ORDER BY follower_count DESC
         LIMIT 20`,
        [searchPattern]
      );

      results.hosts = hostsResult.rows.map(row => ({
        id: row.id.toString(),
        name: row.name || row.username,
        username: row.username,
        avatar: row.avatar || null,
        bio: row.bio || null,
        location: row.location || null,
        verified: row.verified || false,
        followerCount: row.follower_count || 0,
        eventCount: row.event_count || 0
      }));
    }

    // Search talent
    if (category === "all" || category === "talent") {
      const talentResult = await db.query(
        `SELECT 
          t.*,
          u.username,
          u.name,
          u.avatar,
          u.location,
          u.verified
         FROM talent t
         LEFT JOIN users u ON t.user_id = u.id
         WHERE (LOWER(u.name) LIKE LOWER($1) OR LOWER(u.username) LIKE LOWER($1) OR LOWER(t.bio) LIKE LOWER($1) OR LOWER(t.category) LIKE LOWER($1))
         ORDER BY t.rating DESC, t.review_count DESC
         LIMIT 20`,
        [searchPattern]
      );

      results.talent = talentResult.rows.map(row => ({
        id: row.id.toString(),
        userId: row.user_id.toString(),
        name: row.name || row.username || "Unknown",
        category: row.category,
        bio: row.bio || null,
        avatar: row.avatar || null,
        location: row.location || null,
        rating: parseFloat(row.rating) || 0,
        reviewCount: row.review_count || 0,
        priceRange: {
          min: parseFloat(row.price_min) || 0,
          max: parseFloat(row.price_max) || 0
        },
        portfolio: row.portfolio_urls || [],
        verified: row.verified || false,
        availability: [],
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      }));
    }

    // Search posts
    if (category === "all" || category === "posts") {
      const postsResult = await db.query(
        `SELECT DISTINCT
          p.*,
          u.username,
          u.name,
          u.avatar,
          COALESCE(pl.likes_count, 0) as likes_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN (
          SELECT post_id, COUNT(*) as likes_count
          FROM post_likes
          GROUP BY post_id
        ) pl ON pl.post_id = p.id
        WHERE LOWER(p.caption) LIKE LOWER($1)
        ORDER BY p.created_at DESC
        LIMIT 20`,
        [searchPattern]
      );

      results.posts = postsResult.rows.map(row => ({
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
        isLiked: false,
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      }));
    }

    res.json(results);
  } catch (err) {
    console.error("Search error:", err);
    res.status(500).json({ error: "Failed to search" });
  }
});

// GET trending searches
router.get("/trending", async (req, res) => {
  try {
    // For now, return empty array or some default trending searches
    // In production, this would track search queries and return most popular
    res.json([]);
  } catch (err) {
    console.error("Get trending searches error:", err);
    res.status(500).json({ error: "Failed to fetch trending searches" });
  }
});

export default router;

