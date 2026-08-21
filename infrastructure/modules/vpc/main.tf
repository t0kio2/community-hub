# VPCの作成
resource "aws_vpc" "main" {
  cidr_block = "192.168.250.0/24"
  tags = {
    Name = "sandbox-terraform"
  }
}

# 別モジュールから本VPCのIDを参照するための記述
output "vpc_id" {
  value = aws_vpc.main.id
}