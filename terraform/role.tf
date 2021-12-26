
resource "aws_iam_role" "whos_home_lambda" {
  name = "whos_home_lambda"
  path = "/"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : [
            "ec2.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role" "sns_logger" {
  name = "sns_logger"
  path = "/"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:*"
        ],
        "Effect" : "Allow",
      }
    ]
  })
}

data "aws_iam_policy" "AmazonSNSFullAccess" {
  name = "AmazonSNSFullAccess"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "CloudWatchLogsFullAccess" {
  name = "CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_AmazonSNSFullAccess" {
  role       = aws_iam_role.whos_home_lambda.name
  policy_arn = data.aws_iam_policy.AmazonSNSFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "attach_AWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.whos_home_lambda.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_iam_role_policy_attachment" "attach_CloudWatchLogsFullAccess" {
  role       = aws_iam_role.sns_logger.name
  policy_arn = data.aws_iam_policy.CloudWatchLogsFullAccess.arn
}

data "aws_iam_policy_document" "sqs_access" {
  statement {
    sid = "1"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.whos_home_queue_telegram_bot.arn
    ]
  }
}

resource "aws_iam_policy" "sqs_access" {
  name   = "whos_home_lambda_sqs_access"
  policy = data.aws_iam_policy_document.sqs_access.json
}

resource "aws_iam_role_policy_attachment" "sqs_access" {
  role       = aws_iam_role.whos_home_lambda.name
  policy_arn = aws_iam_policy.sqs_access.arn
}
