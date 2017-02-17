output "db_host" {
  value = "${aws_db_instance.main.address}"
}

output "db_port" {
  value = "${aws_db_instance.main.port}"
}

output "db_endpoint" {
  value = "${aws_db_instance.main.endpoint}"
}
