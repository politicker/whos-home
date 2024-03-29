
resource "aws_sns_topic" "whos_home" {
  name                             = "whos_home.fifo"
  fifo_topic                       = true
  content_based_deduplication      = true
  sqs_success_feedback_role_arn    = aws_iam_role.sns_logger.arn
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_logger.arn
  sqs_success_feedback_sample_rate = 100
}

resource "aws_sqs_queue" "whos_home_queue_quinn" {
  name                        = "whos_home_quinn.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
}

resource "aws_sqs_queue" "whos_home_queue_telegram_bot" {
  name                        = "whos_home_telegram.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  deduplication_scope         = "queue"
  fifo_throughput_limit       = "perQueue"
}

resource "aws_sns_topic_subscription" "whos_home_topic_subscription_quinn" {
  topic_arn = aws_sns_topic.whos_home.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.whos_home_queue_quinn.arn
}

resource "aws_sns_topic_subscription" "whos_home_topic_subscription_telegram_bot" {
  topic_arn = aws_sns_topic.whos_home.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.whos_home_queue_telegram_bot.arn
}

data "aws_lambda_function" "telegram_bot" {
  function_name = "post-to-telegram"
}

resource "aws_lambda_event_source_mapping" "telegram_bot" {
  event_source_arn = aws_sqs_queue.whos_home_queue_telegram_bot.arn
  function_name    = data.aws_lambda_function.telegram_bot.arn
}
