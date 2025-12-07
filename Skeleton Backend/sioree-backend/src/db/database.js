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
      // For Transaction Pooler, pgbouncer=true is required
      // However, Transaction Pooler has known SCRAM issues - try without pgbouncer first
      // If that fails, the password might be the issue
      params.set("sslmode", "require");
      
      // For Transaction Pooler, pgbouncer=true can sometimes cause SCRAM issues
      // Try with it first, but if it fails, the password is likely incorrect
      // Transaction Pooler should work with just sslmode=require
      if (!params.has("pgbouncer")) {
        params.set("pgbouncer", "true");
      }
      
      // Reconstruct URL with parameters
      url.search = params.toString();
      databaseUrl = url.toString();
      
      console.log(`📊 Database host: ${url.hostname}`);
      console.log(`📊 Database port: ${url.port || '5432'}`);
      console.log(`📊 Database user: ${url.username}`);
      console.log(`📊 Connection parameters: ${params.toString()}`);
      console.log("📊 Using pooler connection with pgbouncer=true and sslmode=require");
      console.log("📊 These parameters ensure SCRAM authentication completes with server signature");
      
      // Verify critical parameters are present
      if (!params.has("pgbouncer") || params.get("pgbouncer") !== "true") {
        console.error("⚠️ WARNING: pgbouncer parameter is missing or incorrect!");
      }
      if (!params.has("sslmode") || params.get("sslmode") !== "require") {
        console.error("⚠️ WARNING: sslmode parameter is missing or incorrect!");
      }
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
// For Transaction Pooler, we need to be careful with connection settings
const poolConfig = {
  connectionString: databaseUrl || process.env.DATABASE_URL,
  max: 15, // Reduced for pooler connections (Supabase pooler limit)
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 20000, // Increased to 20 seconds for network latency
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
  // Additional options for better connection handling
  allowExitOnIdle: false,
  // Ensure proper SSL/TLS handshake for SCRAM authentication
  application_name: 'sioree-backend',
  // For Transaction Pooler, ensure we don't use prepared statements in transaction mode
  // This helps with SCRAM authentication
  statement_timeout: 30000,
};

// Always add SSL config for Supabase (required)
// Supabase uses self-signed certificates, so we need to disable certificate validation
// This is critical for SCRAM authentication to complete - the SSL handshake must succeed
// before the SCRAM authentication handshake can complete and receive the server signature
const isSupabase = process.env.DATABASE_URL?.includes("supabase") || databaseUrl?.includes("supabase");
if (isSupabase || !isLocalDB) {
  // For pooler connections, SSL is handled via connection string parameters (sslmode=require)
  // For Transaction Pooler, we need to ensure SSL is properly configured
  if (databaseUrl?.includes("pooler")) {
    // Transaction Pooler requires specific SSL configuration
    // We need to allow self-signed certificates but let the connection string control SSL mode
    poolConfig.ssl = {
      rejectUnauthorized: false // Accept self-signed certificates
      // Note: sslmode=require in connection string handles SSL requirement
      // Setting require: true here can conflict with Transaction Pooler
    };
    console.log("🔒 SSL configured for Transaction Pooler (rejectUnauthorized: false)");
    console.log("🔒 SSL mode controlled by connection string parameter: sslmode=require");
  } else {
    // For direct connections, configure SSL explicitly
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
      console.error(`❌ Error code: ${err.code || 'N/A'}`);
      console.error(`❌ Error details:`, {
        errno: err.errno,
        syscall: err.syscall,
        address: err.address,
        port: err.port
      });
      
      // For SCRAM errors, provide specific guidance
      if (err.message.includes("SCRAM") || err.message.includes("server signature")) {
        console.error("⚠️ SCRAM Authentication Error - Common causes:");
        console.error("   1. Incorrect database password in DATABASE_URL");
        console.error("   2. Password contains special characters that need URL encoding");
        console.error("   3. Missing pgbouncer=true parameter (should be auto-added)");
        console.error("   4. Missing sslmode=require parameter (should be auto-added)");
        console.error("   5. Connection string format is incorrect");
        
        // Log connection string info (without password)
        if (databaseUrl) {
          try {
            const url = new URL(databaseUrl);
            console.error(`📋 Connection string check:`);
            console.error(`   Host: ${url.hostname}`);
            console.error(`   Port: ${url.port}`);
            console.error(`   User: ${url.username}`);
            console.error(`   Has password: ${url.password ? 'Yes' : 'NO - THIS IS THE PROBLEM!'}`);
            console.error(`   Parameters: ${url.search}`);
          } catch (e) {
            console.error(`   Could not parse connection string`);
          }
        }
      }
      
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
          console.error("⚠️ Verify your database password is correct and URL-encoded if needed");
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


