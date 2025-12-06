# Easy Way to Create NYC Test Event

## Option 1: Use the Shell Script (Easiest!)

I've created a simple script that will create the event for you. Just run:

```bash
cd "/Users/evolvovsky26/Creative Cloud Files/Mobile App Design/Sioree XCode Project"
./create-nyc-event.sh
```

The script will:
1. Ask for your email and password
2. Log you in automatically
3. Create the NYC event
4. Show you the result

**Make sure your backend server is running first!**

---

## Option 2: Create Event Through the App (Even Easier!)

1. **Open your iOS app**
2. **Log in as a host user** (or create a host account)
3. **Go to "My Events"** or the "Create" tab
4. **Click "Create Event"**
5. **Fill in the details:**
   - **Title**: NYC Rooftop Party - Summer Vibes
   - **Description**: Join us for an epic rooftop party in the heart of New York City! Experience breathtaking skyline views, world-class DJs, premium cocktails, and an unforgettable night under the stars.
   - **Location**: 230 5th Avenue Rooftop, New York, NY 10001
   - **Date**: Pick a date 7 days from now
   - **Time**: 8:00 PM
   - **Ticket Price**: $35.00
   - **Capacity**: 300
6. **Click "Create"**

That's it! The event will be live immediately and visible to all users.

---

## Option 3: Manual cURL Command

If you prefer to use curl directly:

```bash
# Step 1: Login (replace with your credentials)
curl -X POST http://192.168.1.200:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'

# Copy the "token" from the response, then:

# Step 2: Create event (replace YOUR_TOKEN with the token from step 1)
curl -X POST http://192.168.1.200:4000/api/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "NYC Rooftop Party - Summer Vibes",
    "description": "Join us for an epic rooftop party in the heart of New York City! Experience breathtaking skyline views, world-class DJs, premium cocktails, and an unforgettable night under the stars.",
    "location": "230 5th Avenue Rooftop, New York, NY 10001",
    "event_date": "2024-12-25T20:00:00.000Z",
    "ticket_price": 35.00,
    "capacity": 300
  }'
```

---

## Event Details

- **Title**: NYC Rooftop Party - Summer Vibes
- **Location**: 230 5th Avenue Rooftop, New York, NY 10001
- **Ticket Price**: $35.00
- **Capacity**: 300 people
- **Date**: 7 days from now at 8:00 PM

## Testing

After creating the event:
1. Open the app as a **partier** user
2. Go to the **home/feed** screen
3. You should see "NYC Rooftop Party - Summer Vibes"
4. Click on it to view details
5. Click "Buy Ticket" or "RSVP" to test the purchase flow

---

**Recommendation**: Use **Option 2** (create through the app) - it's the easiest and you can see it working immediately! 🎉


