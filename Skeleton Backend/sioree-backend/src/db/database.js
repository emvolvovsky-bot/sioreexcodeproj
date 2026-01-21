import pg from "pg";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";

const candidateEnvPaths = [
  path.resolve(process.cwd(), ".env"),
  path.resolve(process.cwd(), "..", "..", ".env"),
  path.resolve(process.cwd(), "Skeleton Backend/sioree-backend/.env")
];

let loadedEnvPath = null;
for (const envPath of candidateEnvPaths) {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
    loadedEnvPath = envPath;
    break;
  }
}

if (!loadedEnvPath) {
  dotenv.config();
}

// Parse connection string to determine SSL requirements
const isLocalDB = process.env.DATABASE_URL?.includes("localhost") || 
                  process.env.DATABASE_URL?.includes("127.0.0.1") ||
                  (!process.env.DATABASE_URL?.includes("supabase") && 
                   !process.env.DATABASE_URL?.includes("amazonaws") &&
                   !process.env.DATABASE_URL?.includes("neon.tech"));

// Parse DATABASE_URL - ensure SSL mode and connection parameters are set correctly
// These parameters are CRITICAL for SCRAM authentication to complete and receive server signature
let databaseUrl = process.env.DATABASE_URL;

// 🔧 Neon compatibility: add missing project options to avoid "Tenant or user not found"
try {
  if (databaseUrl && databaseUrl.includes(".neon.tech") && !databaseUrl.includes("options=")) {
    const url = new URL(databaseUrl);
    // Neon expects options=project%3D<projectId> where projectId is the host prefix (ep-xxxxx)
    const projectId = url.hostname.split(".")[0];
    const params = new URLSearchParams(url.search);
    params.set("options", `project%3D${projectId}`);
    // Always require SSL for Neon
    if (!params.has("sslmode")) {
      params.set("sslmode", "require");
    }
    url.search = params.toString();
    databaseUrl = url.toString();
    console.log(`🔧 Added Neon project options to connection string (project: ${projectId})`);
  }
} catch (e) {
  console.warn("⚠️ Neon URL adjustment skipped:", e.message);
}
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
      // Transaction Pooler (port 6543) does NOT need pgbouncer=true
      // pgbouncer=true is only for Session Pooler
      params.set("sslmode", "require");
      
      // Remove pgbouncer if present - Transaction Pooler doesn't use it
      // This was causing SCRAM authentication failures
      if (params.has("pgbouncer")) {
        params.delete("pgbouncer");
        console.log("📊 Removed pgbouncer parameter (not needed for Transaction Pooler)");
      }
      
      // Reconstruct URL with parameters
      url.search = params.toString();
      databaseUrl = url.toString();
      
      // Log database info without exposing sensitive details
      const hostname = url.hostname.includes("supabase") ? "supabase.co" : url.hostname.split(".").slice(-2).join(".");
      console.log(`📊 Database host: ${hostname}`);
      console.log(`📊 Database port: ${url.port || '5432'}`);
      console.log(`📊 Database user: ${url.username ? "***" : "Not set"}`);
      // Don't log connection parameters as they may contain sensitive info
      
      // Transaction Pooler vs Session Pooler
      if (url.port === "6543" || url.port === 6543) {
        console.log("📊 Using Transaction Pooler (port 6543)");
        console.log("📊 Transaction Pooler: sslmode=require is required");
        console.log("📊 Note: pgbouncer=true is for Session Pooler, not Transaction Pooler");
      } else {
        console.log("📊 Using Session Pooler");
        if (!params.has("pgbouncer")) {
          params.set("pgbouncer", "true");
          url.search = params.toString();
          databaseUrl = url.toString();
        }
        console.log("📊 Session Pooler: pgbouncer=true and sslmode=require required");
      }
      
      // Verify critical parameters are present
      if (!params.has("sslmode") || params.get("sslmode") !== "require") {
        console.error("⚠️ WARNING: sslmode=require parameter is missing or incorrect!");
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
      
      // CRITICAL: sslmode=require is always needed
      params.set("sslmode", "require");
      
      // For Transaction Pooler (port 6543), don't add pgbouncer=true
      // For Session Pooler, add pgbouncer=true
      const portMatch = databaseUrl.match(/:(\d+)\//);
      const port = portMatch ? portMatch[1] : "6543";
      if (port !== "6543") {
        params.set("pgbouncer", "true");
      }
      
      const baseUrl = databaseUrl.split("?")[0];
      databaseUrl = `${baseUrl}?${params.toString()}`;
      console.log("📊 Using pooler connection with sslmode=require (fallback)");
      if (params.has("pgbouncer")) {
        console.log("📊 Session Pooler: pgbouncer=true added");
      } else {
        console.log("📊 Transaction Pooler: pgbouncer not needed");
      }
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
  console.log("🔌 Attempting to connect to database...");
  console.log(`📊 Database URL configured: ${databaseUrl ? "Yes" : "No"}`);
  if (databaseUrl) {
    try {
      const url = new URL(databaseUrl);
      console.log(`📊 Database host: ${url.hostname}`);
      console.log(`📊 Database port: ${url.port || '5432'}`);
      console.log(`📊 Database user: ${url.username}`);
    } catch (e) {
      console.log("📊 Could not parse database URL");
    }
  }
  
  for (let i = 0; i < retries; i++) {
    try {
      const result = await Promise.race([
        pool.query("SELECT NOW()"),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error("Connection timeout")), 10000)
        )
      ]);
      console.log("═══════════════════════════════════════════════════════════");
      console.log("✅ DATABASE CONNECTED SUCCESSFULLY");
      console.log(`📊 Database time: ${result.rows[0].now}`);
      console.log(`📊 Connection pool: ${pool.totalCount} total, ${pool.idleCount} idle, ${pool.waitingCount} waiting`);
      console.log("═══════════════════════════════════════════════════════════");
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
        
        // Log connection string info (without password or sensitive details)
        if (databaseUrl) {
          try {
            const url = new URL(databaseUrl);
            const hostname = url.hostname.includes("supabase") ? "supabase.co" : url.hostname.split(".").slice(-2).join(".");
            console.error(`📋 Connection string check:`);
            console.error(`   Host: ${hostname}`);
            console.error(`   Port: ${url.port || '5432'}`);
            console.error(`   User: ${url.username ? "***" : "Not set"}`);
            console.error(`   Has password: ${url.password ? 'Yes' : 'NO - THIS IS THE PROBLEM!'}`);
            // Don't log search parameters as they may contain sensitive info
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

// Provide both named and default exports for compatibility with existing imports
export { db };
export default db;


