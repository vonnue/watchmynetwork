# watchmynetwork

A lightweight, open-source network monitoring utility that periodically probes external endpoints using curl, captures comprehensive timing metrics, and stores results in PostgreSQL for analysis and visualization in Grafana.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

**watchmynetwork (wmn)** provides real-time network monitoring with sub-second granularity. It probes popular and reliable endpoints at 1-second intervals, capturing detailed performance metrics and storing them in a PostgreSQL database for historical analysis and SLA reporting.

### Key Capabilities

- **High-frequency probing** – Fixed 1-second cadence for precise monitoring
- **Comprehensive metrics** – DNS, TCP, TLS, TTFB, and total response times via curl (native libcurl)
- **Multi-endpoint support** – Monitor multiple sources simultaneously per probe cycle
- **Time-series storage** – Direct PostgreSQL integration for efficient data persistence
- **Production-ready** – Runs as a systemd service with automatic startup
- **Grafana integration** – Pre-configured dashboards for visualization and alerting
- **Minimal footprint** – Lightweight Rust binary with few dependencies

---

## Architecture

```
systemd
   │
   └─► wmn (Rust binary)
        │
        ├─► Scheduler (1 Hz, strict timing)
        ├─► Fire-and-forget probe tasks
        └─► curl subprocess (no keep-alive, enforced timeouts)
            │
            └─► PostgreSQL (time-series storage)
                 │
                 └─► Grafana (dashboards & SLA reports)
```

### How It Works

- **Probe Groups**: Each scheduler tick generates a unique `probe_id`
- **Multi-source Monitoring**: One row is recorded per `(probe_id, source)` combination
- **Downtime Detection**: A probe is marked DOWN when all sources fail for the same `probe_id`
- **SLA Metrics**: Uptime, downtime events, and packet loss are computed from probe group aggregations

---

## Metrics Captured

Each probe collects the following data points:

| Metric         | Description                                |
| -------------- | ------------------------------------------ |
| `ts`           | Timestamp of the probe                     |
| `source`       | Target endpoint URL                        |
| `probe_id`     | Unique identifier for the probe cycle      |
| `dns_ms`       | DNS resolution time (milliseconds)         |
| `connect_ms`   | TCP connection establishment time          |
| `tls_ms`       | TLS/SSL handshake time                     |
| `ttfb_ms`      | Time to first byte                         |
| `total_ms`     | Total request duration                     |
| `status`       | HTTP status code returned                  |
| `disconnected` | Boolean flag indicating connection failure |

---

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Linux system with systemd support
- `curl` installed on the host

### 1. Clone the Repository

```bash
git clone https://github.com/vonnue/watchmynetwork.git
cd watchmynetwork
```

### 2. Start PostgreSQL and Grafana

Launch the backing services using Docker Compose:

```bash
docker compose up -d
```

This initializes:

- **PostgreSQL** on `localhost:5432` with the time-series schema pre-configured
- **Grafana** on `localhost:3000` with datasource already connected

### 3. Install the Monitoring Agent

Run the installation script with sudo privileges:

```bash
sudo ./install_wmn.sh
```

This will:

- Install the `wmn` binary to `/usr/local/bin/`
- Create and configure `wmn-agent.service`
- Enable the service for automatic startup on boot
- Start monitoring immediately

### 4. Access Grafana

Open your browser and navigate to:

```
http://localhost:3000
```

**First-time setup:**

1. Set your admin password when prompted
2. Verify the PostgreSQL datasource connection (pre-configured)
3. Import the included dashboard or create your own

### 5. Import the Dashboard

Import the example dashboard for instant visualization:

1. In Grafana, go to **Dashboards** → **Import**
2. Upload `grafana/dashboard-favicon.json` from the repository

---

## Configuration

### Database Schema

The monitoring data is stored in the `favicon_metrics` table:

```sql
CREATE TABLE favicon_metrics (
    ts           TIMESTAMPTZ NOT NULL DEFAULT now(),
    probe_id     BIGINT NOT NULL,
    source       TEXT NOT NULL,
    dns_ms       DOUBLE PRECISION,
    connect_ms   DOUBLE PRECISION,
    tls_ms       DOUBLE PRECISION,
    ttfb_ms      DOUBLE PRECISION,
    total_ms     DOUBLE PRECISION,
    status       INTEGER,
    disconnected BOOLEAN NOT NULL,
    PRIMARY KEY (probe_id, source)
);

CREATE INDEX ON favicon_metrics (ts);
CREATE INDEX ON favicon_metrics (source, ts);
```

### Current Behavior

- **Redirects**: Enabled by default _(configurable option coming soon)_
- **Connection pooling**: Disabled (no keep-alive)
- **Probe interval**: Fixed at 1 second
- **Timeout enforcement**: Handled by curl subprocess (1.5 seconds)

---

## Management

### View Service Logs

Monitor real-time logs from the wmn agent:

```bash
journalctl -u wmn-agent -f
```

### Service Management

```bash
# Check service status
sudo systemctl status wmn-agent

# Stop the service
sudo systemctl stop wmn-agent

# Restart the service
sudo systemctl restart wmn-agent

# Disable auto-start
sudo systemctl disable wmn-agent
```

---

---

## Contributing

Contributions are welcome! We appreciate:

- Performance optimizations
- New feature implementations
- Enhanced Grafana dashboards
- Bug fixes and issue reports
- Documentation improvements

**To contribute:**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Roadmap

- [ ] Configuration support
- [ ] Support for additional protocols (ICMP, UDP)
- [ ] Alerting capabilities
- [ ] Prometheus exporter option

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

You are free to use, modify, and distribute this project for any purpose.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/vonnue/watchmynetwork/issues)
- **Discussions**: [GitHub Discussions](https://github.com/vonnue/watchmynetwork/discussions)
