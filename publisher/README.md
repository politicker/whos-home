# Publisher

The publisher is a Rust program that:

- scans the home wifi network via [`arp-scan`](https://google.com)
- searches for your phone's MAC address on the WiFi
- publishes SNS messages when your phone connectes/disconnects to the WiFi

## Configuration

- install `arp-scan`
- setup `.env` file

```sh
CONFIG_PATH=/path/to/config.yaml
SNS_TOPIC_ARN=arn:aws:sns:us:region:stuff:find:this:on:aws:console
```

When you set this command up with systemctrl, make sure to set the env vars:

```bash
CONFIG_PATH=/path/to/config.yaml SNS_TOPIC_ARN=wlekrjew publisher
```

Or optionally set these in the `.bashrc` of the Pi, but be sure that systemctrl loads that `.rc` file when it spawns processes.
