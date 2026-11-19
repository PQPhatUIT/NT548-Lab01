variable "name" { type = string }
variable "vpc_id" { type = string }
variable "my_ip_cidr" {
  type = string
  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0)) && var.my_ip_cidr != "0.0.0.0/0"
    error_message = "my_ip_cidr phải là CIDR hợp lệ và không được là 0.0.0.0/0."
  }
}
