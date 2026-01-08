import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import db from "./src/db/database.js";
import dotenv from "dotenv";

dotenv.config();

// Set SSL rejection for migrations
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runGroupChatMigration() {
  try {
    console.log("🔄 Running group chat migration...");
    
    const migrationPath = path.join(__dirname, "migrations", "010_add_group_chats.sql");
    const sql = fs.readFileSync(migrationPath, "utf8");
    
    console.log(`📄 Running 010_add_group_chats.sql...`);
    await db.query(sql);
    console.log(`✅ Migration completed successfully!`);
    
    process.exit(0);
  } catch (error) {
    // If table already exists, that's okay - continue
    if (error.message.includes("already exists") || 
        error.message.includes("duplicate") ||
        error.message.includes("already exists")) {
      console.log(`⚠️ Migration already applied (or partially), continuing...`);
      console.log(`✅ Migration check completed`);
      process.exit(0);
    } else {
      console.error("❌ Migration error:", error.message);
      console.error(error);
      process.exit(1);
    }
  }
}

runGroupChatMigration();

