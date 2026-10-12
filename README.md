# Inventory Transfer Service (Python)

## The situation

You have just joined the warehouse team. This service moves stock of a
product (a SKU) from one warehouse location to another.

The service has run in the development environment for several weeks without
any problems. Last week the team started load testing before the release,
and the service began to fail. The team has spent two days on it and they are
stuck. They have asked you to help.

## The business rule

**The total quantity of a SKU across all locations must stay the same after
any number of transfers.** A transfer only moves stock. It must never create
or destroy it.

The database starts with this data:

| SKU     | Location    | Quantity |
|---------|-------------|----------|
| SKU-001 | WAREHOUSE-A | 1000     |
| SKU-001 | WAREHOUSE-B | 500      |
| SKU-001 | WAREHOUSE-C | 300      |
| SKU-002 | WAREHOUSE-A | 2000     |
| SKU-002 | WAREHOUSE-B | 1500     |
| SKU-003 | WAREHOUSE-A | 500      |
| SKU-003 | WAREHOUSE-C | 200      |

So the totals must always be: SKU-001 = 1800, SKU-002 = 3500, SKU-003 = 700.

## Tech stack

- Python 3.12, FastAPI, uvicorn
- psycopg 3 with `psycopg_pool`
- PostgreSQL 15

The database connection pool has a maximum of 5 connections. A request waits
up to 5 seconds for a free connection.

Code layout:

```
app/
  main.py         application setup
  routes.py       HTTP handlers
  rules.py        business rules for transfers
  repository.py   database queries
  db.py           connection pool
db/init.sql       schema and seed data
scripts/          test scripts
```

## Running the service

### With Docker (recommended)

You need Docker with Docker Compose.

```bash
docker compose up --build
```

This starts PostgreSQL, loads the data from `db/init.sql` and starts the
service on http://localhost:8080. PostgreSQL is also available on
`localhost:5432` (user `inventory`, password `inventory`, database
`inventory`) if you want to look inside it with `psql` or another tool. If
port 5432 is already in use on your machine, start with
`DB_PORT=5433 docker compose up --build`.

Useful commands:

```bash
docker compose restart app     # restart only the service, keep the data
docker compose down -v         # stop everything and delete the data
docker compose up --build      # start again with fresh seed data
docker compose logs -f app     # follow the service logs
```

### Without Docker

You need PostgreSQL 15 running on your machine.

```bash
createdb inventory
psql -d inventory -f db/init.sql
```

Then start the service:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export DATABASE_URL=postgres://inventory:inventory@localhost:5432/inventory
uvicorn app.main:app --port 8080
```

`DATABASE_URL` defaults to
`postgres://inventory:inventory@localhost:5432/inventory`.

## The API

Read the stock of a SKU:

```bash
curl http://localhost:8080/api/inventory/SKU-001
```

```json
{
  "sku": "SKU-001",
  "locations": [
    {"location": "WAREHOUSE-A", "quantity": 1000},
    {"location": "WAREHOUSE-B", "quantity": 500},
    {"location": "WAREHOUSE-C", "quantity": 300}
  ],
  "total": 1800
}
```

Move stock:

```bash
curl -X POST http://localhost:8080/api/transfer \
  -H "Content-Type: application/json" \
  -d '{"sku":"SKU-001","fromLocation":"WAREHOUSE-A","toLocation":"WAREHOUSE-B","quantity":10}'
```

It answers `200` when the transfer is done, `400` when there is not enough
stock or the quantity is not positive, and `404` when the SKU or location is
unknown.

Check the service and its connection pool:

```bash
curl http://localhost:8080/api/health
```

```json
{"status": "UP", "pool": {"max": 5, "total": 1, "active": 0, "idle": 1, "waiting": 0}}
```

`max` is the pool limit, `total` is how many connections are open, `active`
is how many are in use, `idle` is how many are free, and `waiting` is how many
requests are waiting for a connection.

## Scripts

The `scripts/` folder has some tools the team wrote during load testing. They
need `bash`, `curl` and `jq`. **On Windows, run them in WSL or Git Bash.**

| Script | What it does |
|--------|--------------|
| `./scripts/consistency_check.sh` | Compares the total of each SKU with the expected value. Prints OK or FAIL per SKU. |
| `./scripts/burst_test.sh [concurrency] [total]` | Sends many valid transfers at the same time (default: 20 at a time, 100 in total), alternating WAREHOUSE-A to WAREHOUSE-B and back. |
| `./scripts/leak_test.sh [count]` | Sends transfers that cannot succeed, then prints the state of the connection pool. |
| `./scripts/pool_monitor.sh` | Prints the state of the connection pool once per second. Stop it with Ctrl+C. |

All scripts use `http://localhost:8080` by default. You can change this with
the `BASE_URL` environment variable.

## What the team has seen

1. **The totals stop adding up.** After many transfers run at the same time,
   the total of a SKU is no longer the expected value. When the same
   transfers are sent one by one, everything looks correct.
2. **The service stops responding.** After a series of failed transfers (for
   example, transfers with too little stock), new transfers hang for a few
   seconds and then fail. After a restart the service works again, for a
   while.

## Your task

1. **Reproduce** both problems on your machine.
2. **Find the causes.** There may be more than one cause.
3. **Explain why** the problems only appear under load, and not when one
   developer tests the service by hand.
4. **Prioritize fixes.** Make focused code changes and verify them with
   reproducible checks or tests, to the extent reached within the timebox.

You are free to change anything: the code, the scripts, the database, the
configuration. You can add logging, tests or tools.

## Time

Plan for **2–3 hours total**, including setup, investigation, implementation,
and notes. Stop by three hours and submit what you have.

**Full completion is not expected. An honest partial answer is better than a
complete answer that you cannot explain.** Record blockers, hypotheses,
unsuccessful attempts, and unfinished work.

## AI tools

You may use AI tools (ChatGPT, Claude, Copilot and others). After you hand in
your work, the next step is a call where you explain your reasoning to us.
Anything that you cannot explain on the call is worth nothing, so make sure
you understand every finding and every line of code you hand in. Please also
tell us how you used AI.

## What to hand in

One file, `NOTES.md`, in the root of the repository, with these parts:

1. **What you found** – each problem and its cause.
2. **How to reproduce it** – the exact steps or commands.
3. **Why it only shows under load** – in your own words.
4. **The fix you propose** – and why you chose it over other options.
5. **How to catch this earlier in production** – what you would add
   (logging, metrics, alerts, tests).
6. **What you did not get to** – and what you would do with more time.

Submit a public clone of the repository (or a patch), with any code changes
and `NOTES.md`. Include time spent and a brief chronological thinking log:
what you tried, learned, changed your mind about, and left unfinished. Explain
any AI/tool use and how you checked the results. Full chat transcripts are not
required.

**Screen recording is optional.** You may use a recording with voice comments
instead of written notes. Do not send exercise solutions as pull requests to
the upstream repository.

Good luck, and have fun.
