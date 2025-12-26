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

async function runMigrations() {
  try {
    console.log("🔄 Running database migrations...");
    
    const migrationFiles = [
      "001_initial_schema.sql",
      "002_add_user_fields.sql",
      "003_add_messaging_tables.sql",
      "004_add_social_features.sql",
      "005_add_event_promotions.sql",
      "006_add_reviews.sql",
      "007_add_event_talent_needs.sql",
      "008_add_role_to_messages.sql",
      "009_add_event_id_to_posts.sql",
      "010_add_group_chats.sql",
      "011_add_event_talent_table.sql",
      "012_add_brand_insights_tables.sql",
      "013_add_user_type_to_follows.sql",
      "014_add_earnings_tables.sql"
    ];
    
    for (const file of migrationFiles) {
      const filePath = path.join(__dirname, "migrations", file);
      const sql = fs.readFileSync(filePath, "utf8");
      
      console.log(`📄 Running ${file}...`);
      try {
        await db.query(sql);
        console.log(`✅ ${file} completed`);
      } catch (error) {
        // If table already exists, that's okay - continue
        if (error.message.includes("already exists") || error.message.includes("duplicate")) {
          console.log(`⚠️ ${file} - Some tables already exist, skipping...`);
        } else {
          throw error;
        }
      }
    }
    
    console.log("✅ All migrations completed successfully!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Migration error:", error.message);
    process.exit(1);
  }
}

runMigrations();

