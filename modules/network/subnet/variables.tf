variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "public_az" {
  description = "Availability Zone for the public subnet"
  type        = string
}

variable "private_az" {
  description = "Availability Zone for the private subnet"
  type        = string
}
