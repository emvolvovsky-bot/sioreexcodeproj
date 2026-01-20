import fs from "fs";
import path from "path";
import { db } from "../src/db/database.js";

const OUTPUT_DIR = path.resolve(process.cwd(), "exports");
const OUTPUT_FILE = path.join(OUTPUT_DIR, "users-events.csv");

const columns = [
  "user_id",
  "username",
  "email",
  "name",
  "bio",
  "avatar",
  "user_type",
  "location",
  "verified",
  "follower_count",
  "following_count",
  "event_count",
  "created_at",
  "updated_at",
  "upcoming_events_created_count",
  "upcoming_events_created",
  "upcoming_events_attending_count",
  "upcoming_events_attending",
];

const query = `
  SELECT
    u.id AS user_id,
    u.username,
    u.email,
    u.name,
    u.bio,
    u.avatar,
    u.user_type,
    u.location,
    u.verified,
    u.follower_count,
    u.following_count,
    u.event_count,
    u.created_at,
    u.updated_at,
    COALESCE(created_events.upcoming_count, 0) AS upcoming_events_created_count,
    COALESCE(created_events.upcoming_events, '') AS upcoming_events_created,
    COALESCE(attending_events.upcoming_count, 0) AS upcoming_events_attending_count,
    COALESCE(attending_events.upcoming_events, '') AS upcoming_events_attending
  FROM users u
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) AS upcoming_count,
      STRING_AGG(
        e.id || ':' || e.title || '|' || TO_CHAR(e.event_date, 'YYYY-MM-DD"T"HH24:MI:SS'),
        '; ' ORDER BY e.event_date
      ) AS upcoming_events
    FROM events e
    WHERE e.creator_id = u.id AND e.event_date >= NOW()
  ) created_events ON true
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) AS upcoming_count,
      STRING_AGG(
        e.id || ':' || e.title || '|' || TO_CHAR(e.event_date, 'YYYY-MM-DD"T"HH24:MI:SS'),
        '; ' ORDER BY e.event_date
      ) AS upcoming_events
    FROM event_attendees ea
    JOIN events e ON e.id = ea.event_id
    WHERE ea.user_id = u.id AND e.event_date >= NOW()
  ) attending_events ON true
  ORDER BY u.id;
`;

const csvEscape = (value) => {
  if (value === null || value === undefined) return "";
  let stringValue;
  if (value instanceof Date) {
    stringValue = value.toISOString();
  } else if (typeof value === "boolean") {
    stringValue = value ? "true" : "false";
  } else {
    stringValue = String(value);
  }
  if (stringValue.includes('"') || stringValue.includes(",") || stringValue.includes("\n")) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }
  return stringValue;
};

const writeCsv = (rows) => {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const header = columns.join(",");
  const lines = rows.map((row) =>
    columns.map((column) => csvEscape(row[column])).join(",")
  );
  fs.writeFileSync(OUTPUT_FILE, [header, ...lines].join("\n"), "utf8");
};

const exportOnce = async () => {
  const result = await db.query(query);
  writeCsv(result.rows);
  console.log(`✅ CSV exported: ${OUTPUT_FILE}`);
};

const isWatchMode =
  process.argv.includes("--watch") || process.env.CSV_WATCH === "true";
const refreshSeconds = Number(process.env.CSV_REFRESH_SECONDS || 60);
const refreshMs = Number.isFinite(refreshSeconds) && refreshSeconds > 0
  ? refreshSeconds * 1000
  : 60000;

const shutdown = async () => {
  try {
    await db.pool.end();
  } catch (error) {
    console.error("❌ Failed to close DB pool:", error);
  } finally {
    process.exit(0);
  }
};

const start = async () => {
  try {
    await exportOnce();
  } catch (error) {
    console.error("❌ Failed to export CSV:", error);
    if (!isWatchMode) {
      process.exitCode = 1;
      await shutdown();
    }
  }

  if (!isWatchMode) {
    await shutdown();
    return;
  }

  console.log(`🔁 Refreshing every ${Math.round(refreshMs / 1000)}s`);
  const interval = setInterval(() => {
    exportOnce().catch((error) => {
      console.error("❌ Failed to export CSV:", error);
    });
  }, refreshMs);

  const handleExit = () => {
    clearInterval(interval);
    shutdown();
  };
  process.on("SIGINT", handleExit);
  process.on("SIGTERM", handleExit);
};

start();

