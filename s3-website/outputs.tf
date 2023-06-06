output "web_server_name" {
  description = "Name of S3 WebServer"
  value       = aws_s3_bucket.web_server.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.web_server_config.website_endpoint
}

output "website_domain" {
  value = aws_s3_bucket_website_configuration.web_server_config.website_domain
}

output "domain" {
  value = aws_s3_bucket.web_server.bucket
}