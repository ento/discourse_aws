output "app_name" {
  value = aws_elastic_beanstalk_application.main.name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.main.id
}
