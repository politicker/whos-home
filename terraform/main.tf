resource "aws_sns_topic" "whos_home" {
	name = "whos_home.fifo"
	fifo_topic = true
	content_based_deduplication = true
}

resource "aws_sqs_queue" "whos_home_queue_quinn" {
  name = "whos_home_quinn.fifo"
	fifo_queue = true
	content_based_deduplication = true
}

resource "aws_sns_topic_subscription" "whos_home_topic_subscription_quinn" {
	topic_arn = aws_sns_topic.whos_home.arn
	protocol  = "sqs"
	endpoint = aws_sqs_queue.whos_home_queue_quinn.arn
}

resource "aws_iam_role" "whos_home_lambda" {
	name = "whos_home_lambda"
	assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sns:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
	})
}

# Error: handler and runtime must be set when PackageType is Zip
resource "aws_lambda_function" "location_change_handler" {
	function_name = "location_change_handler"
	role = aws_iam_role.whos_home_lambda.arn
	runtime = "provided.al2"
	handler = "handle_arrival"
}
