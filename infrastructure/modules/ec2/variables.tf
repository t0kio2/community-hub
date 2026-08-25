variable "resource_prefix" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "subnet_id" {
  description = "EC2を配置するサブネットのID"
  type = string
}

variable "security_group_id" {
  description = "EC2に設定するセキュリティグループのID"
  type = string
}
