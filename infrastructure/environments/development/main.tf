terraform {
  required_version = ">= 1.10.0"

  # AWSプロバイダーのバージョンと取得元を固定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # tfstateの保存先
  backend "s3" {
    bucket = "dev-community-hub-tfstate-840851420588-ap-northeast-1-an"
    key = "community-hub/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
		# AWS DynamoDBを使わずに、S3単体で同時実行ロックを行う最新の設定
		use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

# 自分のパブリックIP取得用
provider "http" {}

module "vpc" {
  source = "../../modules/vpc"
  
  resource_prefix = var.resource_prefix
  availability_zone = var.availability_zone
}

module "ec2" {
  source = "../../modules/ec2"

  resource_prefix = var.resource_prefix
  availability_zone = var.availability_zone
  # 以下はVPCのoutputs.tfの値を参照する
  subnet_id = module.vpc.public_subnet_id
  security_group_id = module.vpc.ec2_security_group_id
  
  # ElasticIPはInternetGateway作成後に作る必要がある
  depends_on = [ module.vpc ]
}