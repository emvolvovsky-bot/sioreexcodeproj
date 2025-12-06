#!/bin/bash

# Script to create NYC test event via API
# Make sure your backend is running first!

BASE_URL="http://192.168.1.200:4000/api"

echo "🎉 Creating NYC Test Event..."
echo ""
echo "Please enter your login credentials:"
read -p "Email: " EMAIL
read -sp "Password: " PASSWORD
echo ""

# Login to get token
echo "🔐 Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

# Extract token (basic extraction - assumes JSON response)
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed. Please check your credentials."
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Logged in successfully!"
echo ""

# Calculate date 7 days from now (works on macOS)
EVENT_DATE=$(date -u -v+7d +"%Y-%m-%dT20:00:00.000Z" 2>/dev/null || date -u -d "+7 days" +"%Y-%m-%dT20:00:00.000Z" 2>/dev/null || python3 -c "from datetime import datetime, timedelta; print((datetime.utcnow() + timedelta(days=7)).strftime('%Y-%m-%dT20:00:00.000Z'))")

echo "📅 Event Date: $EVENT_DATE"
echo ""

# Create event
echo "🎪 Creating NYC Rooftop Party event..."
CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"title\": \"NYC Rooftop Party - Summer Vibes\",
    \"description\": \"Join us for an epic rooftop party in the heart of New York City! Experience breathtaking skyline views, world-class DJs, premium cocktails, and an unforgettable night under the stars. This is the party you don't want to miss!\",
    \"location\": \"230 5th Avenue Rooftop, New York, NY 10001\",
    \"event_date\": \"$EVENT_DATE\",
    \"ticket_price\": 35.00,
    \"capacity\": 300
  }")

echo ""
echo "📦 Response:"
echo "$CREATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESPONSE"
echo ""

if echo "$CREATE_RESPONSE" | grep -q "error"; then
  echo "❌ Failed to create event. Check the error above."
else
  echo "✅ NYC Test Event created successfully!"
  echo "📍 Location: 230 5th Avenue Rooftop, New York, NY 10001"
  echo "💰 Ticket Price: \$35.00"
  echo "👥 Capacity: 300"
  echo ""
  echo "🎉 The event is now live! Users can see it and purchase tickets."
fi


