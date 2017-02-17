output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnet" {
  value = "${module.vpc.public_subnets[0]}"
}

output "private_subnets" {
  value = ["${module.vpc.private_subnets}"]
}

output "default_security_group_id" {
  value = "${module.vpc.default_security_group_id}"
}

output "db_security_group_id" {
  value = "${aws_security_group.db.id}"
}

output "web_security_group_id" {
  value = "${aws_security_group.web.id}"
}
