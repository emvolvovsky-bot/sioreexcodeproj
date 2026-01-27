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

// Simplified DB connection that uses process.env.DATABASE_URL (Render Postgres)
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error("❌ DATABASE_URL environment variable is not set! Backend requires Render Postgres.");
}

const isLocalDB = databaseUrl?.includes("localhost") || databaseUrl?.includes("127.0.0.1");

const poolConfig = {
  connectionString: databaseUrl,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000,
  application_name: "sioree-backend",
};

if (!isLocalDB && databaseUrl) {
  poolConfig.ssl = { rejectUnauthorized: false };
}

const pool = new pg.Pool(poolConfig);

// Startup log: print DB host and masked credentials
try {
  if (databaseUrl) {
    const url = new URL(databaseUrl);
    const maskedPassword = url.password ? "***REDACTED***" : "(no password)";
    console.log(`🔌 Database host: ${url.hostname}`);
    console.log(`🔌 Database port: ${url.port || "5432"}`);
    console.log(`🔌 Database user: ${url.username || "(not set)"}`);
    console.log(`🔌 Database password: ${maskedPassword}`);
    if (url.hostname && url.hostname.includes("render.com")) {
      console.log("🔁 Using Render Postgres as the database host.");
    }
  }
} catch (e) {
  console.warn("⚠️ Could not parse DATABASE_URL for startup logging:", e.message);
}

// Test connection
const testConnection = async (retries = 3) => {
  console.log("🔌 Attempting to connect to database...");
  for (let i = 0; i < retries; i++) {
    try {
      const result = await Promise.race([
        pool.query("SELECT NOW()"),
        new Promise((_, reject) => setTimeout(() => reject(new Error("Connection timeout")), 10000))
      ]);
      console.log("✅ DATABASE CONNECTED SUCCESSFULLY");
      console.log(`📊 Database time: ${result.rows[0].now}`);
      console.log(`📊 Connection pool: ${pool.totalCount} total, ${pool.idleCount} idle, ${pool.waitingCount} waiting`);
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


