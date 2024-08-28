provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  access_key                  = "test"
  secret_key                  = "test"
  endpoints {
    s3     = "http://s3.us-east-1.localhost.localstack.cloud:4566"
    lambda = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-lambda-test"
}

resource "aws_lambda_function" "process_s3_event" {
  function_name = "process_s3_event"
  handler       = "com.example.LambdaHandler::handleRequest"
  runtime       = "java11"
  memory_size   = 512
  filename      = "${path.module}/lambdaFunction-1.0-SNAPSHOT.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdaFunction-1.0-SNAPSHOT.zip")

  role = "arn:aws:iam::000000000000:role/lambda-role"

  environment {
    variables = {
      BUCKET_NAME   = aws_s3_bucket.bucket.bucket
      SQL_DATABASE  = "json_database"
      SQL_SERVER_HOST = "host.docker.internal"
      SQL_SERVER_PASS = "Passw0rd"
      SQL_SERVER_USER = "sa"
    }
  }

  depends_on = [
    aws_s3_bucket.bucket
  ]
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_s3_event.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_s3_event.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

