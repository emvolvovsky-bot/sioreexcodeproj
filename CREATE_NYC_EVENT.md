# Create NYC Test Event

## Fixed Issues
✅ **Compilation Error Fixed**: Updated `AttendeeMessageView.swift` preview to include all required `Attendee` parameters (id, avatar, isVerified)

## Create NYC Event

To create a test event in New York that users can purchase tickets for, run this script:

### Option 1: Using the Script (if Node.js is installed)

```bash
cd "Skeleton Backend/sioree-backend"
node scripts/create-test-event.js
```

### Option 2: Using the API Directly

If you have a user account already, you can create the event via the API:

```bash
# First, login to get a token
curl -X POST http://192.168.1.200:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'

# Then create the event (replace YOUR_TOKEN with the token from above)
curl -X POST http://192.168.1.200:4000/api/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "NYC Rooftop Party - Summer Vibes",
    "description": "Join us for an epic rooftop party in the heart of New York City! Experience breathtaking skyline views, world-class DJs, premium cocktails, and an unforgettable night under the stars. This is the party you don'\''t want to miss!",
    "location": "230 5th Avenue Rooftop, New York, NY 10001",
    "event_date": "'"$(date -u -v+7d +"%Y-%m-%dT20:00:00.000Z")"'",
    "ticket_price": 35.00,
    "capacity": 300
  }'
```

### Event Details
- **Title**: NYC Rooftop Party - Summer Vibes
- **Location**: 230 5th Avenue Rooftop, New York, NY 10001
- **Ticket Price**: $35.00
- **Capacity**: 300
- **Date**: 7 days from now at 8:00 PM
- **Featured**: Yes

Once created, the event will appear in:
- Nearby events feed for partiers
- My Events for the creator (host)
- Event detail view with purchase option

## Testing
1. Open the app as a partier
2. Navigate to the feed/home screen
3. You should see "NYC Rooftop Party - Summer Vibes"
4. Click on it to view details
5. Click "Buy Ticket" or "RSVP" to test the purchase flow


