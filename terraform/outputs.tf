output "vpc_id" { value = module.vpc.vpc_id }
output "nat_public_ip" { value = module.nat.nat_public_ip }
output "public_ec2_public_ip" { value = module.public_ec2.public_ip }
output "private_ec2_private_ip" { value = module.private_ec2.private_ip }
