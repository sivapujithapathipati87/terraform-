provider "aws" {
  region = "us-west-2"  # Replace with desired region
}

# Create an S3 bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-example-bucket-123456"  # Replace with a unique bucket name
  acl    = "private"

  tags = {
    Name        = "MyExampleBucket"
    Environment = "Dev"
  }
}

# Create a VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "example_vpc"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
  
  tags = {
    Name = "example_igw"
  }
}

# Create a subnet
resource "aws_subnet" "example_subnet" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "example_subnet"
  }
}

# Create a security group
resource "aws_security_group" "example_sg" {
  vpc_id = aws_vpc.example_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "example_sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "example_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with a valid AMI ID for your region
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.example_subnet.id
  security_groups        = [aws_security_group.example_sg.name]

  tags = {
    Name = "ExampleInstance"
  }
}

output "instance_id" {
  value = aws_instance.example_instance.id
}

output "bucket_name" {
  value = aws_s3_bucket.example_bucket.id
}
