# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az
  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 퍼블릭 라우트 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.public_route_table_name != null ? var.public_route_table_name : "${var.project_name}-public-rt"
  }
}

# IGW로 0.0.0.0/0 경로 추가
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# 퍼블릭 서브넷에 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 보안 그룹 생성 
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP, and ping"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # ping
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# 인스턴스 생성 
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true # 퍼블릭 IP 자동 할당 
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.ec2_key_name

  tags = {
    Name = "${var.project_name}-web"
  }
}

# 최신 우분투 AMI 가져오기
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical 공식 계정

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}