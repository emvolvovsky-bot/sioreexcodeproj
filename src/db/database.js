import pg from "pg";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";

const candidateEnvPaths = [
  path.resolve(process.cwd(), ".env"),
  path.resolve(process.cwd(), "backend/.env"),
  path.resolve(process.cwd(), "Skeleton Backend/sioree-backend/.env"),
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

// Use DATABASE_URL for direct Postgres access (Render Postgres)
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error("❌ DATABASE_URL environment variable is not set! Backend requires Render Postgres.");
}

// Determine if the DB is local (simple check)
const isLocalDB = databaseUrl?.includes("localhost") || databaseUrl?.includes("127.0.0.1");

// Use connection pool for better performance and error handling
const poolConfig = {
  connectionString: databaseUrl,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
};

// Add SSL config for remote databases (e.g. Render Postgres)
if (!isLocalDB && databaseUrl) {
  poolConfig.ssl = { rejectUnauthorized: false };
}

const pool = new pg.Pool(poolConfig);

// Startup log: print DB host and masked credentials so we can confirm host (e.g. render.com)
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
pool.query("SELECT NOW()")
  .then(() => console.log("✅ Database pool connected"))
  .catch(err => {
    console.error("❌ Database connection error:", err.message);
    if (!databaseUrl) {
      console.error("⚠️ DATABASE_URL environment variable is not set!");
      console.error("   Tried env files:", candidateEnvPaths.join(", "));
    }
  });

// Export pool with query method for compatibility
const db = {
  query: (text, params) => pool.query(text, params),
  pool: pool
};

// IMPORTANT: named export 'db' so that `import { db } from "../db/database.js"` works
export { db };


