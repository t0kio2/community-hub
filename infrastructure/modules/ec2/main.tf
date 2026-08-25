# EC2 Keyペア
locals {
	key_name = "${var.resource_prefix}-ec2-keypair"
}

# 秘密鍵のアルゴリズム設定
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

# ローカルPCにKeyペアを作成
# terraform apply実行後は、ローカルPCの公開鍵は自動削除される
locals {
  private_key_file = "${path.root}/.keys/${local.key_name}.pem"
}

resource "local_sensitive_file" "private_key_pem" {
  filename = "${local.private_key_file}"
  content = "${tls_private_key.private_key.private_key_pem}"
	file_permission = "0600"
}

# 上記で作成した公開鍵をAWS Keyペアにインポート
resource "aws_key_pair" "keypair" {
  key_name = local.key_name
  public_key = "${tls_private_key.private_key.public_key_openssh}"
}

# EC2
# Amazon Linux2の最新版AMIを取得
data "aws_ssm_parameter" "amzn2_latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2作成
resource "aws_instance" "ec2" {
	ami = data.aws_ssm_parameter.amzn2_latest_ami.value
	instance_type = "t2.micro"
	availability_zone = "${var.availability_zone}"
	vpc_security_group_ids = [var.security_group_id]
	subnet_id = var.subnet_id
	# 自動割り当てされたpublic idは、outputs.tfで出力する
	associate_public_ip_address = true
	key_name = aws_key_pair.keypair.key_name
	tags = {
		Name = "${var.resource_prefix}-ec2"
	}
}

# Elastic IP作成
# NOTE: Elastic IPはEC2停止中もコストがかかる.必要になった際に有効化する.
# resource "aws_eip" "eip" {
# 	instance = aws_instance.ec2.id
# 	domain = "vpc"

# 	tags = {
# 		Name = "${var.resource_prefix}-eip"
# 	}
# }