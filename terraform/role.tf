

resource "aws_iam_role" "whos_home_lambda" {
  name = "whos_home_lambda"
  path = "/"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "ec2.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

data "aws_iam_policy" "lambda_sns_publisher_policy" {
  name = "AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.whos_home_lambda.name
  policy_arn = data.aws_iam_policy.lambda_sns_publisher_policy.arn
}
