resource "aws_network_acl" "nw_acl" {
  vpc_id = "${aws_vpc.nw_vpc.id}"
  egress {
    protocol = "-1"
    rule_no = 2
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
  ingress {
    protocol = "-1"
    rule_no = 1
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
  tags {
    Name = "nw-acl"
  }
}

resource "aws_internet_gateway" "nw_gw" {
  vpc_id = "${aws_vpc.nw_vpc.id}"
  tags {
    Name = "nw-gw"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id = "${aws_subnet.api_subnet.id}"
  depends_on = ["aws_internet_gateway.nw_gw"]
}