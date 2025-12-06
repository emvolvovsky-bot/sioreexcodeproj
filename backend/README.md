# Sioree Backend API

Backend server for the Sioree iOS app.

## Quick Start

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Set Up Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Set Up Database**
   ```bash
   # Make sure PostgreSQL is running
   createdb sioree
   psql sioree < migrations/001_initial_schema.sql
   ```

4. **Start Server**
   ```bash
   npm run dev  # Development with nodemon
   # or
   npm start    # Production
   ```

## Environment Variables

See `.env.example` for all required environment variables.

## API Endpoints

- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/refresh` - Refresh access token
- `GET /api/messages/conversations` - Get conversations
- `POST /api/messages` - Send message
- `POST /api/bank/link-token` - Get Plaid link token
- `POST /api/bank/exchange-token` - Exchange Plaid token
- `GET /api/social/instagram/auth-url` - Get Instagram OAuth URL
- `POST /api/social/instagram/exchange` - Exchange Instagram code
- `POST /api/media/upload` - Upload media file

## WebSocket Events

- `send_message` - Send a message
- `new_message` - Receive new message
- `typing` - Typing indicator
- `mark_read` - Mark messages as read

## Development

```bash
npm run dev    # Start with nodemon (auto-restart)
npm test      # Run tests
```

## Production Deployment

See main BACKEND_SETUP.md for deployment instructions.



