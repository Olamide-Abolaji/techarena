import psycopg
from psycopg.rows import dict_row

from app.core.config import settings


def get_connection():
    """Open a PostgreSQL connection using the configured database URL."""
    return psycopg.connect(settings.database_url, row_factory=dict_row)
