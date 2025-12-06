import pg from "pg";
import dotenv from "dotenv";
dotenv.config();

const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function createTestEvent() {
  try {
    await client.connect();
    console.log("✅ Connected to database");

    // Get first user (or create one if none exists)
    let userResult = await client.query("SELECT id FROM users LIMIT 1");
    
    if (userResult.rows.length === 0) {
      console.log("⚠️ No users found. Please create a user first by signing up in the app.");
      process.exit(1);
    }

    const userId = userResult.rows[0].id;
    console.log(`📝 Using user ID: ${userId}`);

    // Create a test event
    const eventDate = new Date();
    eventDate.setDate(eventDate.getDate() + 7); // 7 days from now
    eventDate.setHours(20, 0, 0, 0); // 8 PM

    const result = await client.query(
      `INSERT INTO events (creator_id, title, description, location, event_date, ticket_price, capacity, is_featured)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id`,
      [
        userId,
        "NYC Rooftop Party - Summer Vibes",
        "Join us for an epic rooftop party in the heart of New York City! Experience breathtaking skyline views, world-class DJs, premium cocktails, and an unforgettable night under the stars. This is the party you don't want to miss!",
        "230 5th Avenue Rooftop, New York, NY 10001",
        eventDate.toISOString(),
        35.00, // $35 ticket price
        300, // Capacity of 300
        true // Featured
      ]
    );

    const eventId = result.rows[0].id;
    console.log(`✅ Created test event with ID: ${eventId}`);
    console.log(`📅 Event Date: ${eventDate.toLocaleString()}`);
    console.log(`📍 Location: 230 5th Avenue Rooftop, New York, NY 10001`);
    console.log(`💰 Ticket Price: $35.00`);
    console.log(`👥 Capacity: 300`);
    console.log(`\n🎉 NYC test event is now live! Users can see it and purchase tickets.`);

    await client.end();
  } catch (err) {
    console.error("❌ Error creating test event:", err);
    process.exit(1);
  }
}

createTestEvent();

