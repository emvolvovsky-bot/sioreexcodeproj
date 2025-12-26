import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { db } from "../db/database.js";
import { sendWelcomeEmail, sendLoginEmail } from "../services/email.js";

const router = express.Router();

/*
---------------------------------------
  HELPER: GENERATE TOKEN
---------------------------------------
*/
function generateToken(userId) {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET || "your-secret-key-change-in-production",
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

/*
---------------------------------------
  SIGNUP
---------------------------------------
*/
router.post("/signup", async (req, res) => {
  try {
    const { email, password, username, name, userType, location } = req.body;

    if (!email || !password)
      return res.status(400).json({ error: "Email and password required" });

    // Check if user exists
    const existsResult = await db.query(
      `SELECT * FROM users WHERE email = $1 OR username = $2`,
      [email, username || email.split("@")[0]]
    ).catch(err => {
      console.error("Database query error:", err);
      throw err;
    });

    if (existsResult.rows.length > 0)
      return res.status(400).json({ error: "User already exists" });

    const hashed = bcrypt.hashSync(password, 10);
    const usernameValue = username || email.split("@")[0];
    const nameValue = name || usernameValue;

    // Insert user (include location if provided, especially for talent)
    const locationValue = location || null;
    const result = await db.query(
      `INSERT INTO users (email, password_hash, username, name, user_type, location)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, email, username, name, user_type, location, created_at`,
      [email, hashed, usernameValue, nameValue, userType || "partier", locationValue]
    );

    const userRow = result.rows[0];
    const token = generateToken(userRow.id);

    // Format user object to match iOS expectations
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
      averageRating: userRow.average_rating !== null ? parseFloat(userRow.average_rating) : null,
      reviewCount: userRow.review_count || 0,
      badges: []
    };

    console.log("✅ Signup successful for user:", email);
    
    // Send response immediately (don't wait for email)
    res.json({
      token,
      user
    });
    
    // Send welcome email after response (completely async, won't block)
    sendWelcomeEmail(email, nameValue).catch(err => {
      console.error("⚠️ Failed to send welcome email:", err);
    });
  } catch (err) {
    console.error("❌ Signup error:", err);
    console.error("   Error message:", err.message);
    console.error("   Error stack:", err.stack);
    res.status(500).json({ error: err.message || "Server error during signup" });
  }
});

/*
---------------------------------------
  LOGIN
---------------------------------------
*/
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password)
      return res.status(400).json({ error: "Email and password required" });

    console.log("🔐 Login attempt for:", email);

    // Get user from database with timeout protection and better error handling
    let result;
    try {
      result = await Promise.race([
        db.query(
          `SELECT * FROM users WHERE email = $1`,
          [email]
        ),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error("Database query timeout after 10 seconds")), 10000)
        )
      ]);
    } catch (dbError) {
      console.error("❌ Database query error:", dbError.message);
      console.error("❌ Error code:", dbError.code);
      console.error("❌ Error details:", {
        errno: dbError.errno,
        syscall: dbError.syscall,
        address: dbError.address,
        port: dbError.port
      });
      
      // Return a more user-friendly error
      if (dbError.code === "ENETUNREACH" || dbError.message.includes("ENETUNREACH")) {
        return res.status(503).json({ 
          error: "Database connection failed. Please check your network configuration." 
        });
      }
      if (dbError.message.includes("timeout") || dbError.message.includes("Connection terminated")) {
        return res.status(503).json({ 
          error: "Database connection timeout. Please try again in a moment." 
        });
      }
      if (dbError.code === "ECONNREFUSED") {
        return res.status(503).json({ 
          error: "Database server is not reachable. Please check your connection settings." 
        });
      }
      throw dbError;
    }

    if (result.rows.length === 0)
      return res.status(400).json({ error: "Invalid email or password" });

    const userRow = result.rows[0];

    // Verify password
    const valid = bcrypt.compareSync(password, userRow.password_hash);
    if (!valid)
      return res.status(400).json({ error: "Invalid email or password" });

    const token = generateToken(userRow.id);

    // Format user object to match iOS expectations
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
      averageRating: userRow.average_rating !== null ? parseFloat(userRow.average_rating) : null,
      reviewCount: userRow.review_count || 0,
      badges: []
    };

    console.log("✅ Login successful for user:", email);
    
    // Send response immediately (don't wait for email)
    res.json({
      token,
      user
    });
    
    // Send login notification email after response (completely async, won't block)
    sendLoginEmail(email, userRow.name || userRow.username).catch(err => {
      console.error("⚠️ Failed to send login email:", err);
    });
  } catch (err) {
    console.error("❌ Login error:", err);
    console.error("   Error message:", err.message);
    console.error("   Error stack:", err.stack);
    res.status(500).json({ error: err.message || "Server error during login" });
  }
});

/*
---------------------------------------
  GET CURRENT USER
---------------------------------------
*/
router.get("/me", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.log("❌ No auth header or invalid format");
      return res.status(401).json({ error: "Unauthorized" });
    }

    const token = authHeader.substring(7);
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    } catch (jwtError) {
      console.error("❌ JWT verification error:", jwtError.message);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    if (!decoded || !decoded.userId) {
      console.error("❌ Token decoded but missing userId");
      return res.status(401).json({ error: "Invalid token format" });
    }

    const result = await db.query(
      `SELECT * FROM users WHERE id = $1`,
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      console.error("❌ User not found for userId:", decoded.userId);
      return res.status(404).json({ error: "User not found" });
    }

    const userRow = result.rows[0];

    // Format user object to match iOS expectations
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
      averageRating: userRow.average_rating !== null ? parseFloat(userRow.average_rating) : null,
      reviewCount: userRow.review_count || 0,
      badges: []
    };

    res.json(user);
  } catch (err) {
    console.error("❌ Get current user error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/*
---------------------------------------
  LOGOUT
---------------------------------------
*/
router.post("/logout", (req, res) => {
  // In a stateless JWT system, logout is handled client-side
  // by removing the token. No server-side action needed.
  res.json({ message: "Logged out" });
});

/*
---------------------------------------
  DELETE ACCOUNT
---------------------------------------
*/
router.delete("/delete-account", async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer "))
      return res.status(401).json({ error: "Unauthorized" });

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");

    // Delete user from database
    await db.query(`DELETE FROM users WHERE id = $1`, [decoded.userId]);

    res.json({ message: "Account deleted successfully" });
  } catch (err) {
    console.error("Delete account error:", err);
    res.status(500).json({ error: "Failed to delete account" });
  }
});

export default router;
