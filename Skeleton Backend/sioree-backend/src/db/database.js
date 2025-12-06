import pg from "pg";
import dotenv from "dotenv";
dotenv.config();

// Parse connection string to determine SSL requirements
const isLocalDB = process.env.DATABASE_URL?.includes("localhost") || 
                  process.env.DATABASE_URL?.includes("127.0.0.1") ||
                  (!process.env.DATABASE_URL?.includes("supabase") && 
                   !process.env.DATABASE_URL?.includes("amazonaws"));

// Use connection pool for better performance and error handling
const poolConfig = {
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 5000, // Return an error after 5 seconds if connection could not be established
};

// Always add SSL config for Supabase (required)
if (process.env.DATABASE_URL?.includes("supabase") || !isLocalDB) {
  poolConfig.ssl = {
    rejectUnauthorized: false // Accept self-signed certificates for Supabase
  };
}

const pool = new pg.Pool(poolConfig);

// Test connection with timeout
const testConnection = async () => {
  try {
    const result = await Promise.race([
      pool.query("SELECT NOW()"),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error("Connection timeout")), 5000)
      )
    ]);
    console.log("✅ Database pool connected");
  } catch (err) {
    console.error("❌ Database connection error:", err.message);
    if (!process.env.DATABASE_URL) {
      console.error("⚠️ DATABASE_URL environment variable is not set!");
    } else {
      console.error("⚠️ Check your DATABASE_URL connection string");
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


