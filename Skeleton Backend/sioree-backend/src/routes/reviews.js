import express from "express";
import db from "../db/database.js";
import { getUserIdFromToken } from "../middleware/auth.js";

const router = express.Router();

// Helper function to safely convert dates to ISO8601
const toISOString = (dateValue) => {
  if (!dateValue) return new Date().toISOString();
  try {
    const date = dateValue instanceof Date ? dateValue : new Date(dateValue);
    if (isNaN(date.getTime())) {
      console.warn("Invalid date value:", dateValue);
      return new Date().toISOString();
    }
    return date.toISOString();
  } catch (err) {
    console.error("Error converting date to ISO8601:", err, dateValue);
    return new Date().toISOString();
  }
};

// POST /api/reviews - Create a review
router.post("/", async (req, res) => {
  try {
    const reviewerId = getUserIdFromToken(req);
    if (!reviewerId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { reviewedUserId, rating, comment } = req.body;

    // Validate input
    if (!reviewedUserId) {
      return res.status(400).json({ error: "reviewedUserId is required" });
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ error: "Rating must be between 1 and 5" });
    }

    // Check if reviewer is trying to review themselves
    if (reviewerId === reviewedUserId) {
      return res.status(400).json({ error: "Cannot review yourself" });
    }

    // Check if user being reviewed exists and is a host or talent
    const userCheck = await db.query(
      `SELECT user_type FROM users WHERE id = $1`,
      [reviewedUserId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const userType = userCheck.rows[0].user_type;
    if (userType !== "host" && userType !== "talent") {
      return res.status(400).json({ error: "Can only review hosts and talents" });
    }

    // Check if review already exists (upsert)
    const existingReview = await db.query(
      `SELECT id FROM reviews WHERE reviewer_id = $1 AND reviewed_user_id = $2`,
      [reviewerId, reviewedUserId]
    );

    let reviewId;
    if (existingReview.rows.length > 0) {
      // Update existing review
      const result = await db.query(
        `UPDATE reviews 
         SET rating = $1, comment = $2, updated_at = NOW()
         WHERE reviewer_id = $3 AND reviewed_user_id = $4
         RETURNING *`,
        [rating, comment || null, reviewerId, reviewedUserId]
      );
      reviewId = result.rows[0].id;
    } else {
      // Create new review
      const result = await db.query(
        `INSERT INTO reviews (reviewer_id, reviewed_user_id, rating, comment)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [reviewerId, reviewedUserId, rating, comment || null]
      );
      reviewId = result.rows[0].id;
    }

    // Fetch the complete review with reviewer info
    const reviewResult = await db.query(
      `SELECT 
        r.*,
        u.username as reviewer_username,
        u.name as reviewer_name,
        u.avatar as reviewer_avatar
      FROM reviews r
      LEFT JOIN users u ON r.reviewer_id = u.id
      WHERE r.id = $1`,
      [reviewId]
    );

    const reviewRow = reviewResult.rows[0];
    const review = {
      id: reviewRow.id.toString(),
      reviewerId: reviewRow.reviewer_id.toString(),
      reviewerName: reviewRow.reviewer_name || reviewRow.reviewer_username || "Anonymous",
      reviewerUsername: reviewRow.reviewer_username || "",
      reviewerAvatar: reviewRow.reviewer_avatar || null,
      reviewedUserId: reviewRow.reviewed_user_id.toString(),
      rating: reviewRow.rating,
      comment: reviewRow.comment || "",
      createdAt: toISOString(reviewRow.created_at),
      updatedAt: toISOString(reviewRow.updated_at)
    };

    res.status(existingReview.rows.length > 0 ? 200 : 201).json(review);
  } catch (err) {
    console.error("Create review error:", err);
    res.status(500).json({ error: "Failed to create review" });
  }
});

// GET /api/reviews/:userId - Get all reviews for a user
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await db.query(
      `SELECT 
        r.*,
        u.username as reviewer_username,
        u.name as reviewer_name,
        u.avatar as reviewer_avatar
      FROM reviews r
      LEFT JOIN users u ON r.reviewer_id = u.id
      WHERE r.reviewed_user_id = $1
      ORDER BY r.created_at DESC`,
      [userId]
    );

    const reviews = result.rows.map(row => ({
      id: row.id.toString(),
      reviewerId: row.reviewer_id.toString(),
      reviewerName: row.reviewer_name || row.reviewer_username || "Anonymous",
      reviewerUsername: row.reviewer_username || "",
      reviewerAvatar: row.reviewer_avatar || null,
      reviewedUserId: row.reviewed_user_id.toString(),
      rating: row.rating,
      comment: row.comment || "",
      createdAt: toISOString(row.created_at),
      updatedAt: toISOString(row.updated_at)
    }));

    res.json({ reviews });
  } catch (err) {
    console.error("Get reviews error:", err);
    res.status(500).json({ error: "Failed to fetch reviews" });
  }
});

// DELETE /api/reviews/:reviewId - Delete a review (only by reviewer)
router.delete("/:reviewId", async (req, res) => {
  try {
    const reviewerId = getUserIdFromToken(req);
    if (!reviewerId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { reviewId } = req.params;

    // Check if review exists and belongs to the reviewer
    const reviewCheck = await db.query(
      `SELECT reviewer_id FROM reviews WHERE id = $1`,
      [reviewId]
    );

    if (reviewCheck.rows.length === 0) {
      return res.status(404).json({ error: "Review not found" });
    }

    if (reviewCheck.rows[0].reviewer_id !== reviewerId) {
      return res.status(403).json({ error: "Can only delete your own reviews" });
    }

    await db.query(`DELETE FROM reviews WHERE id = $1`, [reviewId]);

    res.json({ success: true });
  } catch (err) {
    console.error("Delete review error:", err);
    res.status(500).json({ error: "Failed to delete review" });
  }
});

export default router;

