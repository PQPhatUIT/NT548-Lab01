resource "aws_security_group" "public_ec2" {
  name        = "${var.name}-public-ec2-sg"
  description = "Allow SSH from my IP only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name}-public-ec2-sg" }
}

resource "aws_security_group" "private_ec2" {
  name        = "${var.name}-private-ec2-sg"
  description = "Allow SSH from Public EC2 SG only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from Public EC2"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name}-private-ec2-sg" }
}
