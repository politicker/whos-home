use serde::{Deserialize, Serialize};
use std::env;
use std::fs::File;
use std::process::Command;
use time::{Duration, Instant};

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

fn main() {
	let config_path = env::var("CONFIG_PATH").unwrap_or(String::from("../example_config.yaml"));
	let config_contents = File::open(config_path).unwrap();

	let config: Config = serde_yaml::from_reader(config_contents).unwrap();

	// Raspi version of arp-scan command
	// arp-scan --localnet --interface en0
	// let output = Command::new("arp-scan")
	// 	.arg("-l")
	// 	.arg("-r")
	// 	.arg("3")
	// 	.output()
	// 	.expect("expected output");

	loop {
		let mut last_detected_at = time::Instant::now();
		let mut is_home = false;

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
				print!("Found Harrison's phone on wifi");

				last_detected_at = time::Instant::now();

				if !is_home {
					// publish 'person arrived home'
					is_home = true;
				}
				continue;
			}

			let ten_min_from_last = last_detected_at.checked_add(Duration::minutes(10)).unwrap();
			if Instant::now() > ten_min_from_last && is_home {
				// publish 'person left home'
				is_home = false;
			}
		}
	}
}
