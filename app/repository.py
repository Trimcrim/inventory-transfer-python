from psycopg import AsyncConnection


async def get_stock_levels(conn: AsyncConnection, sku: str) -> dict[str, int]:
    cur = await conn.execute(
        "SELECT location, quantity FROM inventory WHERE sku = %s ORDER BY location",
        (sku,),
    )
    return {location: quantity for location, quantity in await cur.fetchall()}


async def get_quantity(conn: AsyncConnection, sku: str, location: str) -> int:
    cur = await conn.execute(
        "SELECT quantity FROM inventory WHERE sku = %s AND location = %s",
        (sku, location),
    )
    row = await cur.fetchone()
    if row is None:
        raise LookupError(f"{sku} is not stocked at {location}")
    return row[0]


async def set_quantity(conn: AsyncConnection, sku: str, location: str, quantity: int) -> None:
    await conn.execute(
        "UPDATE inventory SET quantity = %s, updated_at = now() WHERE sku = %s AND location = %s",
        (quantity, sku, location),
    )


async def move_stock(
    conn: AsyncConnection, sku: str, from_location: str, to_location: str, quantity: int
) -> None:
    source = await get_quantity(conn, sku, from_location)
    target = await get_quantity(conn, sku, to_location)
    await set_quantity(conn, sku, from_location, source - quantity)
    await set_quantity(conn, sku, to_location, target + quantity)
