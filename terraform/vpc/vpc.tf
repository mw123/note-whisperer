provider "aws" {
  region = "${var.aws_region}"
}

data "aws_availability_zones" "all" {}

resource "aws_vpc" "nw_vpc" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "nw-vpc"
  }

}

resource "aws_subnet" "api_subnet" {
  cidr_block = "10.0.0.32/27"
  vpc_id = "${aws_vpc.nw_vpc.id}"
  tags {
    Name = "public-subnet"
  }
  availability_zone = "${data.aws_availability_zones.all.names[0]}"
}

resource "aws_subnet" "db_subnet_az1" {
  cidr_block = "10.0.0.16/28"
  vpc_id = "${aws_vpc.nw_vpc.id}"
  tags {
    Name = "db-subnet-az1"
  }
  availability_zone = "${data.aws_availability_zones.all.names[1]}"
}

resource "aws_subnet" "db_subnet_az0" {
  cidr_block = "10.0.0.0/28"
  vpc_id = "${aws_vpc.nw_vpc.id}"
  tags {
    Name = "db-subnet-az0"
  }
  availability_zone = "${data.aws_availability_zones.all.names[0]}"
}
/*
resource "aws_subnet" "db_subnet_az2" {
  cidr_block = "10.0.0.8/29"
  vpc_id = "${aws_vpc.nw_vpc.id}"
  tags {
    Name = "db-subnet-az2"
  }
  availability_zone = "${data.aws_availability_zones.all.names[2]}"
}
*/
resource "aws_db_subnet_group" "rds_subnets" {
  name = "nw-rds-subnets"
  description = "RDS subnet group"
  subnet_ids = [
    "${aws_subnet.db_subnet_az0.id}",
    "${aws_subnet.db_subnet_az1.id}"]
    /*"${aws_subnet.db_subnet_az2.id}"]*/
}

