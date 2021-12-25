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

data "aws_iam_policy" "lambda_sns_publisher_policy" {
	name = "AmazonSNSFullAccess"
}

data "aws_iam_policy_document" "lambda_sns_publisher_policy_doc" {
	policy_id = data.aws_iam_policy.lambda_sns_publisher_policy.policy_id
}

resource "aws_iam_role" "whos_home_lambda" {
	name = "whos_home_lambda"
	assume_role_policy = data.aws_iam_policy_document.lambda_sns_publisher_policy_doc.json
}

resource "aws_lambda_function" "location_change_handler" {
	function_name = "location_change_handler"
	role = aws_iam_role.whos_home_lambda.arn
}
