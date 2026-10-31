terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}

provider "aws" {
  access_key = "Test"
  secret_key = "Test"
  region = "us-east-1"

  endpoints {
    ec2      = "http://localhost:4566"
  }
}

### Basic Example: Create a EC2 instance in LocalStack"
resource "aws_instance" "example" {
  ami           = "ami-test"
  instance_type = "t2.micro"
}

