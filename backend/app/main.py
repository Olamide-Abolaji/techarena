from fastapi import FastAPI

from app.api.routes.arenas import router as arenas_router
from app.api.routes.health import router as health_router

app = FastAPI(
    title="TechArena API",
    version="0.1.0",
    description="Challenge-based learning platform API.",
)

app.include_router(health_router)
app.include_router(arenas_router)
