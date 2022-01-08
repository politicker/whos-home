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
		let output = Command::new("arp-scan")
			.arg("--localnet")
			.arg("--interface")
			.arg("en0")
			.output()
			.expect("failed to build command arp-scan");

		if !output.status.success() {
			println!("arp-scan command returned error");
			break;
		}

		let text_output = String::from_utf8(output.stdout).expect("failed to utf-decode cmd output");
		for person in &config.people {
			if text_output.contains(&person.mac_address) {
				last_detected_at = time::Instant::now();

				if !is_home {
					println!("arriving home");

					let rand_string: String = thread_rng()
						.sample_iter(&Alphanumeric)
						.take(30)
						.map(char::from)
						.collect();

					client
						.publish()
						.topic_arn(&topic_arn)
						.message_group_id("l23")
						.message_deduplication_id(rand_string)
						.message("{\"name\": \"Harrison\", \"location\": \"Home\", \"event\": \"ARRIVING\"}")
						.send()
						.await
						.expect("failed to publish arrival");

					is_home = true;
				}
				continue;
			}

			let ten_min_from_last = last_detected_at.checked_add(Duration::minutes(10)).unwrap();
			if Instant::now() > ten_min_from_last && is_home {
				is_home = false;
				println!("leaving home");

				let rand_string: String = thread_rng()
					.sample_iter(&Alphanumeric)
					.take(30)
					.map(char::from)
					.collect();

				client
					.publish()
					.topic_arn(&topic_arn)
					.message_group_id("124")
					.message_deduplication_id(rand_string)
					.message("{\"name\": \"Harrison\", \"location\": \"Home\", \"event\": \"DEPARTING\"}")
					.send()
					.await
					.expect("failed to publish departure");
			}
		}
	}
}
