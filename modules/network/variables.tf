variable "project_name" {
  type        = string
  description = "Prefix for naming resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
}

variable "public_az" {
  type        = string
  description = "Availability Zone for the public subnet"
}

variable "private_az" {
  type        = string
  description = "Availability Zone for the private subnet"
}
variable "public_route_table_name" {
  type    = string
  default = null
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_key_name" {
  type = string
}