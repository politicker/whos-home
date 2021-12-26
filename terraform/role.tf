

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

data "aws_iam_policy" "AmazonSNSFullAccess" {
  name = "AmazonSNSFullAccess"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.whos_home_lambda.name
  policy_arn = data.aws_iam_policy.AmazonSNSFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.whos_home_lambda.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}
