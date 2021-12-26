terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "whos-home"

    workspaces {
      name = "whos-home"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.whos_home_gateway_stage.invoke_url
}
