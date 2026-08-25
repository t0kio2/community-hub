# VPCの作成
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true # DNSホスト名を有効化
  tags = {
    Name = "${var.resource_prefix}-vpc"
  }
}

# サブネット
resource "aws_subnet" "public_1a_sn" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.availability_zone}"

  tags = {
    Name = "${var.resource_prefix}-sn-public-1a"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.resource_prefix}-igw"
  }
}

# Route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.resource_prefix}-rt-public"
  }
}

# SubnetとRoute tableの関連付け
resource "aws_route_table_association" "public_rt_associate" {
  subnet_id = aws_subnet.public_1a_sn.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
# 自分のパブリックIP取得
data "http" "ifconfig" {
  url = "https://ipv4.icanhazip.com/"
}

variable "allowed_cidr" {
  default = null
}

locals {
  my_ip = chomp(data.http.ifconfig.response_body)
  allowed_cidr = (var.allowed_cidr == null) ? "${local.my_ip}/32" : var.allowed_cidr
}

# Security Group作成
resource "aws_security_group" "ec2_sg" {
  name = "${var.resource_prefix}-sg-ec2"
  description = "for EC2"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.resource_prefix}-sg-ec2"
  }

  # インバウンドルール
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  # アウトバウンドルール
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}