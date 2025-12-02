# watchmynetwork

`wmn` is a lightweight, open-source network monitoring tool that continuously captures and parses live output from your operating system’s `ping` command.  
Each ICMP response is converted into structured metrics, including latency, packet loss, TTL, ICMP type, and byte size , and stored into a PostgreSQL database at fixed intervals.  
Dashboards and visualizations can then be built using Grafana or any analytics tool of your choice.

---

## Features

- Continuous real-time ping monitoring
- Parses native OS ping output
- Captures:
  - Latency (ms)
  - Packet loss events
  - TTL value
  - ICMP type
  - Bytes received
  - Status (OK / TIMEOUT)
- Stores metrics in PostgreSQL
- Ready-to-use Grafana setup with preconfigured datasource
- Example Grafana dashboard included
- Small binary footprint and minimal dependencies

---

## Architecture

1. `ping` runs as a subprocess
2. Output is parsed line-by-line
3. Parsed metrics are buffered
4. Buffered samples are flushed to PostgreSQL every N minutes
5. Grafana reads from PostgreSQL and renders dashboards

---

## Installation & Usage

### 1. Start PostgreSQL and Grafana

The provided Docker Compose file spins up:

- PostgreSQL on `localhost:5432`
- Grafana on `localhost:3000`

Run:

```sh
docker compose up -d
```

This initializes:

- A ready-to-use PostgreSQL instance
- A time-series table for storing ping metrics
- A Grafana instance with a pre-wired datasource pointing to PostgreSQL

---

### 2. Run the watchmynetwork binary

Start the collector by running the compiled binary (see releases).  
It will begin streaming ping output, parsing each line, and buffering metrics until it flushes them to the database.

---

### 3. Open Grafana

Navigate to:

http://localhost:3000

On first launch:

- Set the admin password
- Verify that the PostgreSQL datasource is already connected
- Proceed to dashboard creation or import

---

### 4. Import or create dashboards

You can import the example dashboard available in the repository under grafana/dashboard.json.  
Alternatively, create custom visualizations using the ping_results table as the data source.

Fields available include:

- timestamp
- target_ip
- response_time_ms
- packet_loss
- bytes_received
- ttl
- status

These can be plotted as time series, histograms, gauges, or combined panels.

---

## Database Schema

The project stores parsed metrics into a table named ping_results, indexed for fast time-series querying and multi-host aggregation.

---

## Configuration

Configurations are not currently suported , the plan is to turn this into a proper CLI

For now you can modify:

- Target IP address
- Flush interval
- Database connection settings
- Ping output parsing rules

These are defined in the Rust source and can be customized based on your environment.

---

## Example Use Cases

- Long-term latency tracking
- Monitoring ISP stability
- Packet loss detection
- Server uptime and connectivity measurement
- Feeding network metrics into alerting and automation systems

---

## Contributing

Pull requests and issue reports are welcome.  
Contributions that improve performance, add features, or enhance Grafana dashboards are appreciated.

---

## License

MIT License.  
You are free to use, modify, and distribute this project.
