provider "aws" {
  access_key           = ""
  secret_access_key    = ""
  region               = "eu-central-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name"             = var.EnvironmentName
    "Group"            = var.GroupStaff
  }
}