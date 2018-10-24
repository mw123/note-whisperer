provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "all" {}

module "nw_vpc" {
  source = "vpc"
}

module "nw-cluster" {
  source = "ecs-cluster"

  name = "nw-cluster"
  size = 2
  instance_type = "t2.micro"
  vpc_id = "${module.nw_vpc.vpc_id}"
  subnet_ids = "${module.nw_vpc.public_subnet_id}"
  key_pair_name = "${var.fellow_name}-IAM-keypair"
  associate_public_ip_address = true
}

module "kgs-task" {
  source = "ecs-task"

  name = "nw-kgs-task"
  ecs_cluster_id = "${module.nw-cluster.ecs_cluster_id}"
  image = "${var.ecr_url_kgs}"
  image_version = "latest"
  cpu = 0
  memory = 900
  container_port = 5001
  host_port = 5001
  desired_count = 1
  num_env_vars = 5
  env_vars = "${map("DB_HOST", "${aws_db_instance.nw_mysql.address}",
                    "DB_USER", "${aws_db_instance.nw_mysql.username}",
                    "DB_PASSWD", "${aws_db_instance.nw_mysql.password}",
                    "KEY_DB_NAME", "${aws_db_instance.nw_mysql.name}",
                    "MSG_DB_NAME", "msg_db")}"
}

module "server-service" {
  source = "ecs-service"

  name = "nw-server-service"
  ecs_cluster_id = "${module.nw-cluster.ecs_cluster_id}"
  image = "${var.ecr_url_server}"
  image_version = "latest"
  cpu = 0
  memory = 900
  container_port = 80
  host_port = 80
  desired_count = 1
  elb_name = "${aws_elb.nw_elb.id}"
  num_env_vars = 6
  env_vars = "${map("SERVER_HOST", "${aws_elb.nw_elb.dns_name}",
                    "DB_HOST", "${aws_db_instance.nw_mysql.address}",
                    "DB_USER", "${aws_db_instance.nw_mysql.username}",
                    "DB_PASSWD", "${aws_db_instance.nw_mysql.password}",
                    "KEY_DB_NAME", "${aws_db_instance.nw_mysql.name}",
                    "MSG_DB_NAME", "msg_db")}"
  depends_on = ["module.kgs-task"]
}

resource "aws_elb" "nw_elb" {
  name = "nw-elb-primary"
  security_groups = ["${aws_security_group.elb_sg.id}"]
  subnets = ["${module.nw_vpc.public_subnet_id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }
}

resource "aws_security_group" "elb_sg" {
  name = "nw-elb-sg-primary"
  vpc_id = "${module.nw_vpc.vpc_id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "nw_mysql" {
  allocated_storage = 20 # 100 GB of storage, gives us more IOPS than a lower number
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro" # use micro if you want to use the free tier
  identifier = "nw-mysql"
  name = "keys_db"
  username = "root" # username
  password = "notewhisperer" # password
  db_subnet_group_name = "${module.nw_vpc.db_subnet_group}"
  multi_az = "false" # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]
  storage_type = "gp2"
  backup_retention_period = 30 # how long you’re going to keep your backups
  skip_final_snapshot = true

  tags {
    Name = "nw-db-instance"
  }
}

resource "aws_security_group" "db_sg" {
  name = "nw-db-sg"
  tags {
    Name = "nw-db-sg"
  }
  vpc_id = "${module.nw_vpc.vpc_id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${module.nw-cluster.security_group_id}"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}