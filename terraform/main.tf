terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source              = "./modules/vpc"
  name                = var.name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  az                  = var.az
}

module "nat" {
  source           = "./modules/nat_gateway"
  name             = var.name
  public_subnet_id = module.vpc.public_subnet_id
  depends_on       = [module.vpc] # đảm bảo IGW đã gắn xong trước khi tạo NAT
}

module "routes" {
  source            = "./modules/route_tables"
  name              = var.name
  vpc_id            = module.vpc.vpc_id
  igw_id            = module.vpc.igw_id
  nat_gateway_id    = module.nat.nat_gateway_id
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
}

module "sg" {
  source     = "./modules/security_groups"
  name       = var.name
  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = var.my_ip_cidr
}

module "public_ec2" {
  source              = "./modules/ec2"
  name                = "${var.name}-public-ec2"
  subnet_id           = module.vpc.public_subnet_id
  security_group_id   = module.sg.public_ec2_sg_id
  key_name            = var.key_name
  instance_type       = var.instance_type
  associate_public_ip = true
}

module "private_ec2" {
  source              = "./modules/ec2"
  name                = "${var.name}-private-ec2"
  subnet_id           = module.vpc.private_subnet_id
  security_group_id   = module.sg.private_ec2_sg_id
  key_name            = var.key_name
  instance_type       = var.instance_type
  associate_public_ip = false
  depends_on          = [module.routes] # có route qua NAT rồi mới tạo
}
