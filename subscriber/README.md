# Subscriber

The subscriber is a Rust program that:

- subscribes to an AWS SQS queue
- operates the Raspberry Pi GPIO in response to messages from the queue

The messages are JSON in the following shape:

```json
{
  "name": "Harrison",
  "location": "Home",
  "event": "ARRIVE"
}
```

Messages on the queue signify that a person running `whos-home` on another Raspberry Pi has either left or arrived at their house.
