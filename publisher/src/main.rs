use serde::{Deserialize, Serialize};
use std::env;
use std::fs::File;
use std::process::Command;
use time::{Duration, Instant};

use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};

use aws_config::meta::region::RegionProviderChain;
use aws_sdk_sns::Client;

#[derive(PartialEq, Serialize, Deserialize)]
struct Resident {
	name: String,
	mac_address: String,
	location_name: String,
}

#[derive(PartialEq, Serialize, Deserialize)]
struct Config {
	name: String,
	people: Vec<Resident>,
	following: Vec<Resident>,
	queue_id: String,
	queue_name: String,
}

#[derive(Serialize, Deserialize)]
struct QueueEvent {
	name: String,
	location: String,
	event: String,
}

const CONFIG_PATH_ENV_NAME: &str = "CONFIG_PATH";
const SNS_TOPIC_ARN_ENV_NAME: &str = "SNS_TOPIC_ARN";

const DEPARTURE_MINUTES_THRESHOLD: i64 = 5;

#[tokio::main]
async fn main() {
	let config_path = env::var(CONFIG_PATH_ENV_NAME).unwrap_or(String::from("../config.yaml"));
	let config_contents = File::open(config_path).unwrap();

	let topic_arn = env::var(SNS_TOPIC_ARN_ENV_NAME).unwrap();

	let config: Config = serde_yaml::from_reader(config_contents).unwrap();

	let region_provider = RegionProviderChain::default_provider().or_else("us-east-1");
	let aws_config = aws_config::from_env().region(region_provider).load().await;
	let client = Client::new(&aws_config);

	let mut last_detected_at = time::Instant::now();
	let mut is_home = false;

	// TODO: check if arp-scan is installed on system

	// Raspi version of arp-scan command
	// arp-scan --localnet --interface en0
	// let output = Command::new("arp-scan")
	// 	.arg("-l")
	// 	.arg("-r")
	// 	.arg("3")
	// 	.output()
	// 	.expect("expected output");

	// TODO: Count errors and exit program after a certain amount
	loop {
		// macOS version of arp-scan command
		// sudo arp-scan --localnet --interface en0
		let output = match Command::new("arp-scan")
			.arg("--localnet")
			.arg("--interface")
			.arg("en0")
			.output()
		{
			Ok(out) => out,
			Err(_) => {
				println!("arp-scan command failed");
				continue;
			}
		};

		if !output.status.success() {
			println!("arp-scan command returned error");
			continue;
		}

		let text_output = match String::from_utf8(output.stdout) {
			Ok(str) => str,
			Err(_) => {
				println!("failed to utf-decode cmd output");
				continue;
			}
		};

		for resident in &config.people {
			if text_output.contains(&resident.mac_address) {
				last_detected_at = time::Instant::now();

				if !is_home {
					is_home = true;
					println!("arriving home");

					match publish_to_sns(&resident, &client, &topic_arn, "ARRIVING").await {
						Ok(_) => println!("published ARRIVING for: {}", resident.name),
						Err(_) => println!("failed to publish ARRIVING for: {}", resident.name),
					}
				}
				continue;
			}

			let departure_cutoff_time =
				match last_detected_at.checked_add(Duration::minutes(DEPARTURE_MINUTES_THRESHOLD)) {
					Some(t) => t,
					None => {
						println!("failed to parse departure_cutoff_time");
						continue;
					}
				};

			if Instant::now() > departure_cutoff_time && is_home {
				is_home = false;
				println!("leaving home");

				match publish_to_sns(&resident, &client, &topic_arn, "DEPARTING").await {
					Ok(_) => println!("published DEPARTING for: {}", resident.name),
					Err(_) => println!("failed to publish DEPARTING for: {}", resident.name),
				}
			}
		}
	}
}

async fn publish_to_sns(
	resident: &Resident,
	client: &aws_sdk_sns::Client,
	topic_arn: &String,
	event: &str,
) -> Result<(), Box<dyn std::error::Error>> {
	let rand_string: String = thread_rng()
		.sample_iter(&Alphanumeric)
		.take(30)
		.map(char::from)
		.collect();

	let event = QueueEvent {
		name: resident.name.clone(),
		location: resident.location_name.clone(),
		event: String::from(event),
	};
	let json = serde_json::to_string(&event)?;

	client
		.publish()
		.topic_arn(topic_arn)
		.message_group_id("124")
		.message_deduplication_id(rand_string)
		.message(json)
		.send()
		.await?;

	return Ok(());
}
