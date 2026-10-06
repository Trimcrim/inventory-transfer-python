import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app import db
from app.routes import router

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("inventory")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.pool.open(wait=True)
    yield
    await db.pool.close()


app = FastAPI(title="Inventory Transfer Service", lifespan=lifespan)
app.include_router(router)


@app.exception_handler(Exception)
async def handle_unexpected_error(request: Request, exc: Exception):
    log.error("%s %s failed", request.method, request.url.path, exc_info=exc)
    return JSONResponse(status_code=500, content={"error": "internal error"})
