/*
variable "keypair_name" {
  description = "The name of your pre-made key-pair in Amazon" 
} 
*/

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default = "10.0.0.0/26"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-west-2"
}

