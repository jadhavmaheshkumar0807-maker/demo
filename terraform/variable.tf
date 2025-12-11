variable "region" {
    description = "Region to create Instance"
    default = "us-east-1"
    type = string
}

variable "key_name" {
    description = "key name"
    default = "AWS-key"
    type = string  
}

variable "vpc_cidr_block" {
    description = "CIDR block for VPC"
    default = "20.90.0.0/16"
}

variable "subnet_cidr_block" {
    description = "CIDR block for subnet"
    default = "20.90.5.0/24"
}


variable "availability_zone" {
    description = "Availability zone for the Subnet to create"
    default = "us-east-1a"
    type = string
}

variable "instance_type" {
    description = "type of the instance"
    default = "c7i-flex.large"
    type = string  
}

variable "aws_ami" {
  description = "ami for the instance"
  default = "ami-068c0051b15cdb816"
}