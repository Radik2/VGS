provider "aws" {
   region = "us-east-1"
}


resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "air_conditions"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "eventDateTime"
  range_key      = "air_station"

  attribute {
    name = "eventDateTime"
    type = "S"
  }

  attribute {
    name = "air_station"
    type = "S"
  }


}


resource "aws_lambda_function" "myLambda" {
   function_name = "firstFunction"

   
   s3_bucket = "radik123"
   s3_key    = "lambda_function.zip"

   
   handler = "lambda_function.lambda_handler"
   runtime = "python3.6"

   role = aws_iam_role.lambda_role.arn
}


resource "aws_iam_role" "lambda_role" {
   name = "role_lambda"

   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_api_gateway_rest_api" "apiLambda" {
  name        = "myAPI"
}



resource "aws_api_gateway_resource" "api_res" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   path_part   = "mydemoresource"
}

resource "aws_api_gateway_method" "Method" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.api_res.id
   http_method   = "POST"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.Method.resource_id
   http_method = aws_api_gateway_method.Method.http_method

   integration_http_method = "POST"
   type                    = "AWS"
   uri                     = aws_lambda_function.myLambda.invoke_arn
}





resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [
     aws_api_gateway_integration.lambda
   ]

   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   stage_name  = "test"
}


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.myLambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/*/*"
}


output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}
