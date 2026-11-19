#!/usr/bin/env bash
# Dùng: bash tests/test.sh <name-prefix> [region]
# Ví dụ: bash tests/test.sh nt548-tf us-east-1
NAME=${1:-nt548-tf}
REGION=${2:-us-east-1}
FAILED=0

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; FAILED=1; }
check() { # check "mô tả" "giá trị thực" "mẫu mong đợi (glob)"
  [[ "$2" == $3 ]] && pass "$1 ($2)" || fail "$1 (nhận được: '$2', mong đợi: '$3')"
}
q() { aws --region "$REGION" --output text "$@"; }

VPC_ID=$(q ec2 describe-vpcs --filters "Name=tag:Name,Values=${NAME}-vpc" --query 'Vpcs[0].VpcId')
check "TC1 VPC tồn tại" "$VPC_ID" "vpc-*"

CIDR=$(q ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].CidrBlock')
check "TC2 VPC CIDR" "$CIDR" "10.0.0.0/16"

PUB_SUBNET=$(q ec2 describe-subnets --filters "Name=tag:Name,Values=${NAME}-public-subnet" --query 'Subnets[0].SubnetId')
PRIV_SUBNET=$(q ec2 describe-subnets --filters "Name=tag:Name,Values=${NAME}-private-subnet" --query 'Subnets[0].SubnetId')
check "TC3 Public subnet tồn tại" "$PUB_SUBNET" "subnet-*"
check "TC4 Private subnet tồn tại" "$PRIV_SUBNET" "subnet-*"

IGW_STATE=$(q ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].Attachments[0].State')
check "TC5 IGW attach vào VPC" "$IGW_STATE" "available"

DEF_SG_RULES=$(q ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --query 'SecurityGroups[0].IpPermissions | length(@)')
check "TC6 Default SG không còn rule ingress" "$DEF_SG_RULES" "0"

PUB_RT_GW=$(q ec2 describe-route-tables --filters "Name=tag:Name,Values=${NAME}-public-rt" --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId | [0]")
check "TC7 Public RT: 0.0.0.0/0 -> IGW" "$PUB_RT_GW" "igw-*"

PRIV_RT_NAT=$(q ec2 describe-route-tables --filters "Name=tag:Name,Values=${NAME}-private-rt" --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].NatGatewayId | [0]")
check "TC8 Private RT: 0.0.0.0/0 -> NAT" "$PRIV_RT_NAT" "nat-*"

NAT_STATE=$(q ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[0].State')
NAT_SUBNET=$(q ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[0].SubnetId')
check "TC9 NAT Gateway available" "$NAT_STATE" "available"
check "TC10 NAT nằm ở public subnet" "$NAT_SUBNET" "$PUB_SUBNET"

PUB_SG_CIDR=$(q ec2 describe-security-groups --filters "Name=tag:Name,Values=${NAME}-public-ec2-sg" --query 'SecurityGroups[0].IpPermissions[0].IpRanges[0].CidrIp')
check "TC11 Public SG chỉ mở SSH cho 1 IP (/32)" "$PUB_SG_CIDR" "*/32"

PRIV_SG_SRC=$(q ec2 describe-security-groups --filters "Name=tag:Name,Values=${NAME}-private-ec2-sg" --query 'SecurityGroups[0].IpPermissions[0].UserIdGroupPairs[0].GroupId')
check "TC12 Private SG nhận SSH từ SG khác" "$PRIV_SG_SRC" "sg-*"

PUB_IP=$(q ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}-public-ec2" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress')
check "TC13 Public EC2 có public IP" "$PUB_IP" "*.*.*.*"

PRIV_PUB_IP=$(q ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}-private-ec2" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress')
check "TC14 Private EC2 KHÔNG có public IP" "$PRIV_PUB_IP" "None"

echo
[[ $FAILED -eq 0 ]] && echo "TẤT CẢ TEST ĐỀU PASS" || echo "CÓ TEST FAIL"
exit $FAILED