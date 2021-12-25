#[macro_use]
extern crate lambda_runtime as lambda;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate log;
extern crate simple_logger;

use aws_config::meta::region::RegionProviderChain;
use aws_sdk_sns::Client;

use lambda::error::HandlerError;
use std::error::Error;

// {
//   "device_id": "23lk4j2kl3j234",
//   "name": "Harrison",
//   "location": "Home",
//   "event": "ARRIVE" // ARRIVE | LEAVE
// }
#[derive(Deserialize, Clone)]
struct CustomEvent {}

#[derive(Serialize, Clone)]
struct CustomOutput {
	message: String,
}

fn main() -> Result<(), Box<dyn Error>> {
	simple_logger::init_with_level(log::Level::Info)?;
	lambda!(handle_arrival);

	Ok(())
}

fn handle_arrival(_: CustomEvent, _: lambda::Context) -> Result<CustomOutput, HandlerError> {
	let region_provider = RegionProviderChain::default_provider().or_else("us-east-2");
	let config = aws_config::from_env().region(region_provider).load().await;
	let client = Client::new(&config);

	Ok(CustomOutput {
		message: String::from("success"),
	})
}
