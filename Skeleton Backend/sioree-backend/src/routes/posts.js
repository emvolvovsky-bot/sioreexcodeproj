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

// CREATE POST
router.post("/", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { caption, mediaUrls, location, eventId } = req.body;
    console.log("[POST CREATE] Received mediaUrls:", JSON.stringify(mediaUrls));

    // Check if event_id column exists before using it
    let hasEventIdColumn = false;
    try {
      const columnCheck = await db.query(
        `SELECT column_name FROM information_schema.columns 
         WHERE table_name = 'posts' AND column_name = 'event_id'`
      );
      hasEventIdColumn = columnCheck.rows.length > 0;
    } catch (err) {
      // Column check failed, assume it doesn't exist
      hasEventIdColumn = false;
    }

    // Ensure mediaUrls is properly formatted for PostgreSQL array
    const mediaUrlsArray = Array.isArray(mediaUrls) ? mediaUrls : [];
    console.log("[POST CREATE] Saving mediaUrls as:", JSON.stringify(mediaUrlsArray));

    let result;
    if (hasEventIdColumn && eventId) {
      result = await db.query(
        `INSERT INTO posts (user_id, caption, media_urls, location, event_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [userId, caption || null, mediaUrlsArray, location || null, eventId]
      );
    } else {
      result = await db.query(
        `INSERT INTO posts (user_id, caption, media_urls, location)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [userId, caption || null, mediaUrlsArray, location || null]
      );
    }
    console.log("[POST CREATE] Saved post media_urls:", result.rows[0]?.media_urls);

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
      images: postRow.media_urls || [],
      location: postRow.location || null,
      eventId: hasEventIdColumn && postRow.event_id ? postRow.event_id.toString() : (eventId || null),
      likes: 0,
      comments: 0,
      isLiked: false,
      isSaved: false,
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
    const eventId = req.params.eventId;
    console.log(`[GET POSTS FOR EVENT] Fetching posts for eventId: ${eventId}`);

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
      WHERE p.event_id = $1
      ORDER BY p.created_at DESC`,
      [eventId, getUserIdFromToken(req)]
    );

    const posts = result.rows.map(row => {
      console.log("[GET POSTS FOR EVENT] Row media_urls:", row.media_urls, "type:", typeof row.media_urls);
      return {
        id: row.id.toString(),
        userId: row.user_id.toString(),
        username: row.username || "",
        name: row.name || row.username || "",
        avatar: row.avatar || null,
        caption: row.caption || "",
        images: Array.isArray(row.media_urls) ? row.media_urls : (row.media_urls ? JSON.parse(row.media_urls) : []),
        location: row.location || null,
        eventId: row.event_id ? row.event_id.toString() : null,
        likes: parseInt(row.likes_count) || 0,
        comments: parseInt(row.comments_count) || 0,
        isLiked: row.is_liked || false,
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      };
    });

    console.log(`[GET POSTS FOR EVENT] Returning ${posts.length} posts for event ${eventId}`);
    res.json({ posts });
  } catch (err) {
    console.error("Get posts for event error:", err);
    res.status(500).json({ error: "Failed to fetch posts for event" });
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

    const posts = result.rows.map(row => {
      console.log("[GET POSTS] Row media_urls:", row.media_urls, "type:", typeof row.media_urls);
      return {
        id: row.id.toString(),
        userId: row.user_id.toString(),
        username: row.username || "",
        name: row.name || row.username || "",
        avatar: row.avatar || null,
        caption: row.caption || "",
        images: Array.isArray(row.media_urls) ? row.media_urls : (row.media_urls ? JSON.parse(row.media_urls) : []),
        location: row.location || null,
        likes: parseInt(row.likes_count) || 0,
        comments: parseInt(row.comments_count) || 0,
        isLiked: row.is_liked || false,
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      };
    });

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

// DELETE POST
router.delete("/:id", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const postId = req.params.id;

    // First check if the post exists and belongs to the user
    const postResult = await db.query(
      `SELECT user_id FROM posts WHERE id = $1`,
      [postId]
    );

    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: "Post not found" });
    }

    if (postResult.rows[0].user_id !== userId) {
      return res.status(403).json({ error: "You can only delete your own posts" });
    }

    // Delete associated likes first
    await db.query(`DELETE FROM post_likes WHERE post_id = $1`, [postId]);

    // Delete associated comments
    await db.query(`DELETE FROM comments WHERE post_id = $1`, [postId]);

    // Delete the post
    await db.query(`DELETE FROM posts WHERE id = $1`, [postId]);

    console.log(`[DELETE POST] Post ${postId} deleted by user ${userId}`);
    res.json({ success: true });
  } catch (err) {
    console.error("Delete post error:", err);
    res.status(500).json({ error: "Failed to delete post" });
  }
});

// FIX: Migrate old URLs from us-east-1 to us-east-2
router.post("/fix-urls", async (req, res) => {
  try {
    // Get all posts with old URLs
    const result = await db.query(
      `SELECT id, media_urls FROM posts WHERE media_urls::text LIKE '%us-east-1%'`
    );

    let fixedCount = 0;
    for (const row of result.rows) {
      let urls = row.media_urls;
      if (typeof urls === 'string') {
        urls = JSON.parse(urls);
      }

      // Replace us-east-1 with us-east-2
      const fixedUrls = urls.map(url => url.replace('us-east-1', 'us-east-2'));

      await db.query(
        `UPDATE posts SET media_urls = $1 WHERE id = $2`,
        [fixedUrls, row.id]
      );
      fixedCount++;
    }

    console.log(`[FIX URLS] Fixed ${fixedCount} posts`);
    res.json({ success: true, fixedCount });
  } catch (err) {
    console.error("Fix URLs error:", err);
    res.status(500).json({ error: "Failed to fix URLs" });
  }
});

// DELETE SINGLE IMAGE FROM POST
router.patch("/:id/images", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const postId = req.params.id;
    const { imageUrl } = req.body;

    if (!imageUrl) {
      return res.status(400).json({ error: "imageUrl is required" });
    }

    const postResult = await db.query(`SELECT user_id, media_urls FROM posts WHERE id = $1`, [postId]);
    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: "Post not found" });
    }

    const post = postResult.rows[0];
    if (post.user_id.toString() !== userId.toString()) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const images = post.media_urls || [];
    const updatedImages = images.filter((url) => url !== imageUrl);

    if (updatedImages.length === images.length) {
      return res.status(400).json({ error: "Image not found in post" });
    }

    if (updatedImages.length === 0) {
      await db.query(`DELETE FROM posts WHERE id = $1`, [postId]);
      return res.json({ success: true });
    }

    await db.query(`UPDATE posts SET media_urls = $1 WHERE id = $2`, [updatedImages, postId]);
    res.json({ success: true });
  } catch (err) {
    console.error("Delete post image error:", err);
    res.status(500).json({ error: "Failed to delete post image" });
  }
});

export default router;

