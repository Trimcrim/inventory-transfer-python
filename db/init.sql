CREATE TABLE inventory (
    id          SERIAL PRIMARY KEY,
    sku         VARCHAR(32)  NOT NULL,
    location    VARCHAR(32)  NOT NULL,
    quantity    INTEGER      NOT NULL,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (sku, location)
);

INSERT INTO inventory (sku, location, quantity) VALUES
    ('SKU-001', 'WAREHOUSE-A', 1000),
    ('SKU-001', 'WAREHOUSE-B', 500),
    ('SKU-001', 'WAREHOUSE-C', 300),
    ('SKU-002', 'WAREHOUSE-A', 2000),
    ('SKU-002', 'WAREHOUSE-B', 1500),
    ('SKU-003', 'WAREHOUSE-A', 500),
    ('SKU-003', 'WAREHOUSE-C', 200);
