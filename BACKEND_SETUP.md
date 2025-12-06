# Sioree Backend Setup Guide

This comprehensive guide will help you set up the complete backend infrastructure for the Sioree app.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Technology Stack Recommendations](#technology-stack-recommendations)
4. [API Endpoints](#api-endpoints)
5. [Third-Party Integrations](#third-party-integrations)
6. [Database Schema](#database-schema)
7. [Authentication & Security](#authentication--security)
8. [Real-Time Features](#real-time-features)
9. [Media Storage](#media-storage)
10. [Deployment](#deployment)
11. [Testing](#testing)

---

## Overview

The Sioree app requires a robust backend to handle:
- User authentication and authorization
- Real-time messaging between users
- Bank account connections via Plaid
- Social media OAuth integrations
- Event management and discovery
- Media uploads and storage
- Payment processing

---

## Architecture

### Recommended Architecture Pattern

```
┌─────────────┐
│   iOS App   │
└──────┬──────┘
       │ HTTPS/REST API
       │ WebSocket (Messaging)
┌──────▼──────────────────────────────┐
│         API Gateway                 │
│    (Rate Limiting, Auth)            │
└──────┬──────────────────────────────┘
       │
┌──────▼──────────────────────────────┐
│      Backend Services                │
│  ┌──────────┐  ┌──────────┐         │
│  │   Auth   │  │ Messaging│         │
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │  Events  │  │ Payments │         │
│  └──────────┘  └──────────┘         │
└──────┬──────────────────────────────┘
       │
┌──────▼──────────────────────────────┐
│      Database Layer                  │
│  ┌──────────┐  ┌──────────┐         │
│  │PostgreSQL│  │  Redis   │         │
│  └──────────┘  └──────────┘         │
└──────────────────────────────────────┘
```

---

## Technology Stack Recommendations

### Backend Framework Options

**Option 1: Node.js (Recommended for rapid development)**
- **Framework**: Express.js or Nest.js
- **Runtime**: Node.js 18+
- **Why**: Easy OAuth integration, good WebSocket support, large ecosystem

**Option 2: Python**
- **Framework**: FastAPI or Django
- **Why**: Strong data processing, good for ML features later

**Option 3: Go**
- **Framework**: Gin or Echo
- **Why**: High performance, good concurrency for messaging

### Database
- **Primary**: PostgreSQL 14+ (for relational data)
- **Cache**: Redis 7+ (for sessions, real-time data)
- **Search**: Elasticsearch or Algolia (for event search)

### Additional Services
- **Media Storage**: AWS S3, Cloudinary, or Firebase Storage
- **CDN**: CloudFront or Cloudflare
- **Email**: SendGrid, AWS SES, or Resend
- **Push Notifications**: Firebase Cloud Messaging (FCM) or APNs

---

## API Endpoints

### Base Configuration

Update `Constants.API.baseURL` in `Constants.swift`:
```swift
static let baseURL = "https://api.sioree.com" // Production
// static let baseURL = "https://api-dev.sioree.com" // Development
```

### Authentication Endpoints

#### POST /api/auth/signup
**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe",
  "role": "host" // or "partier", "talent", "brand"
}
```

**Response:**
```json
{
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "host"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here"
}
```

#### POST /api/auth/login
**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response:** Same as signup

#### POST /api/auth/logout
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true
}
```

#### GET /api/auth/me
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "host",
  "avatar": "https://cdn.sioree.com/avatars/user_123.jpg",
  "bio": "Event host based in LA",
  "location": "Los Angeles, CA"
}
```

#### POST /api/auth/refresh
**Request:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

**Response:**
```json
{
  "token": "new_access_token",
  "refreshToken": "new_refresh_token"
}
```

---

### Messaging Endpoints

#### GET /api/messages/conversations
**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response:**
```json
{
  "conversations": [
    {
      "id": "conv_123",
      "participantId": "user_456",
      "participantName": "DJ Midnight",
      "participantAvatar": "https://cdn.sioree.com/avatars/user_456.jpg",
      "lastMessage": "Hey! I'm available for your event.",
      "lastMessageTime": "2024-01-15T10:30:00Z",
      "unreadCount": 2,
      "isActive": true
    }
  ],
  "total": 15,
  "page": 1,
  "limit": 20
}
```

#### GET /api/messages/:conversationId
**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Messages per page (default: 50)

**Response:**
```json
{
  "messages": [
    {
      "id": "msg_789",
      "conversationId": "conv_123",
      "senderId": "user_456",
      "receiverId": "user_123",
      "text": "Hey! I'm available for your event.",
      "timestamp": "2024-01-15T10:30:00Z",
      "isRead": false,
      "messageType": "text"
    }
  ],
  "hasMore": false
}
```

#### POST /api/messages
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "conversationId": "conv_123", // Optional if creating new conversation
  "receiverId": "user_456",
  "text": "Hello! Are you available?",
  "messageType": "text"
}
```

**Response:**
```json
{
  "id": "msg_789",
  "conversationId": "conv_123",
  "senderId": "user_123",
  "receiverId": "user_456",
  "text": "Hello! Are you available?",
  "timestamp": "2024-01-15T10:35:00Z",
  "isRead": false,
  "messageType": "text"
}
```

#### POST /api/messages/conversation
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "userId": "user_456"
}
```

**Response:**
```json
{
  "id": "conv_123",
  "participantId": "user_456",
  "participantName": "DJ Midnight",
  "participantAvatar": "https://cdn.sioree.com/avatars/user_456.jpg",
  "lastMessage": "",
  "lastMessageTime": "2024-01-15T10:00:00Z",
  "unreadCount": 0,
  "isActive": true
}
```

#### POST /api/messages/:conversationId/read
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true
}
```

---

### Bank Account Endpoints (Plaid Integration)

#### POST /api/bank/link-token
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "linkToken": "link-sandbox-abc123...",
  "expiration": "2024-01-15T11:00:00Z"
}
```

**Backend Implementation (Node.js example):**
```javascript
const plaid = require('plaid');

const client = new plaid.Client({
  clientID: process.env.PLAID_CLIENT_ID,
  secret: process.env.PLAID_SECRET,
  env: plaid.environments.sandbox, // or production
});

app.post('/api/bank/link-token', authenticate, async (req, res) => {
  try {
    const response = await client.createLinkToken({
      user: {
        client_user_id: req.user.id,
      },
      client_name: 'Sioree',
      products: ['auth', 'transactions'],
      country_codes: ['US'],
      language: 'en',
    });
    
    res.json({ linkToken: response.link_token });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### POST /api/bank/exchange-token
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "publicToken": "public-sandbox-abc123..."
}
```

**Response:**
```json
{
  "account": {
    "id": "bank_acc_123",
    "bankName": "Chase",
    "accountType": "checking",
    "last4": "1234",
    "isVerified": true,
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

**Backend Implementation:**
```javascript
app.post('/api/bank/exchange-token', authenticate, async (req, res) => {
  try {
    const { publicToken } = req.body;
    
    // Exchange public token for access token
    const response = await client.exchangePublicToken(publicToken);
    const accessToken = response.access_token;
    
    // Get account information
    const accountsResponse = await client.getAccounts(accessToken);
    const account = accountsResponse.accounts[0];
    
    // Save to database
    const bankAccount = await BankAccount.create({
      userId: req.user.id,
      plaidAccessToken: accessToken, // Encrypt this!
      plaidItemId: response.item_id,
      bankName: account.name,
      accountType: account.type,
      last4: account.mask,
      isVerified: true,
    });
    
    res.json({ account: formatBankAccount(bankAccount) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### GET /api/bank/accounts
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "accounts": [
    {
      "id": "bank_acc_123",
      "bankName": "Chase",
      "accountType": "checking",
      "last4": "1234",
      "isVerified": true,
      "createdAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### DELETE /api/bank/accounts/:accountId
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true
}
```

---

### Social Media OAuth Endpoints

#### Instagram OAuth Flow

**Step 1: GET /api/social/instagram/auth-url**
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "authUrl": "https://api.instagram.com/oauth/authorize?client_id=YOUR_CLIENT_ID&redirect_uri=sioree://instagram-callback&scope=user_profile,user_media&response_type=code",
  "state": "random_state_string"
}
```

**Backend Implementation:**
```javascript
app.get('/api/social/instagram/auth-url', authenticate, (req, res) => {
  const state = generateRandomString();
  const authUrl = `https://api.instagram.com/oauth/authorize?` +
    `client_id=${process.env.INSTAGRAM_CLIENT_ID}&` +
    `redirect_uri=${encodeURIComponent(process.env.INSTAGRAM_REDIRECT_URI)}&` +
    `scope=user_profile,user_media&` +
    `response_type=code&` +
    `state=${state}`;
  
  // Store state in session/redis for verification
  req.session.instagramState = state;
  
  res.json({ authUrl, state });
});
```

**Step 2: POST /api/social/instagram/exchange**
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "code": "authorization_code_from_instagram",
  "state": "state_from_step_1"
}
```

**Response:**
```json
{
  "account": {
    "id": "social_acc_123",
    "platform": "instagram",
    "username": "@user_instagram",
    "profileUrl": "https://instagram.com/user_instagram",
    "isConnected": true,
    "connectedAt": "2024-01-15T10:00:00Z"
  }
}
```

**Backend Implementation:**
```javascript
app.post('/api/social/instagram/exchange', authenticate, async (req, res) => {
  try {
    const { code, state } = req.body;
    
    // Verify state
    if (req.session.instagramState !== state) {
      return res.status(400).json({ error: 'Invalid state' });
    }
    
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
    
    // Save to database
    const socialAccount = await SocialAccount.create({
      userId: req.user.id,
      platform: 'instagram',
      username: profileResponse.data.username,
      profileUrl: `https://instagram.com/${profileResponse.data.username}`,
      accessToken: encrypt(access_token), // Encrypt!
      refreshToken: null,
      isConnected: true,
    });
    
    res.json({ account: formatSocialAccount(socialAccount) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### Similar Endpoints for Other Platforms

- `GET /api/social/tiktok/auth-url`
- `POST /api/social/tiktok/exchange`
- `GET /api/social/youtube/auth-url`
- `POST /api/social/youtube/exchange`
- `GET /api/social/spotify/auth-url`
- `POST /api/social/spotify/exchange`

#### GET /api/social/accounts
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "accounts": [
    {
      "id": "social_acc_123",
      "platform": "instagram",
      "username": "@user_instagram",
      "profileUrl": "https://instagram.com/user_instagram",
      "isConnected": true,
      "connectedAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### DELETE /api/social/accounts/:accountId
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true
}
```

---

### Media Upload Endpoints

#### POST /api/media/upload
**Headers:** 
- `Authorization: Bearer <token>`
- `Content-Type: multipart/form-data`

**Request:** Form data with file

**Response:**
```json
{
  "url": "https://cdn.sioree.com/uploads/abc123.jpg",
  "thumbnailUrl": "https://cdn.sioree.com/uploads/thumbnails/abc123.jpg",
  "fileSize": 1024000,
  "mimeType": "image/jpeg"
}
```

**Backend Implementation (Node.js with AWS S3):**
```javascript
const multer = require('multer');
const AWS = require('aws-sdk');
const sharp = require('sharp');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
});

const upload = multer({ storage: multer.memoryStorage() });

app.post('/api/media/upload', authenticate, upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    const userId = req.user.id;
    
    // Generate unique filename
    const fileExtension = file.originalname.split('.').pop();
    const fileName = `${userId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExtension}`;
    
    // Upload original
    const uploadParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: fileName,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'public-read',
    };
    
    const uploadResult = await s3.upload(uploadParams).promise();
    
    // Generate thumbnail if image
    let thumbnailUrl = null;
    if (file.mimetype.startsWith('image/')) {
      const thumbnail = await sharp(file.buffer)
        .resize(300, 300, { fit: 'inside' })
        .toBuffer();
      
      const thumbnailKey = `thumbnails/${fileName}`;
      await s3.upload({
        ...uploadParams,
        Key: thumbnailKey,
        Body: thumbnail,
      }).promise();
      
      thumbnailUrl = `https://${process.env.S3_BUCKET_NAME}.s3.amazonaws.com/${thumbnailKey}`;
    }
    
    res.json({
      url: uploadResult.Location,
      thumbnailUrl: thumbnailUrl || uploadResult.Location,
      fileSize: file.size,
      mimeType: file.mimetype,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### POST /api/media/upload-multiple
**Headers:** 
- `Authorization: Bearer <token>`
- `Content-Type: multipart/form-data`

**Request:** Form data with multiple files

**Response:**
```json
{
  "urls": [
    {
      "url": "https://cdn.sioree.com/uploads/abc123.jpg",
      "thumbnailUrl": "https://cdn.sioree.com/uploads/thumbnails/abc123.jpg"
    }
  ]
}
```

---

### Events Endpoints

#### GET /api/events
**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page
- `location` (optional): Filter by location
- `date` (optional): Filter by date
- `search` (optional): Search query

**Response:**
```json
{
  "events": [
    {
      "id": "event_123",
      "hostId": "user_123",
      "title": "Halloween Mansion Party",
      "hostName": "LindaFlora",
      "date": "2024-10-31T20:00:00Z",
      "location": "Bel Air, CA",
      "priceText": "$75",
      "imageName": "party.popper.fill",
      "tags": ["House Party", "Halloween"],
      "isFeatured": true,
      "images": ["https://cdn.sioree.com/events/event_123_1.jpg"]
    }
  ],
  "total": 50,
  "page": 1
}
```

#### POST /api/events
**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "title": "New Year's Eve Party",
  "description": "Celebrate the new year!",
  "date": "2024-12-31T22:00:00Z",
  "location": "Downtown LA",
  "latitude": 34.0522,
  "longitude": -118.2437,
  "ticketPrice": 50,
  "capacity": 200,
  "tags": ["New Year", "Party"],
  "isFeatured": false,
  "images": ["https://cdn.sioree.com/uploads/img1.jpg"]
}
```

**Response:**
```json
{
  "id": "event_456",
  "hostId": "user_123",
  "title": "New Year's Eve Party",
  "date": "2024-12-31T22:00:00Z",
  "location": "Downtown LA",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

## Third-Party Integrations

### 1. Plaid (Bank Accounts)

#### Setup Steps

1. **Create Plaid Account**
   - Go to https://dashboard.plaid.com/signup
   - Complete registration
   - Get your API keys from the dashboard

2. **Install Plaid SDK**
   ```bash
   npm install plaid
   # or
   pip install plaid-python
   ```

3. **Environment Variables**
   ```env
   PLAID_CLIENT_ID=your_client_id
   PLAID_SECRET=your_secret_key
   PLAID_ENV=sandbox  # or production
   ```

4. **Initialize Plaid Client**
   ```javascript
   const plaid = require('plaid');
   
   const client = new plaid.Client({
     clientID: process.env.PLAID_CLIENT_ID,
     secret: process.env.PLAID_SECRET,
     env: process.env.PLAID_ENV === 'production' 
       ? plaid.environments.production 
       : plaid.environments.sandbox,
   });
   ```

5. **Webhook Setup**
   - Configure webhook URL in Plaid dashboard
   - Handle webhooks for account updates, transactions, etc.

#### Security Best Practices
- **Never store Plaid access tokens in plain text** - Use encryption
- **Use environment variables** for all API keys
- **Implement token refresh** - Plaid tokens expire
- **Validate webhook signatures** - Verify requests are from Plaid

---

### 2. Instagram OAuth

#### Setup Steps

1. **Create Facebook App**
   - Go to https://developers.facebook.com/apps
   - Create new app
   - Add "Instagram Basic Display" product

2. **Configure OAuth**
   - Add redirect URI: `sioree://instagram-callback`
   - Get Client ID and Client Secret
   - Set up app review if needed

3. **Environment Variables**
   ```env
   INSTAGRAM_CLIENT_ID=your_client_id
   INSTAGRAM_CLIENT_SECRET=your_client_secret
   INSTAGRAM_REDIRECT_URI=sioree://instagram-callback
   ```

4. **OAuth Flow**
   - User clicks "Connect Instagram"
   - Redirect to Instagram authorization URL
   - User authorizes
   - Instagram redirects with code
   - Exchange code for access token
   - Store token securely

#### Token Management
- Instagram tokens expire - implement refresh flow
- Handle token revocation
- Store tokens encrypted in database

---

### 3. TikTok OAuth

1. **Create TikTok App**
   - Go to https://developers.tiktok.com
   - Create app
   - Configure OAuth redirect URI

2. **Environment Variables**
   ```env
   TIKTOK_CLIENT_KEY=your_client_key
   TIKTOK_CLIENT_SECRET=your_client_secret
   TIKTOK_REDIRECT_URI=sioree://tiktok-callback
   ```

---

### 4. YouTube OAuth

1. **Google Cloud Console**
   - Create project at https://console.cloud.google.com
   - Enable YouTube Data API v3
   - Create OAuth 2.0 credentials
   - Add redirect URI

2. **Environment Variables**
   ```env
   GOOGLE_CLIENT_ID=your_client_id
   GOOGLE_CLIENT_SECRET=your_client_secret
   GOOGLE_REDIRECT_URI=sioree://youtube-callback
   ```

---

### 5. Spotify OAuth

1. **Create Spotify App**
   - Go to https://developer.spotify.com/dashboard
   - Create app
   - Set redirect URI

2. **Environment Variables**
   ```env
   SPOTIFY_CLIENT_ID=your_client_id
   SPOTIFY_CLIENT_SECRET=your_client_secret
   SPOTIFY_REDIRECT_URI=sioree://spotify-callback
   ```

---

## Database Schema

### PostgreSQL Tables

#### users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('host', 'partier', 'talent', 'brand')),
    avatar_url TEXT,
    bio TEXT,
    location VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

#### conversations
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    participant2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_time TIMESTAMP,
    participant1_unread_count INTEGER DEFAULT 0,
    participant2_unread_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(participant1_id, participant2_id)
);

CREATE INDEX idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_participant2 ON conversations(participant2_id);
```

#### messages
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'event_invite')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
```

#### bank_accounts
```sql
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bank_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('checking', 'savings')),
    last4 VARCHAR(4) NOT NULL,
    plaid_access_token_encrypted TEXT NOT NULL, -- Encrypted!
    plaid_item_id VARCHAR(255),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bank_accounts_user ON bank_accounts(user_id);
```

#### social_accounts
```sql
CREATE TABLE social_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('instagram', 'tiktok', 'youtube', 'spotify', 'twitter', 'soundcloud', 'apple_music')),
    username VARCHAR(255) NOT NULL,
    profile_url TEXT,
    access_token_encrypted TEXT, -- Encrypted!
    refresh_token_encrypted TEXT, -- Encrypted!
    expires_at TIMESTAMP,
    is_connected BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, platform)
);

CREATE INDEX idx_social_accounts_user ON social_accounts(user_id);
CREATE INDEX idx_social_accounts_platform ON social_accounts(platform);
```

#### events
```sql
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    date TIMESTAMP NOT NULL,
    location VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    ticket_price DECIMAL(10, 2),
    capacity INTEGER,
    tags TEXT[], -- Array of tags
    is_featured BOOLEAN DEFAULT false,
    images TEXT[], -- Array of image URLs
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_events_host ON events(host_id);
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_events_location ON events(location);
CREATE INDEX idx_events_featured ON events(is_featured) WHERE is_featured = true;
```

#### event_attendees
```sql
CREATE TABLE event_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'going' CHECK (status IN ('going', 'interested', 'not_going')),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX idx_event_attendees_event ON event_attendees(event_id);
CREATE INDEX idx_event_attendees_user ON event_attendees(user_id);
```

---

## Authentication & Security

### JWT Token Implementation

**Token Structure:**
```json
{
  "userId": "user_123",
  "email": "user@example.com",
  "role": "host",
  "iat": 1705315200,
  "exp": 1705401600
}
```

**Backend Implementation (Node.js):**
```javascript
const jwt = require('jsonwebtoken');

// Generate tokens
function generateTokens(user) {
  const accessToken = jwt.sign(
    { userId: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );
  
  const refreshToken = jwt.sign(
    { userId: user.id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );
  
  return { accessToken, refreshToken };
}

// Middleware to verify token
function authenticate(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```

### Password Hashing

**Use bcrypt:**
```javascript
const bcrypt = require('bcrypt');

// Hash password
async function hashPassword(password) {
  const saltRounds = 10;
  return await bcrypt.hash(password, saltRounds);
}

// Verify password
async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}
```

### Encryption for Sensitive Data

**Encrypt OAuth tokens and bank account tokens:**
```javascript
const crypto = require('crypto');

const algorithm = 'aes-256-gcm';
const key = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag();
  
  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex'),
  };
}

function decrypt(encryptedData) {
  const decipher = crypto.createDecipheriv(
    algorithm,
    key,
    Buffer.from(encryptedData.iv, 'hex')
  );
  
  decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
  
  let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}
```

---

## Real-Time Features

### WebSocket Implementation for Messaging

**Using Socket.io (Node.js):**
```javascript
const io = require('socket.io')(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Authenticate socket connection
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.userId;
    next();
  } catch (error) {
    next(new Error('Authentication error'));
  }
});

// Handle connections
io.on('connection', (socket) => {
  console.log(`User ${socket.userId} connected`);
  
  // Join user's room
  socket.join(`user:${socket.userId}`);
  
  // Handle new message
  socket.on('send_message', async (data) => {
    const { conversationId, receiverId, text } = data;
    
    // Save to database
    const message = await Message.create({
      conversationId,
      senderId: socket.userId,
      receiverId,
      text,
    });
    
    // Emit to receiver
    io.to(`user:${receiverId}`).emit('new_message', message);
    
    // Confirm to sender
    socket.emit('message_sent', message);
  });
  
  // Handle typing indicator
  socket.on('typing', (data) => {
    socket.to(`user:${data.receiverId}`).emit('user_typing', {
      userId: socket.userId,
      isTyping: data.isTyping,
    });
  });
  
  socket.on('disconnect', () => {
    console.log(`User ${socket.userId} disconnected`);
  });
});
```

---

## Media Storage

### AWS S3 Setup

1. **Create S3 Bucket**
   - Go to AWS Console → S3
   - Create bucket: `sioree-media`
   - Enable versioning
   - Set up CORS configuration

2. **CORS Configuration:**
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"]
  }
]
```

3. **IAM Policy for S3 Access:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::sioree-media/*"
    }
  ]
}
```

### Cloudinary Alternative

**Setup:**
```javascript
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Upload image
const result = await cloudinary.uploader.upload(file.path, {
  folder: 'sioree',
  transformation: [
    { width: 1000, height: 1000, crop: 'limit' },
    { quality: 'auto' },
  ],
});
```

---

## Deployment

### Environment Setup

**Production Environment Variables:**
```env
# Server
NODE_ENV=production
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@host:5432/sioree_prod
REDIS_URL=redis://host:6379

# JWT
JWT_SECRET=your_super_secret_jwt_key_here
JWT_REFRESH_SECRET=your_super_secret_refresh_key_here
ENCRYPTION_KEY=your_32_byte_hex_encryption_key

# Plaid
PLAID_CLIENT_ID=your_plaid_client_id
PLAID_SECRET=your_plaid_secret
PLAID_ENV=production

# Instagram
INSTAGRAM_CLIENT_ID=your_instagram_client_id
INSTAGRAM_CLIENT_SECRET=your_instagram_client_secret
INSTAGRAM_REDIRECT_URI=sioree://instagram-callback

# AWS S3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
S3_BUCKET_NAME=sioree-media

# Other OAuth (similar pattern)
TIKTOK_CLIENT_KEY=...
SPOTIFY_CLIENT_ID=...
GOOGLE_CLIENT_ID=...
```

### Deployment Platforms

**Option 1: AWS (Recommended)**
- **Compute**: EC2 or ECS (Docker)
- **Database**: RDS PostgreSQL
- **Cache**: ElastiCache Redis
- **Storage**: S3 + CloudFront
- **Load Balancer**: ALB

**Option 2: Heroku**
- Easy deployment
- Add-ons for PostgreSQL, Redis
- Automatic SSL

**Option 3: Railway / Render**
- Simple setup
- Good for MVP

**Option 4: DigitalOcean**
- App Platform or Droplets
- Managed databases available

### Docker Setup

**Dockerfile:**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/sioree
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=sioree
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Testing

### API Testing with Postman

1. **Create Collection**
   - Import the API endpoints
   - Set up environment variables
   - Add authentication token

2. **Test Flow:**
   - Sign up → Get token
   - Use token for authenticated requests
   - Test messaging
   - Test OAuth flows
   - Test media uploads

### Unit Testing

**Example (Jest):**
```javascript
describe('Authentication', () => {
  test('should sign up new user', async () => {
    const response = await request(app)
      .post('/api/auth/signup')
      .send({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'host',
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
  });
});
```

---

## Next Steps

1. **Choose your tech stack** (Node.js recommended for speed)
2. **Set up development environment**
3. **Create database schema**
4. **Implement authentication**
5. **Set up third-party integrations** (start with one)
6. **Implement core endpoints**
7. **Add real-time messaging**
8. **Set up media storage**
9. **Deploy to staging**
10. **Test thoroughly**
11. **Deploy to production**
12. **Update app's API URL**

---

## Support & Resources

- **Plaid Docs**: https://plaid.com/docs/
- **Instagram API**: https://developers.facebook.com/docs/instagram-basic-display-api
- **Socket.io**: https://socket.io/docs/
- **AWS S3**: https://docs.aws.amazon.com/s3/

---

## Security Checklist

- [ ] All API endpoints use HTTPS
- [ ] JWT tokens have short expiration times
- [ ] Refresh tokens are stored securely
- [ ] Passwords are hashed with bcrypt
- [ ] OAuth tokens are encrypted in database
- [ ] Plaid access tokens are encrypted
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (use parameterized queries)
- [ ] CORS properly configured
- [ ] Environment variables never committed to git
- [ ] Regular security audits
- [ ] Webhook signature verification

---

Good luck building the Sioree backend! 🚀
