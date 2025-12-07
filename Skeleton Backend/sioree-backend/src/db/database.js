import pg from "pg";
import dotenv from "dotenv";
dotenv.config();

// Parse connection string to determine SSL requirements
const isLocalDB = process.env.DATABASE_URL?.includes("localhost") || 
                  process.env.DATABASE_URL?.includes("127.0.0.1") ||
                  (!process.env.DATABASE_URL?.includes("supabase") && 
                   !process.env.DATABASE_URL?.includes("amazonaws"));

// Parse DATABASE_URL - ensure SSL mode and connection parameters are set correctly
// These parameters are CRITICAL for SCRAM authentication to complete and receive server signature
let databaseUrl = process.env.DATABASE_URL;
if (databaseUrl && databaseUrl.includes("supabase")) {
  console.log("📊 Using Supabase database connection");
  
  // For pooler connections, ensure proper connection parameters
  // The pgbouncer=true parameter is essential for Transaction Pooler to complete SCRAM handshake
  if (databaseUrl.includes("pooler")) {
    // Parse the URL to properly handle parameters
    try {
      const url = new URL(databaseUrl);
      const params = new URLSearchParams(url.search);
      
      // Set required parameters for pooler (critical for SCRAM authentication)
      // sslmode=require ensures SSL/TLS handshake completes first
      // pgbouncer=true tells the pooler to handle SCRAM authentication correctly
      // Without these, the server won't send its signature in the final SCRAM message
      params.set("sslmode", "require");
      params.set("pgbouncer", "true"); // CRITICAL: Required for Transaction Pooler SCRAM auth
      
      // Reconstruct URL with parameters
      url.search = params.toString();
      databaseUrl = url.toString();
      
      console.log(`📊 Database host: ${url.hostname}`);
      console.log(`📊 Database port: ${url.port || '5432'}`);
      console.log("📊 Using pooler connection with pgbouncer=true and sslmode=require");
      console.log("📊 These parameters ensure SCRAM authentication completes with server signature");
    } catch (e) {
      // Fallback: manual string manipulation if URL parsing fails
      console.log("📊 Using fallback URL parsing");
      const params = new URLSearchParams();
      if (databaseUrl.includes("?")) {
        const existingParams = databaseUrl.split("?")[1];
        const existing = new URLSearchParams(existingParams);
        existing.forEach((value, key) => params.set(key, value));
      }
      
      // CRITICAL: These parameters ensure the server sends its signature
      params.set("sslmode", "require");
      params.set("pgbouncer", "true");
      
      const baseUrl = databaseUrl.split("?")[0];
      databaseUrl = `${baseUrl}?${params.toString()}`;
      console.log("📊 Using pooler connection with pgbouncer=true and sslmode=require (fallback)");
      console.log("📊 These parameters ensure SCRAM authentication completes with server signature");
    }
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
  connectionTimeoutMillis: 15000, // Increased to 15 seconds for network latency
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
  // Additional options for better connection handling
  allowExitOnIdle: false,
  // Ensure proper SSL/TLS handshake for SCRAM authentication
  application_name: 'sioree-backend',
};

// Always add SSL config for Supabase (required)
// Supabase uses self-signed certificates, so we need to disable certificate validation
// This is critical for SCRAM authentication to complete - the SSL handshake must succeed
// before the SCRAM authentication handshake can complete and receive the server signature
const isSupabase = process.env.DATABASE_URL?.includes("supabase") || databaseUrl?.includes("supabase");
if (isSupabase || !isLocalDB) {
  // For pooler connections, SSL is handled via connection string parameters
  // But we still need to configure the SSL object for the pg library
  // The SSL configuration ensures the TLS handshake completes, allowing SCRAM to proceed
  if (databaseUrl?.includes("pooler")) {
    // Pooler connections handle SSL via connection string, but we still need this for pg library
    // This ensures the full SSL/TLS handshake completes so SCRAM can receive server signature
    poolConfig.ssl = {
      rejectUnauthorized: false, // Accept self-signed certificates
      // Ensure SSL connection is established before SCRAM authentication
      require: true
    };
    console.log("🔒 SSL configured for pooler connection - ensures SCRAM authentication can complete");
  } else {
    poolConfig.ssl = {
      rejectUnauthorized: false, // CRITICAL: Accept self-signed certificates for Supabase
      require: true // Ensure SSL is required
    };
    console.log("🔒 SSL configured with rejectUnauthorized: false for Supabase connection");
  }
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


