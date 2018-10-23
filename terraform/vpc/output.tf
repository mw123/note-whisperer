output "vpc_id" {
  value = "${aws_vpc.nw_vpc.id}"
}

output "public_subnet_id" {
  value = ["${aws_subnet.api_subnet.id}"]
}

output "db_subnet_group" {
  value = "${aws_db_subnet_group.rds_subnets.id}"
}