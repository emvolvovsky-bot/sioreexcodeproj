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

// Parse connection string to determine SSL requirements
const isLocalDB = process.env.DATABASE_URL?.includes("localhost") || 
                  process.env.DATABASE_URL?.includes("127.0.0.1") ||
                  (!process.env.DATABASE_URL?.includes("supabase") && 
                   !process.env.DATABASE_URL?.includes("amazonaws"));

// Use connection pool for better performance and error handling
const poolConfig = {
  connectionString: process.env.DATABASE_URL,
  max: 20,                  // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Return an error after 10 seconds if connection could not be established
};

// Only add SSL config for remote databases
if (!isLocalDB && process.env.DATABASE_URL) {
  poolConfig.ssl = {
    rejectUnauthorized: false // Accept self-signed certificates for Supabase / managed Postgres
  };
}

const pool = new pg.Pool(poolConfig);

// Test connection
pool.query("SELECT NOW()")
  .then(() => console.log("✅ Database pool connected"))
  .catch(err => {
    console.error("❌ Database connection error:", err.message);
    if (!process.env.DATABASE_URL) {
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


