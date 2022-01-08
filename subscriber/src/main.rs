use aws_config::meta::region::RegionProviderChain;
use aws_sdk_sqs::Client;
use serde::{Deserialize, Serialize};
use std::env;
use std::fs::File;

static QUEUE_URL: &str = "https://sqs.us-east-1.amazonaws.com/824357296248/whos-home-main-sub.fifo";

#[derive(PartialEq, Serialize, Deserialize)]
struct Followee {
	name: String,
	location_name: String,
	gpio_pin_number: i32,
}

#[derive(Serialize, Deserialize)]
struct Config {
	name: String,
	following: Vec<Followee>,
	queue_id: String,
	queue_name: String,
}

#[derive(Serialize, Deserialize)]
struct QueueEvent {
	name: String,
	location: String,
	event: String,
}

async fn handle_message(
	client: &aws_sdk_sqs::Client,
	message: aws_sdk_sqs::model::Message,
	config: &Config,
) -> () {
	println!("{}", message.body.unwrap());

	match client
		.receive_message()
		.queue_url(QUEUE_URL)
		// .receipt_handle(message.receipt_handle.unwrap())
		.send()
		.await
	{
		Ok(msg) => {
			println!("received message");

			// NOTE: The assumption here is the default value of msg.messages is an empty array
			for message in msg.messages.unwrap_or_default() {
				let body = match message.body {
					Some(b) => b,
					None => {
						println!("empty body, skipping");
						continue;
					}
				};

				let body: &str = &body;
				let event: QueueEvent = match serde_json::from_str(body) {
					Ok(e) => e,
					Err(err) => {
						println!("failed to parse incoming message: {}", err);
						continue;
					}
				};

				for f in &config.following {
					// The message received from the pub/sub queue is about someone you follow
					if f.name == event.name {
						// TODO: toggle f.gpio_pin_number on raspi
						println!("toggle gpio: {}", f.gpio_pin_number)
					}
				}
			}
		}
		Err(_) => println!("error deleting received message"),
	}
}

#[tokio::main]
async fn main() {
	let region_provider = RegionProviderChain::default_provider().or_else("us-east-1");
	let config = aws_config::from_env().region(region_provider).load().await;
	let client = Client::new(&config);

	const CONFIG_PATH_ENV_NAME: &str = "CONFIG_PATH";

	let config_path = env::var(CONFIG_PATH_ENV_NAME).unwrap_or(String::from("../config.yaml"));
	let config_contents = File::open(config_path).unwrap();
	let config: Config = serde_yaml::from_reader(config_contents).unwrap();

	loop {
		match client
			.receive_message()
			.wait_time_seconds(5)
			.queue_url(QUEUE_URL)
			.send()
			.await
		{
			Ok(message) => {
				println!("Request completed. checking for messages...");

				for ml in message.messages {
					for msg in ml {
						handle_message(&client, msg, &config).await;
					}
				}
			}
			Err(e) => {
				println!("{}", e);
				break;
			}
		};
	}
}
