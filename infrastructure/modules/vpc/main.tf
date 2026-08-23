# VPCの作成
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true # DNSホスト名を有効化
  tags = {
    Name = "${var.resource_prefix}-vpc"
  }
}

# 別モジュールから本VPCのIDを参照するための記述
output "vpc_id" {
  value = aws_vpc.main.id
}