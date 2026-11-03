from fastapi import APIRouter, HTTPException

from app.db import get_connection

router = APIRouter(prefix="/api/v1/arenas", tags=["Arenas"])


@router.get("")
def list_arenas() -> list[dict]:
    """Return active arenas without exposing private mission evaluation data."""
    try:
        with get_connection() as connection:
            rows = connection.execute(
                """
                SELECT arena_key, name, description, accent_color, icon_key, display_order
                FROM arenas
                WHERE is_active = TRUE
                ORDER BY display_order, name
                """
            ).fetchall()
            return [dict(row) for row in rows]
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Arena catalogue is temporarily unavailable.") from exc
