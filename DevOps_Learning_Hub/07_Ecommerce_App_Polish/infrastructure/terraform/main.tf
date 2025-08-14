provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "ecommerce_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.ecommerce_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name        = "${var.environment}-nat-gw"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecommerce_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_rta" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Create security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.ecommerce_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}

# Create security group for ECS tasks
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecommerce_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
    Project     = "ecommerce"
    Terraform   = "true"
  }
}
