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
