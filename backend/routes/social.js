const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');
const { encryptForStorage } = require('../utils/encryption');

const router = express.Router();
router.use(authenticate);

// Helper to generate random state
function generateRandomString(length = 32) {
  return crypto.randomBytes(length).toString('hex');
}

// Instagram OAuth
router.get('/instagram/auth-url', (req, res) => {
  const state = generateRandomString();
  const authUrl = `https://api.instagram.com/oauth/authorize?` +
    `client_id=${process.env.INSTAGRAM_CLIENT_ID}&` +
    `redirect_uri=${encodeURIComponent(process.env.INSTAGRAM_REDIRECT_URI)}&` +
    `scope=user_profile,user_media&` +
    `response_type=code&` +
    `state=${state}`;
  
  // Store state in Redis (in production) or session
  // For now, we'll return it and verify on exchange
  res.json({ authUrl, state });
});

router.post('/instagram/exchange', async (req, res) => {
  try {
    const { code, state } = req.body;
    
    // Exchange code for access token
    const tokenResponse = await axios.post('https://api.instagram.com/oauth/access_token', {
      client_id: process.env.INSTAGRAM_CLIENT_ID,
      client_secret: process.env.INSTAGRAM_CLIENT_SECRET,
      grant_type: 'authorization_code',
      redirect_uri: process.env.INSTAGRAM_REDIRECT_URI,
      code: code,
    });
    
    const { access_token, user_id } = tokenResponse.data;
    
    // Get user profile
    const profileResponse = await axios.get(
      `https://graph.instagram.com/${user_id}?fields=id,username&access_token=${access_token}`
    );
    
    const username = profileResponse.data.username;
    const encryptedToken = encryptForStorage(access_token);
    
    // Save or update social account
    const result = await query(
      `INSERT INTO social_accounts 
       (user_id, platform, username, profile_url, access_token_encrypted, is_connected, created_at, updated_at)
       VALUES ($1, 'instagram', $2, $3, $4, true, NOW(), NOW())
       ON CONFLICT (user_id, platform) 
       DO UPDATE SET 
         username = $2,
         profile_url = $3,
         access_token_encrypted = $4,
         is_connected = true,
         updated_at = NOW()
       RETURNING id, platform, username, profile_url, is_connected, connected_at`,
      [
        req.user.id,
        username,
        `https://instagram.com/${username}`,
        encryptedToken,
      ]
    );
    
    const account = result.rows[0];
    
    res.json({
      account: {
        id: account.id,
        platform: account.platform,
        username: account.username,
        profileUrl: account.profile_url,
        isConnected: account.is_connected,
        connectedAt: account.connected_at,
      },
    });
  } catch (error) {
    console.error('Instagram OAuth error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to connect Instagram' });
  }
});

// TikTok OAuth (similar pattern)
router.get('/tiktok/auth-url', (req, res) => {
  const state = generateRandomString();
  const authUrl = `https://www.tiktok.com/v2/auth/authorize/` +
    `?client_key=${process.env.TIKTOK_CLIENT_KEY}` +
    `&scope=user.info.basic` +
    `&response_type=code` +
    `&redirect_uri=${encodeURIComponent(process.env.TIKTOK_REDIRECT_URI)}` +
    `&state=${state}`;
  
  res.json({ authUrl, state });
});

router.post('/tiktok/exchange', async (req, res) => {
  try {
    const { code } = req.body;
    
    // Exchange code for token (TikTok API)
    const tokenResponse = await axios.post('https://open.tiktokapis.com/v2/oauth/token/', {
      client_key: process.env.TIKTOK_CLIENT_KEY,
      client_secret: process.env.TIKTOK_CLIENT_SECRET,
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: process.env.TIKTOK_REDIRECT_URI,
    });
    
    const { access_token, open_id } = tokenResponse.data.data;
    
    // Get user info
    const userResponse = await axios.get(
      'https://open.tiktokapis.com/v2/user/info/',
      {
        headers: { Authorization: `Bearer ${access_token}` },
        params: { fields: 'open_id,username,display_name' },
      }
    );
    
    const username = userResponse.data.data.user?.username || `@user_${open_id}`;
    const encryptedToken = encryptForStorage(access_token);
    
    const result = await query(
      `INSERT INTO social_accounts 
       (user_id, platform, username, profile_url, access_token_encrypted, is_connected, created_at, updated_at)
       VALUES ($1, 'tiktok', $2, $3, $4, true, NOW(), NOW())
       ON CONFLICT (user_id, platform) 
       DO UPDATE SET 
         username = $2,
         access_token_encrypted = $4,
         is_connected = true,
         updated_at = NOW()
       RETURNING id, platform, username, profile_url, is_connected, connected_at`,
      [
        req.user.id,
        username,
        `https://tiktok.com/@${username}`,
        encryptedToken,
      ]
    );
    
    const account = result.rows[0];
    res.json({ account: formatSocialAccount(account) });
  } catch (error) {
    console.error('TikTok OAuth error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to connect TikTok' });
  }
});

// YouTube OAuth
router.get('/youtube/auth-url', (req, res) => {
  const state = generateRandomString();
  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
    `client_id=${process.env.GOOGLE_CLIENT_ID}&` +
    `redirect_uri=${encodeURIComponent(process.env.GOOGLE_REDIRECT_URI)}&` +
    `response_type=code&` +
    `scope=https://www.googleapis.com/auth/youtube.readonly&` +
    `state=${state}`;
  
  res.json({ authUrl, state });
});

router.post('/youtube/exchange', async (req, res) => {
  try {
    const { code } = req.body;
    
    // Exchange code for token
    const tokenResponse = await axios.post('https://oauth2.googleapis.com/token', {
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: process.env.GOOGLE_REDIRECT_URI,
    });
    
    const { access_token } = tokenResponse.data;
    
    // Get channel info
    const channelResponse = await axios.get(
      'https://www.googleapis.com/youtube/v3/channels',
      {
        params: {
          part: 'snippet',
          mine: true,
        },
        headers: { Authorization: `Bearer ${access_token}` },
      }
    );
    
    const channel = channelResponse.data.items[0];
    const username = channel.snippet.title;
    const encryptedToken = encryptForStorage(access_token);
    
    const result = await query(
      `INSERT INTO social_accounts 
       (user_id, platform, username, profile_url, access_token_encrypted, is_connected, created_at, updated_at)
       VALUES ($1, 'youtube', $2, $3, $4, true, NOW(), NOW())
       ON CONFLICT (user_id, platform) 
       DO UPDATE SET 
         username = $2,
         access_token_encrypted = $4,
         is_connected = true,
         updated_at = NOW()
       RETURNING id, platform, username, profile_url, is_connected, connected_at`,
      [
        req.user.id,
        username,
        `https://youtube.com/@${channel.snippet.customUrl || username}`,
        encryptedToken,
      ]
    );
    
    const account = result.rows[0];
    res.json({ account: formatSocialAccount(account) });
  } catch (error) {
    console.error('YouTube OAuth error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to connect YouTube' });
  }
});

// Spotify OAuth
router.get('/spotify/auth-url', (req, res) => {
  const state = generateRandomString();
  const authUrl = `https://accounts.spotify.com/authorize?` +
    `client_id=${process.env.SPOTIFY_CLIENT_ID}&` +
    `response_type=code&` +
    `redirect_uri=${encodeURIComponent(process.env.SPOTIFY_REDIRECT_URI)}&` +
    `scope=user-read-private user-read-email&` +
    `state=${state}`;
  
  res.json({ authUrl, state });
});

router.post('/spotify/exchange', async (req, res) => {
  try {
    const { code } = req.body;
    
    // Exchange code for token
    const tokenResponse = await axios.post('https://accounts.spotify.com/api/token', 
      new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: process.env.SPOTIFY_REDIRECT_URI,
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          Authorization: `Basic ${Buffer.from(`${process.env.SPOTIFY_CLIENT_ID}:${process.env.SPOTIFY_CLIENT_SECRET}`).toString('base64')}`,
        },
      }
    );
    
    const { access_token } = tokenResponse.data;
    
    // Get user profile
    const userResponse = await axios.get('https://api.spotify.com/v1/me', {
      headers: { Authorization: `Bearer ${access_token}` },
    });
    
    const username = userResponse.data.display_name || userResponse.data.id;
    const encryptedToken = encryptForStorage(access_token);
    
    const result = await query(
      `INSERT INTO social_accounts 
       (user_id, platform, username, profile_url, access_token_encrypted, is_connected, created_at, updated_at)
       VALUES ($1, 'spotify', $2, $3, $4, true, NOW(), NOW())
       ON CONFLICT (user_id, platform) 
       DO UPDATE SET 
         username = $2,
         access_token_encrypted = $4,
         is_connected = true,
         updated_at = NOW()
       RETURNING id, platform, username, profile_url, is_connected, connected_at`,
      [
        req.user.id,
        username,
        userResponse.data.external_urls?.spotify || `https://open.spotify.com/user/${userResponse.data.id}`,
        encryptedToken,
      ]
    );
    
    const account = result.rows[0];
    res.json({ account: formatSocialAccount(account) });
  } catch (error) {
    console.error('Spotify OAuth error:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to connect Spotify' });
  }
});

// GET /api/social/accounts
router.get('/accounts', async (req, res) => {
  try {
    const result = await query(
      `SELECT id, platform, username, profile_url, is_connected, created_at as connected_at
       FROM social_accounts
       WHERE user_id = $1 AND is_connected = true
       ORDER BY created_at DESC`,
      [req.user.id]
    );
    
    const accounts = result.rows.map(row => formatSocialAccount(row));
    
    res.json({ accounts });
  } catch (error) {
    console.error('Get social accounts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/social/accounts/:accountId
router.delete('/accounts/:accountId', async (req, res) => {
  try {
    const { accountId } = req.params;
    
    // Verify ownership
    const accountResult = await query(
      'SELECT id FROM social_accounts WHERE id = $1 AND user_id = $2',
      [accountId, req.user.id]
    );
    
    if (accountResult.rows.length === 0) {
      return res.status(404).json({ error: 'Account not found' });
    }
    
    // Mark as disconnected (don't delete for history)
    await query(
      'UPDATE social_accounts SET is_connected = false, updated_at = NOW() WHERE id = $1',
      [accountId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Disconnect social account error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Helper function
function formatSocialAccount(row) {
  return {
    id: row.id,
    platform: row.platform,
    username: row.username,
    profileUrl: row.profile_url,
    isConnected: row.is_connected,
    connectedAt: row.connected_at,
  };
}

module.exports = router;

