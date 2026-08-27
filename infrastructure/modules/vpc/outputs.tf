output "public_subnet_id" {
	description = "publicサブネットID"
	value = aws_subnet.public_1a_sn.id
}

output "ec2_security_group_id" {
	description = "EC2用セキュリティグループID"
	value = aws_security_group.ec2_sg.id
}
