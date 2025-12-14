CREATE TABLE IF NOT EXISTS ping_results (
    id SERIAL PRIMARY KEY,
    target_ip VARCHAR(45) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    response_time_ms FLOAT,
    packet_loss FLOAT,
    bytes_received INT,
    icmp_type INT,
    ttl INT,
    status VARCHAR(20) NOT NULL
);

CREATE INDEX idx_timestamp ON ping_results(timestamp DESC);
CREATE INDEX idx_target_ip ON ping_results(target_ip);

CREATE TABLE favicon_metrics (
    ts           TIMESTAMPTZ NOT NULL DEFAULT now(),
    source       TEXT NOT NULL,
    probe_id     BIGINT NOT NULL,
    dns_ms       DOUBLE PRECISION,
    connect_ms   DOUBLE PRECISION,
    tls_ms       DOUBLE PRECISION,
    ttfb_ms      DOUBLE PRECISION,
    total_ms     DOUBLE PRECISION,
    status       INTEGER,
    disconnected BOOLEAN NOT NULL
);

CREATE INDEX ON favicon_metrics (ts);
CREATE INDEX ON favicon_metrics (source, ts);
