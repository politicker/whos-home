use serde::{Deserialize, Serialize};
use std::env;
use std::fs::File;
use std::process::Command;
use time::{Duration, Instant};

use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};

use aws_config::meta::region::RegionProviderChain;
use aws_sdk_sns::Client;

// Result of device on the network?
#[derive(PartialEq, Serialize, Deserialize)]
struct Person {
	name: String,
	mac_address: String,
	location_name: String,
	// gpio_pin_number: i16,
}

#[derive(PartialEq, Serialize, Deserialize)]
struct Config {
	name: String,
	people: Vec<Person>,
	following: Vec<Person>,
	queue_id: String,
	queue_name: String,
}

#[derive(Serialize, Deserialize)]
struct QueueEvent {
	name: String,
	location: String,
	event: String,
}

#[tokio::main]
async fn main() {
	let config_path = env::var("CONFIG_PATH").unwrap_or(String::from("../example_config.yaml"));
	let config_contents = File::open(config_path).unwrap();

	let topic_arn = env::var("SNS_TOPIC_ARN").unwrap();

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

	loop {
		// macOS version of arp-scan command
		// sudo arp-scan --localnet --interface en0
		let output = match Command::new("arp-scan")
			.arg("--localnet")
			.arg("--interface")
			.arg("en0")
			.output()
		{
			Ok(o) => o,
			Err(_) => {
				println!("arp-scan command failed");
				continue;
			}
		};

		if !output.status.success() {
			println!("arp-scan command returned error");
			break;
		}

		let text_output = match String::from_utf8(output.stdout) {
			Ok(str) => str,
			Err(_) => {
				println!("failed to utf-decode cmd output");
				continue;
			}
		};

		for person in &config.people {
			if text_output.contains(&person.mac_address) {
				last_detected_at = time::Instant::now();

				if !is_home {
					is_home = true;
					println!("arriving home");

					match publish_to_sns(&person, &client, &topic_arn, "ARRIVING").await {
						Ok(_) => println!("published ARRIVING for: {}", person.name),
						Err(_) => println!("failed to publish ARRIVING for: {}", person.name),
					}
				}
				continue;
			}

			let ten_min_from_last = match last_detected_at.checked_add(Duration::minutes(10)) {
				Some(d) => d,
				None => {
					println!("failed to parse ten_min_from_last");
					continue;
				}
			};

			if Instant::now() > ten_min_from_last && is_home {
				is_home = false;
				println!("leaving home");

				match publish_to_sns(&person, &client, &topic_arn, "DEPARTING").await {
					Ok(_) => println!("published DEPARTING for: {}", person.name),
					Err(_) => println!("failed to publish DEPARTING for: {}", person.name),
				}
			}
		}
	}

	async fn publish_to_sns(
		person: &Person,
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
			name: person.name.clone(),
			location: person.location_name.clone(),
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
}
