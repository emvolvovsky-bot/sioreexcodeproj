import pg from "pg";
import dotenv from "dotenv";
dotenv.config();

// Parse connection string to determine SSL requirements
const isLocalDB = process.env.DATABASE_URL?.includes("localhost") || 
                  process.env.DATABASE_URL?.includes("127.0.0.1") ||
                  (!process.env.DATABASE_URL?.includes("supabase") && 
                   !process.env.DATABASE_URL?.includes("amazonaws"));

// Parse DATABASE_URL - ensure SSL mode and connection parameters are set correctly
let databaseUrl = process.env.DATABASE_URL;
if (databaseUrl && databaseUrl.includes("supabase")) {
  console.log("📊 Using Supabase database connection");
  // Log connection details (without exposing password)
  try {
    const urlParts = new URL(databaseUrl);
    console.log(`📊 Database host: ${urlParts.hostname}`);
    console.log(`📊 Database port: ${urlParts.port || '5432'}`);
  } catch (e) {
    console.log("📊 Database URL format check");
  }
  
  // For pooler connections, ensure proper connection parameters
  if (databaseUrl.includes("pooler")) {
    // Pooler connections need specific parameters
    const params = new URLSearchParams();
    if (databaseUrl.includes("?")) {
      const existingParams = databaseUrl.split("?")[1];
      const existing = new URLSearchParams(existingParams);
      existing.forEach((value, key) => params.set(key, value));
    }
    
    // Set required parameters for pooler (these are critical for SCRAM authentication)
    if (!params.has("sslmode")) {
      params.set("sslmode", "require");
    }
    if (!params.has("pgbouncer")) {
      params.set("pgbouncer", "true"); // Critical for pooler connections
    }
    
    const baseUrl = databaseUrl.split("?")[0];
    databaseUrl = `${baseUrl}?${params.toString()}`;
    console.log("📊 Using pooler connection with pgbouncer=true and sslmode=require");
  } else {
    // For direct connections, just ensure sslmode=require
    if (!databaseUrl.includes("sslmode=")) {
      databaseUrl += (databaseUrl.includes("?") ? "&" : "?") + "sslmode=require";
    }
  }
}

// Use connection pool for better performance and error handling
const poolConfig = {
  connectionString: databaseUrl || process.env.DATABASE_URL,
  max: 15, // Reduced for pooler connections (Supabase pooler limit)
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Increased to 10 seconds for network latency
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
  // For pooler connections, we need to use transaction mode
  statement_timeout: 30000, // 30 second statement timeout
};

// Always add SSL config for Supabase (required)
// Supabase uses self-signed certificates, so we need to disable certificate validation
const isSupabase = process.env.DATABASE_URL?.includes("supabase") || databaseUrl?.includes("supabase");
if (isSupabase || !isLocalDB) {
  poolConfig.ssl = {
    rejectUnauthorized: false // CRITICAL: Accept self-signed certificates for Supabase
  };
  console.log("🔒 SSL configured with rejectUnauthorized: false for Supabase connection");
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


