terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region                  = "us-east-1"
  //shared_config_files      = ["~/.aws/config"]
  //shared_credentials_files = ["~/.aws/credentials"]
  //profile                 = "veera"
}