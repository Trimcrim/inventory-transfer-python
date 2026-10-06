import asyncio

# Typical response time of the product catalogue service.
CATALOGUE_LATENCY_SECONDS = 0.01


async def check_transfer_allowed(
    sku: str, from_location: str, to_location: str, quantity: int
) -> str | None:
    """Checks a transfer against the business rules.

    Returns a message that explains why the transfer is not allowed,
    or None if it may go ahead.
    """
    if quantity <= 0:
        return "quantity must be greater than zero"
    if from_location == to_location:
        return "source and target location must be different"
    if not await catalogue_allows_location(sku, to_location):
        return f"{sku} cannot be stored at {to_location}"
    return None


async def catalogue_allows_location(sku: str, location: str) -> bool:
    # In production this calls the product catalogue service, which knows the
    # storage requirements of every SKU (cooling, hazardous goods, size).
    # The local client is a stub: it allows everything and answers with the
    # catalogue's usual latency.
    await asyncio.sleep(CATALOGUE_LATENCY_SECONDS)
    return True
