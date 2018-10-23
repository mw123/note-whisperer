output "elb_dns_name" {
  value = "${aws_elb.nw_elb.dns_name}"
}