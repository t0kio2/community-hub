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
}

module "ec2" {
  source = "../../modules/ec2"
}