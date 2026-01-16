import csv
import os
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

import psycopg2

OUTPUT_DIR = Path.cwd() / "exports"
OUTPUT_FILE = OUTPUT_DIR / "users-events.csv"

COLUMNS = [
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
]

QUERY = """
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
"""


ALLOWED_QUERY_KEYS = {"sslmode", "connect_timeout", "application_name", "options"}


def normalize_database_url(database_url: str) -> str:
    parsed = urlparse(database_url)
    query_params = parse_qs(parsed.query)
    filtered_params = {
        key: value
        for key, value in query_params.items()
        if key in ALLOWED_QUERY_KEYS
    }
    normalized_query = urlencode(filtered_params, doseq=True)
    return urlunparse(parsed._replace(query=normalized_query))


def resolve_ssl_mode(database_url: str) -> str:
    hostname = urlparse(database_url).hostname or ""
    is_local = hostname in {"localhost", "127.0.0.1"} or (
        "supabase" not in database_url and "amazonaws" not in database_url
    )
    return "disable" if is_local else "require"


def sanitize_row(row: tuple) -> list:
    row_list = list(row)
    bio_index = COLUMNS.index("bio")
    avatar_index = COLUMNS.index("avatar")

    bio_value = row_list[bio_index]
    if isinstance(bio_value, str):
        row_list[bio_index] = " ".join(bio_value.splitlines()).strip()

    avatar_value = row_list[avatar_index]
    if isinstance(avatar_value, str) and avatar_value.startswith("data:image"):
        row_list[avatar_index] = ""

    return row_list


def main() -> None:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise RuntimeError("DATABASE_URL is not set")

    normalized_url = normalize_database_url(database_url)
    sslmode = resolve_ssl_mode(normalized_url)
    with psycopg2.connect(normalized_url, sslmode=sslmode) as connection:
        with connection.cursor() as cursor:
            cursor.execute(QUERY)
            rows = cursor.fetchall()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with OUTPUT_FILE.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(COLUMNS)
        for row in rows:
            writer.writerow(sanitize_row(row))

    print(f"✅ CSV exported: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()

