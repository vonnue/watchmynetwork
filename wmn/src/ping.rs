// use postgres::{Client, NoTls};
// use regex::Regex;
// use std::io::{BufRead, BufReader};
// use std::process::{Command, Stdio};
// use std::time::{Duration, Instant};
//
// #[derive(Debug)]
// struct PingSample {
//     target_ip: String,
//     response_time_ms: Option<f64>,
//     packet_loss: f64,
//     bytes_received: Option<i32>,
//     icmp_type: Option<i32>,
//     ttl: Option<i32>,
//     status: String,
// }
//
// fn main() -> Result<(), Box<dyn std::error::Error>> {
//     let target_ip = "8.8.8.8".to_string();
//     let flush_interval = Duration::from_secs(5 * 60);
//
//     let mut client = Client::connect(
//         "host=localhost user=pinguser password=pingpass123 dbname=wmn",
//         NoTls,
//     )?;
//
//     let mut child = Command::new("ping")
//         .arg("-D")
//         .arg("-O")
//         .arg(&target_ip)
//         .stdout(Stdio::piped())
//         .spawn()
//         .expect("failed to start ping");
//
//     let stdout = child.stdout.take().expect("no stdout from ping");
//     let reader = BufReader::new(stdout);
//
//     let re_ok =
//         Regex::new(r"(?P<bytes>\d+)\s+bytes.*ttl=(?P<ttl>\d+)\s+time=(?P<time>[0-9\.]+)\s*ms")?;
//
//     let re_timeout = Regex::new(r"(no answer yet|Request timeout)")?;
//
//     let mut buffer: Vec<PingSample> = Vec::new();
//     let mut last_flush = Instant::now();
//
//     println!("Starting ping collector for {}", target_ip);
//
//     for line in reader.lines() {
//         let line = match line {
//             Ok(l) => l,
//             Err(e) => {
//                 eprintln!("error reading ping output: {e}");
//                 break;
//             }
//         };
//
//         if let Some(caps) = re_ok.captures(&line) {
//             let bytes: i32 = caps["bytes"].parse().unwrap_or(0);
//             let ttl: i32 = caps["ttl"].parse().unwrap_or(0);
//             let rtt_ms: f64 = caps["time"].parse().unwrap_or(0.0);
//
//             let sample = PingSample {
//                 target_ip: target_ip.clone(),
//                 response_time_ms: Some(rtt_ms),
//                 packet_loss: 0.0,
//                 bytes_received: Some(bytes),
//                 icmp_type: Some(0),
//                 ttl: Some(ttl),
//                 status: "OK".to_string(),
//             };
//             println!("{:?}", sample);
//             buffer.push(sample);
//         } else if re_timeout.is_match(&line) {
//             let sample = PingSample {
//                 target_ip: target_ip.clone(),
//                 response_time_ms: None,
//                 packet_loss: 100.0,
//                 bytes_received: None,
//                 icmp_type: Some(3),
//                 ttl: None,
//                 status: "TIMEOUT".to_string(),
//             };
//
//             println!("{:?}", sample);
//             buffer.push(sample);
//         } else {
//             println!("Found another type of response , To be handled {}", line);
//         }
//
//         if last_flush.elapsed() >= flush_interval && !buffer.is_empty() {
//             println!("Flushing {} samples to DB...", buffer.len());
//             if let Err(e) = flush_to_db(&mut client, &buffer) {
//                 print_db_error(e);
//             } else {
//                 println!("Flush complete.");
//                 buffer.clear();
//                 last_flush = Instant::now();
//             }
//         }
//     }
//
//     if !buffer.is_empty() {
//         println!("Final flush of {} samples to DB...", buffer.len());
//         if let Err(e) = flush_to_db(&mut client, &buffer) {
//             print_db_error(e);
//         }
//     }
//
//     Ok(())
// }
//
// fn print_db_error(error: postgres::Error) {
//     if let Some(db_error) = error.as_db_error() {
//         eprintln!("     Message: {}", db_error.message());
//         eprintln!("     Detail: {:?}", db_error.detail());
//         eprintln!("     Hint: {:?}", db_error.hint());
//         eprintln!("     Position: {:?}", db_error.position());
//     }
// }
//
// fn flush_to_db(client: &mut Client, samples: &[PingSample]) -> Result<(), postgres::Error> {
//     let mut tx = client.transaction()?;
//
//     for s in samples {
//         tx.execute(
//             "INSERT INTO ping_results
//             (target_ip, response_time_ms, packet_loss,
//              bytes_received, icmp_type, ttl, status)
//              VALUES ($1,$2,$3,$4,$5,$6,$7)",
//             &[
//                 &s.target_ip,
//                 &s.response_time_ms,
//                 &s.packet_loss,
//                 &s.bytes_received,
//                 &s.icmp_type,
//                 &s.ttl,
//                 &s.status,
//             ],
//         )?;
//     }
//
//     tx.commit()?;
//     Ok(())
// }
