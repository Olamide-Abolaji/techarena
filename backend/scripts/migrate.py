from pathlib import Path

import psycopg

from app.core.config import settings


MIGRATION_FILE = Path(__file__).resolve().parents[1] / "migrations" / "001_initial_schema.sql"


def main() -> None:
    sql = MIGRATION_FILE.read_text(encoding="utf-8")
    with psycopg.connect(settings.database_url) as connection:
        connection.execute(sql, prepare=False)
    print("TechArena database schema v1.1 applied successfully.")


if __name__ == "__main__":
    main()
