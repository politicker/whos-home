terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "whos-home"

    workspaces {
      name = "whos-home"
    }
  }
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}
