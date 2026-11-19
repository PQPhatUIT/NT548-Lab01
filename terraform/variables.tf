variable "region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "nt548-tf"
}
variable "az" {
  type    = string
  default = "us-east-1a"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_name" { type = string }
variable "my_ip_cidr" { type = string }
