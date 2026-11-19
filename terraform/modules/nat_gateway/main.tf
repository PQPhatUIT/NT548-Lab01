resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id # NAT phải nằm ở PUBLIC subnet
  tags          = { Name = "${var.name}-nat" }
}
