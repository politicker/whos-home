# Location Change Handler

This lambda is wrapped in an API Gateway, to allow connectivity from an iOS shortcut. It relays any HTTP messages as events on a SNS topic.

Specifically, it should receive HTTP requests with a json body of type (undefined / no type def currently).
