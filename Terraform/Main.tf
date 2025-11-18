provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "mini-project-vpc" }
}
	resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = { Name = "mini-project-public-subnet" }
}
	resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "mini-project-igw" }
}

  resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "mini-project-public-rt" }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

  resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
	resource "aws_security_group" "web_sg" {
  name        = "mini-project-sg"
  description = "Allow SSH & HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mini-project-sg" }
}
	resource "aws_key_pair" "demo_key" {
  key_name   = "mini-project-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
resource "aws_instance" "web" {
  ami                    = "ami-02b8269d5e85954ef" # Ubuntu 20.04
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.demo_key.key_name
  associate_public_ip_address = true
  tags = { Name = "mini-project-ec2" }
}
