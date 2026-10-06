import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from psycopg import AsyncConnection
from psycopg_pool import AsyncConnectionPool

POOL_MAX_SIZE = 5
POOL_TIMEOUT_SECONDS = 5

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgres://inventory:inventory@localhost:5432/inventory"
)

pool = AsyncConnectionPool(
    DATABASE_URL,
    min_size=1,
    max_size=POOL_MAX_SIZE,
    timeout=POOL_TIMEOUT_SECONDS,
    kwargs={"autocommit": True},
    open=False,
)
waiting = 0


async def getconn() -> AsyncConnection:
    """Takes a connection from the pool and keeps count of callers waiting for one."""
    global waiting
    waiting += 1
    try:
        return await pool.getconn()
    finally:
        waiting -= 1


async def putconn(conn: AsyncConnection) -> None:
    await pool.putconn(conn)


@asynccontextmanager
async def connection() -> AsyncIterator[AsyncConnection]:
    conn = await getconn()
    try:
        yield conn
    finally:
        await putconn(conn)


def pool_stats() -> dict[str, int]:
    stats = pool.get_stats()
    total = stats.get("pool_size", 0)
    idle = stats.get("pool_available", 0)
    return {
        "max": POOL_MAX_SIZE,
        "total": total,
        "active": total - idle,
        "idle": idle,
        "waiting": waiting,
    }
