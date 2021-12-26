resource "aws_apigatewayv2_api" "whos_home_gateway" {
  name          = "whos_home_gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "whos_home_gateway_stage" {
  api_id = aws_apigatewayv2_api.whos_home_gateway.id

  name        = "whos_home_gateway_production"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.gateway_log_group.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

data "aws_lambda_function" "lambda" {
  function_name = "location_change_handler"
}

resource "aws_apigatewayv2_integration" "gateway_lambda_integration" {
  api_id = aws_apigatewayv2_api.whos_home_gateway.id

  integration_uri    = data.aws_lambda_function.lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "gateway_route" {
  api_id = aws_apigatewayv2_api.whos_home_gateway.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.gateway_lambda_integration.id}"
}

resource "aws_cloudwatch_log_group" "gateway_log_group" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.whos_home_gateway.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.whos_home_gateway.execution_arn}/*/*"
}
