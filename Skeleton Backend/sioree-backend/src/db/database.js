import pg from "pg";
import dotenv from "dotenv";
dotenv.config();

// Parse connection string to determine SSL requirements
const isLocalDB = process.env.DATABASE_URL?.includes("localhost") || 
                  process.env.DATABASE_URL?.includes("127.0.0.1") ||
                  (!process.env.DATABASE_URL?.includes("supabase") && 
                   !process.env.DATABASE_URL?.includes("amazonaws"));

// Parse DATABASE_URL and ensure it uses IPv4 if needed
let databaseUrl = process.env.DATABASE_URL;
if (databaseUrl && databaseUrl.includes("supabase")) {
  // Force IPv4 by replacing IPv6 hostname with IPv4 if present
  // Supabase connection strings should use the pooler or direct connection
  // If the URL contains an IPv6 address, we might need to use the pooler endpoint
  if (!databaseUrl.includes("pooler") && !databaseUrl.includes(":5432")) {
    // Ensure we're using the pooler for better connection handling
    databaseUrl = databaseUrl.replace(/@([^:]+):5432/, '@$1.pooler.supabase.com:6543');
  }
}

// Use connection pool for better performance and error handling
const poolConfig = {
  connectionString: databaseUrl || process.env.DATABASE_URL,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Increased to 10 seconds for network latency
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
};

// Always add SSL config for Supabase (required)
if (process.env.DATABASE_URL?.includes("supabase") || !isLocalDB) {
  poolConfig.ssl = {
    rejectUnauthorized: false // Accept self-signed certificates for Supabase
  };
}

const pool = new pg.Pool(poolConfig);

// Test connection with timeout and retry logic
const testConnection = async (retries = 3) => {
  for (let i = 0; i < retries; i++) {
    try {
      const result = await Promise.race([
        pool.query("SELECT NOW()"),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error("Connection timeout")), 10000)
        )
      ]);
      console.log("✅ Database pool connected");
      return;
    } catch (err) {
      console.error(`❌ Database connection attempt ${i + 1}/${retries} failed:`, err.message);
      if (i < retries - 1) {
        console.log(`⏳ Retrying in 2 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      } else {
        console.error("❌ Database connection error:", err.message);
        if (!process.env.DATABASE_URL) {
          console.error("⚠️ DATABASE_URL environment variable is not set!");
        } else {
          console.error("⚠️ Check your DATABASE_URL connection string");
          console.error("⚠️ Make sure your Supabase database allows connections from Render's IP addresses");
        }
      }
    }
  }
};

testConnection();

// Export pool with query method for compatibility
const db = {
  query: (text, params) => pool.query(text, params),
  pool: pool
};

export default db;


