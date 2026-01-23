import express from "express";
import { db } from "../db/database.js";
import jwt from "jsonwebtoken";

const router = express.Router();

// TEST ROUTE
router.get("/test", (req, res) => {
  res.json({ message: "Posts routes are working", timestamp: new Date().toISOString() });
});

// TEST DELETE IMAGE ROUTE
router.get("/:id/delete-image/test", (req, res) => {
  res.json({ message: "Delete image route exists", postId: req.params.id });
});

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

// CREATE POST
router.post("/", async (req, res) => {
  try {
    console.log("📝 CREATE POST - Received body:", JSON.stringify(req.body, null, 2));
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { caption, mediaUrls, location, eventId } = req.body;
    console.log("📝 CREATE POST - Extracted values:", { caption, mediaUrlsCount: mediaUrls?.length, location, eventId });

    // Convert eventId to integer if provided
    const eventIdInt = eventId ? parseInt(eventId, 10) : null;
    if (eventId && isNaN(eventIdInt)) {
      return res.status(400).json({ error: "Invalid eventId" });
    }

    const result = await db.query(
      `INSERT INTO posts (user_id, caption, images, location, event_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [userId, caption || null, mediaUrls || [], location || null, eventIdInt]
    );

    const postRow = result.rows[0];
    const userResult = await db.query(`SELECT username, name, avatar FROM users WHERE id = $1`, [userId]);
    const user = userResult.rows[0] || {};

    const post = {
      id: postRow.id.toString(),
      userId: userId.toString(),
      username: user.username || "",
      name: user.name || user.username || "",
      avatar: user.avatar || null,
      caption: postRow.caption || "",
      images: postRow.images || [],
      location: postRow.location || null,
      eventId: postRow.event_id?.toString() || null,
      likes: 0,
      comments: 0,
      isLiked: false,
      createdAt: postRow.created_at ? new Date(postRow.created_at).toISOString() : new Date().toISOString()
    };

    res.json(post);
  } catch (err) {
    console.error("Create post error:", err);
    res.status(500).json({ error: "Failed to create post" });
  }
});

// GET POSTS FOR EVENT
router.get("/event/:eventId", async (req, res) => {
  try {
    const { eventId } = req.params;
    console.log("🔍 Fetching posts for eventId:", eventId, "type:", typeof eventId);

    const eventIdInt = parseInt(eventId, 10);
    if (isNaN(eventIdInt)) {
      return res.status(400).json({ error: "Invalid eventId" });
    }
    console.log("🔍 Parsed eventId:", eventIdInt, "from:", eventId);

    const result = await db.query(
      `SELECT
        p.*,
        u.username,
        u.name,
        u.avatar
       FROM posts p
       JOIN users u ON p.user_id = u.id
       WHERE p.event_id = $1
       ORDER BY p.created_at DESC`,
      [eventIdInt]
    );

    const posts = result.rows.map(row => ({
      id: row.id.toString(),
      userId: row.user_id.toString(),
      username: row.username || "",
      name: row.name || row.username || "",
      avatar: row.avatar || null,
      caption: row.caption || "",
      images: row.images || [],
      location: row.location || null,
      eventId: row.event_id?.toString() || null,
      likes: row.likes || 0,
      comments: row.comments || 0,
      isLiked: false,
      isSaved: false,
      createdAt: row.created_at
    }));

    res.json({ posts });
  } catch (error) {
    console.error("Get event posts error:", error);
    res.status(500).json({ error: "Failed to fetch event posts" });
  }
});

// GET USER POSTS
router.get("/user/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
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
    res.status(500).json({ error: "Failed to fetch posts" });
  }
});

// LIKE/UNLIKE POST
router.post("/:id/like", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const postId = req.params.id;

    const checkResult = await db.query(
      `SELECT * FROM post_likes WHERE post_id = $1 AND user_id = $2`,
      [postId, userId]
    );

    if (checkResult.rows.length > 0) {
      await db.query(
        `DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2`,
        [postId, userId]
      );
      await db.query(
        `UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = $1`,
        [postId]
      );
      res.json({ liked: false });
    } else {
      await db.query(
        `INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)`,
        [postId, userId]
      );
      await db.query(
        `UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1`,
        [postId]
      );
      res.json({ liked: true });
    }
  } catch (err) {
    console.error("Like post error:", err);
    res.status(500).json({ error: "Failed to like/unlike post" });
  }
});

// DELETE SINGLE IMAGE FROM POST
router.delete("/:id/images", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const postId = parseInt(req.params.id, 10);
    if (isNaN(postId)) {
      return res.status(400).json({ error: "Invalid postId" });
    }

    const { imageUrl } = req.body;

    if (!imageUrl) {
      return res.status(400).json({ error: "imageUrl is required" });
    }

    const postResult = await db.query(`SELECT user_id, images FROM posts WHERE id = $1`, [postId]);
    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: "Post not found" });
    }

    const post = postResult.rows[0];
    if (post.user_id.toString() !== userId.toString()) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const images = post.images || [];
    const updatedImages = images.filter((url) => url !== imageUrl);

    if (updatedImages.length === images.length) {
      return res.status(400).json({ error: "Image not found in post" });
    }

    if (updatedImages.length === 0) {
      await db.query(`DELETE FROM posts WHERE id = $1`, [postId]);
      return res.json({ success: true });
    }

    await db.query(`UPDATE posts SET images = $1 WHERE id = $2`, [updatedImages, postId]);
    res.json({ success: true });
  } catch (err) {
    console.error("Delete post image error:", err);
    res.status(500).json({ error: "Failed to delete post image" });
  }
});

// TEST ROUTES (at the end to avoid conflicts)
router.get("/test", (req, res) => {
  res.json({ message: "Posts routes are working", timestamp: new Date().toISOString() });
});

router.get("/:id/images/test", (req, res) => {
  res.json({ message: "Delete image route exists", postId: req.params.id, method: "DELETE" });
});

export default router;

