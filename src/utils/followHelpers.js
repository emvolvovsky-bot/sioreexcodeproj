import jwt from "jsonwebtoken";
import { db } from "../db/database.js";

export function getUserIdFromToken(req) {
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

export async function setFollowState({ followerId, followingId, shouldFollow }) {
  if (!followerId) throw new Error("Unauthorized");
  if (followerId.toString() === followingId.toString()) {
    throw new Error("Cannot follow yourself");
  }

  if (shouldFollow) {
    await db.query(
      `INSERT INTO follows (follower_id, following_id) 
       VALUES ($1, $2)
       ON CONFLICT (follower_id, following_id) DO NOTHING`,
      [followerId, followingId]
    );
  } else {
    await db.query(
      `DELETE FROM follows WHERE follower_id = $1 AND following_id = $2`,
      [followerId, followingId]
    );
  }

  const followerCountResult = await db.query(
    `SELECT COUNT(*)::int AS count FROM follows WHERE following_id = $1`,
    [followingId]
  );
  const followingCountResult = await db.query(
    `SELECT COUNT(*)::int AS count FROM follows WHERE follower_id = $1`,
    [followerId]
  );

  const followerCount = followerCountResult.rows[0]?.count || 0;
  const followingCount = followingCountResult.rows[0]?.count || 0;

  await db.query(`UPDATE users SET follower_count = $1 WHERE id = $2`, [followerCount, followingId]);
  await db.query(`UPDATE users SET following_count = $1 WHERE id = $2`, [followingCount, followerId]);

  return { following: shouldFollow, followerCount, followingCount };
}

export async function getFollowingUsers(followerId) {
  const result = await db.query(
    `SELECT 
        u.id, u.email, u.username, u.name, u.bio, u.avatar, u.user_type, u.location, 
        u.verified, u.follower_count, u.following_count, u.event_count, u.created_at
     FROM follows f
     INNER JOIN users u ON f.following_id = u.id
     WHERE f.follower_id = $1
     ORDER BY f.created_at DESC`,
    [followerId]
  );

  return result.rows.map(row => ({
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
}
