import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import db from "../db/database.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigrations() {
  try {
    const migrationsDir = path.join(__dirname, "../../migrations");
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith(".sql"))
      .sort();

    console.log("Running migrations...");

    for (const file of files) {
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, "utf8");
      
      console.log(`Running migration: ${file}`);
      await db.query(sql);
      console.log(`✅ Completed: ${file}`);
    }

    console.log("All migrations completed!");
  } catch (err) {
    console.error("Migration error:", err);
    throw err;
  }
}

runMigrations()
  .then(() => {
    console.log("Migrations finished successfully");
    process.exit(0);
  })
  .catch(err => {
    console.error("Migration failed:", err);
    process.exit(1);
  });


