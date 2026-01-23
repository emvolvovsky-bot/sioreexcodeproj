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

// GET Instagram OAuth URL
router.get("/instagram/auth-url", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const clientId = process.env.INSTAGRAM_CLIENT_ID;
    const redirectUri = process.env.INSTAGRAM_REDIRECT_URI || "sioree://instagram-callback";
    const scope = "user_profile,user_media";

    if (!clientId) {
      return res.status(500).json({ error: "Instagram OAuth not configured. Please set INSTAGRAM_CLIENT_ID in environment variables." });
    }

    const state = jwt.sign({ userId, timestamp: Date.now() }, process.env.JWT_SECRET || "your-secret-key-change-in-production", { expiresIn: "10m" });
    
    const authUrl = `https://api.instagram.com/oauth/authorize?` +
      `client_id=${clientId}&` +
      `redirect_uri=${encodeURIComponent(redirectUri)}&` +
      `scope=${encodeURIComponent(scope)}&` +
      `response_type=code&` +
      `state=${encodeURIComponent(state)}`;

    res.json({ authUrl });
  } catch (err) {
    console.error("Instagram auth URL error:", err);
    res.status(500).json({ error: "Failed to generate Instagram auth URL" });
  }
});

// POST Instagram OAuth callback - exchange code for token
router.post("/instagram/exchange", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { code, state } = req.body;
    if (!code) return res.status(400).json({ error: "Authorization code required" });

    // Verify state token
    try {
      const decoded = jwt.verify(state, process.env.JWT_SECRET || "your-secret-key-change-in-production");
      if (decoded.userId !== userId) {
        return res.status(403).json({ error: "Invalid state token" });
      }
    } catch (err) {
      return res.status(403).json({ error: "Invalid or expired state token" });
    }

    const clientId = process.env.INSTAGRAM_CLIENT_ID;
    const clientSecret = process.env.INSTAGRAM_CLIENT_SECRET;
    const redirectUri = process.env.INSTAGRAM_REDIRECT_URI || "sioree://instagram-callback";

    if (!clientId || !clientSecret) {
      return res.status(500).json({ error: "Instagram OAuth not configured. Please set INSTAGRAM_CLIENT_ID and INSTAGRAM_CLIENT_SECRET in environment variables." });
    }

    // Exchange code for access token
    try {
      const tokenResponse = await fetch("https://api.instagram.com/oauth/access_token", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: new URLSearchParams({
          client_id: clientId,
          client_secret: clientSecret,
          grant_type: "authorization_code",
          redirect_uri: redirectUri,
          code: code
        })
      });

      if (!tokenResponse.ok) {
        throw new Error(`Instagram API error: ${tokenResponse.status}`);
      }

      const tokenData = await tokenResponse.json();
      const { access_token, user_id } = tokenData;

      // Get user info from Instagram Graph API
      const userResponse = await fetch(
        `https://graph.instagram.com/${user_id}?fields=id,username&access_token=${access_token}`
      );

      if (!userResponse.ok) {
        throw new Error(`Instagram Graph API error: ${userResponse.status}`);
      }

      const userData = await userResponse.json();
      const username = userData.username || `user_${user_id}`;

      // Save or update OAuth token in database
      // First check if table exists, if not create it
      await db.query(`
        CREATE TABLE IF NOT EXISTS oauth_tokens (
          id SERIAL PRIMARY KEY,
          user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
          provider VARCHAR(50) NOT NULL,
          access_token TEXT NOT NULL,
          refresh_token TEXT,
          expires_at TIMESTAMP,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW(),
          UNIQUE(user_id, provider)
        )
      `);
      
      await db.query(
        `INSERT INTO oauth_tokens (user_id, provider, access_token, expires_at, created_at)
         VALUES ($1, 'instagram', $2, NOW() + INTERVAL '60 days', NOW())
         ON CONFLICT (user_id, provider) 
         DO UPDATE SET access_token = $2, expires_at = NOW() + INTERVAL '60 days', updated_at = NOW()`,
        [userId, access_token]
      );

      const account = {
        id: userId.toString(),
        platform: "instagram",
        username: `@${username}`,
        profileUrl: `https://instagram.com/${username}`,
        isConnected: true,
        connectedAt: new Date().toISOString()
      };

      res.json(account);
    } catch (error) {
      console.error("Instagram token exchange error:", error.response?.data || error.message);
      res.status(500).json({ error: "Failed to exchange Instagram authorization code. Please try again." });
    }
  } catch (err) {
    console.error("Instagram exchange error:", err);
    res.status(500).json({ error: "Failed to connect Instagram" });
  }
});

// GET connected social media accounts
router.get("/accounts", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const result = await db.query(
      `SELECT provider, access_token, created_at 
       FROM oauth_tokens 
       WHERE user_id = $1 AND expires_at > NOW()`,
      [userId]
    );

    const accounts = result.rows.map(row => {
      // Extract username from token or use provider name
      const platform = row.provider;
      return {
        id: `${userId}_${platform}`,
        platform: platform,
        username: `@user_${platform}`,
        profileUrl: `https://${platform}.com/user`,
        isConnected: true,
        connectedAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      };
    });

    res.json(accounts);
  } catch (err) {
    console.error("Get connected accounts error:", err);
    res.status(500).json({ error: "Failed to fetch connected accounts" });
  }
});

// DELETE disconnect social media account
router.delete("/accounts/:accountId", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const accountId = req.params.accountId;
    // Extract platform from accountId (format: userId_platform)
    const platform = accountId.split("_").slice(1).join("_");

    await db.query(
      `DELETE FROM oauth_tokens WHERE user_id = $1 AND provider = $2`,
      [userId, platform]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("Disconnect account error:", err);
    res.status(500).json({ error: "Failed to disconnect account" });
  }
});

export default router;

