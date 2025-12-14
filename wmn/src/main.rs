use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::Result;
use tokio::{
    process::Command,
    time::{Duration, interval},
};
use tokio_postgres::NoTls;

static SOURCES: [&str; 2] = [
    "https://google.com/favicon.ico",
    "https://cloudflare.com/favicon.ico",
];

static DB_CONN_STR: &str = "host=localhost user=pinguser password=pingpass123 dbname=wmn";

#[derive(Debug)]
struct FaviconFetchMetrics {
    source: &'static str,
    probe_id: i64,
    dns_ms: f64,
    connect_ms: f64,
    tls_ms: f64,
    ttfb_ms: f64,
    total_ms: f64,
    status: u16,
    disconnected: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let _ = connect_db().await?;

    let mut probe_tick = interval(Duration::from_secs(1));

    loop {
        probe_tick.tick().await;
        let probe_id: i64 = SystemTime::now()
            .duration_since(UNIX_EPOCH)?
            .as_secs()
            .try_into()?;

        for &source in SOURCES.iter() {
            tokio::spawn(async move {
                let res = fetch_favicon(source, probe_id).await;
                let metric = match res {
                    Ok(m) => {
                        println!("{:?}", m);
                        m
                    }
                    Err(e) => {
                        eprintln!("{} error: {}", source, e);
                        FaviconFetchMetrics {
                            source,
                            probe_id,
                            dns_ms: 0.0,
                            connect_ms: 0.0,
                            tls_ms: 0.0,
                            ttfb_ms: 0.0,
                            total_ms: 0.0,
                            status: 0,
                            disconnected: true,
                        }
                    }
                };

                if let Err(e) = insert_metric(&metric).await {
                    eprintln!("DB insert error for {}: {}", source, e);
                }
            });
        }
    }
}

async fn fetch_favicon(source: &'static str, probe_id: i64) -> Result<FaviconFetchMetrics> {
    let output = Command::new("curl")
        .arg("--no-keepalive")
        .arg("--max-time").arg("1.5")
        .arg("--silent")
        .arg("--output").arg("/dev/null")
        .arg("-L")
        .arg("--write-out")
        .arg("%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total} %{http_code}")
        .arg(source)
        .output()
        .await?;

    if let Some(28) = output.status.code() {
        return Ok(FaviconFetchMetrics {
            source,
            probe_id,
            dns_ms: 0.0,
            connect_ms: 0.0,
            tls_ms: 0.0,
            ttfb_ms: 0.0,
            total_ms: 1500.0,
            status: 0,
            disconnected: true,
        });
    }

    if !output.status.success() {
        return Err(anyhow::anyhow!("curl failed"));
    }

    let stdout = String::from_utf8(output.stdout)?;
    let parts: Vec<&str> = stdout.trim().split_whitespace().collect();

    if parts.len() != 6 {
        return Err(anyhow::anyhow!("unexpected curl output: {}", stdout));
    }

    Ok(FaviconFetchMetrics {
        source,
        probe_id,
        dns_ms: parts[0].parse::<f64>()? * 1000.0,
        connect_ms: parts[1].parse::<f64>()? * 1000.0,
        tls_ms: parts[2].parse::<f64>()? * 1000.0,
        ttfb_ms: parts[3].parse::<f64>()? * 1000.0,
        total_ms: parts[4].parse::<f64>()? * 1000.0,
        status: parts[5].parse::<u16>()?,
        disconnected: false,
    })
}

async fn connect_db() -> Result<tokio_postgres::Client> {
    let (client, connection) = tokio_postgres::connect(DB_CONN_STR, NoTls).await?;

    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("postgres connection error: {}", e);
        }
    });

    Ok(client)
}

async fn insert_metric(m: &FaviconFetchMetrics) -> Result<()> {
    let client = connect_db().await?;

    client
        .execute(
            "
            INSERT INTO favicon_metrics
            (source, probe_id, dns_ms, connect_ms, tls_ms, ttfb_ms, total_ms, status, disconnected)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
            ",
            &[
                &m.source,
                &m.probe_id,
                &m.dns_ms,
                &m.connect_ms,
                &m.tls_ms,
                &m.ttfb_ms,
                &m.total_ms,
                &(m.status as i32),
                &m.disconnected,
            ],
        )
        .await?;

    Ok(())
}
