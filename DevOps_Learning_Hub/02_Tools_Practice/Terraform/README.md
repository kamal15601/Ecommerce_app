# Terraform Infrastructure as Code Labs 🏗️

## Overview
Terraform is an open-source Infrastructure as Code (IaC) tool that allows you to define, provision, and manage cloud infrastructure using declarative configuration files. This comprehensive guide covers Terraform from basics to advanced enterprise patterns.

## Prerequisites
- Terraform installed (latest version)
- Cloud provider account (AWS/Azure/GCP)
- Basic understanding of cloud services
- Text editor or IDE

## Labs Structure

### Lab 1: Terraform Basics and First Resource

#### Installation and Setup
```bash
# Install Terraform (Linux/macOS)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Terraform (Windows with Chocolatey)
choco install terraform

# Verify installation
terraform --version

# Enable tab completion
terraform -install-autocomplete
```

#### First Configuration - AWS S3 Bucket
**main.tf**:
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "my-terraform-bucket"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

resource "aws_s3_bucket" "example" {
  bucket = "${var.bucket_name}-${var.environment}-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "My bucket"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "example" {
  bucket = aws_s3_bucket.example.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.example.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.example.arn
}
```

#### Basic Commands
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Destroy infrastructure
terraform destroy
```

### Lab 2: Variables, Outputs, and Data Sources

#### variables.tf
```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myproject"
  
  validation {
    condition     = length(var.project_name) > 2 && length(var.project_name) < 20
    error_message = "Project name must be between 3 and 19 characters."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_types" {
  description = "Map of instance types for different environments"
  type        = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "MyProject"
    ManagedBy = "Terraform"
  }
}
```

#### outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.web[*].public_ip
  sensitive   = false
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
```

#### data.tf
```hcl
# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get existing VPC (if referencing existing infrastructure)
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}
```

### Lab 3: Complex Infrastructure - Multi-Tier Application

#### vpc.tf
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-gateway-${count.index + 1}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

#### security_groups.tf
```hcl
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-web-sg"
  })
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL/Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-sg"
  })
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-bastion-sg"
  })
}
```

#### compute.tf
```hcl
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_types[var.environment]
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint = aws_rds_cluster.main.endpoint
    s3_bucket   = aws_s3_bucket.app_data.bucket
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-web-server"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = var.tags
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

### Lab 4: State Management and Remote Backends

#### backend.tf
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

#### Setting up S3 Backend
**bootstrap/main.tf**:
```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "bootstrap"
  }
}
```

#### State Commands
```bash
# List state resources
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state
terraform state rm aws_instance.example

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Pull remote state
terraform state pull

# Push state to remote
terraform state push terraform.tfstate
```

### Lab 5: Modules and Code Organization

#### Creating a VPC Module
**modules/vpc/main.tf**:
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# ... rest of VPC resources ...

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}
```

#### Using Modules
**main.tf**:
```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr               = var.vpc_cidr
  project_name           = var.project_name
  availability_zones     = data.aws_availability_zones.available.names
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  enable_nat_gateway     = var.enable_nat_gateway
  tags                   = var.tags
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  tags         = var.tags
}

module "compute" {
  source = "./modules/compute"

  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = module.security_groups.web_sg_id
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags
}
```

#### Module from Registry
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = var.tags
}
```

### Lab 6: Workspaces and Environment Management

#### Workspace Commands
```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete old-env
```

#### Environment-Specific Configuration
**terraform.tfvars.dev**:
```hcl
environment         = "dev"
instance_type       = "t3.micro"
min_size           = 1
max_size           = 2
desired_capacity   = 1
enable_monitoring  = false
backup_retention   = 7
```

**terraform.tfvars.prod**:
```hcl
environment         = "prod"
instance_type       = "t3.large"
min_size           = 2
max_size           = 10
desired_capacity   = 3
enable_monitoring  = true
backup_retention   = 30
```

#### Using Workspaces in Configuration
```hcl
locals {
  environment = terraform.workspace
  
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }

  instance_counts = {
    dev     = 1
    staging = 2
    prod    = 3
  }
}

resource "aws_instance" "web" {
  count         = local.instance_counts[local.environment]
  instance_type = var.instance_types[local.environment]
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
  })
}
```

### Lab 7: Advanced Terraform Features

#### Dynamic Blocks
```hcl
resource "aws_security_group" "dynamic_example" {
  name   = "dynamic-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]
}
```

#### Conditional Resources
```hcl
resource "aws_instance" "conditional" {
  count = var.create_instance ? 1 : 0
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  tags = {
    Name = "Conditional Instance"
  }
}

resource "aws_autoscaling_group" "conditional" {
  count = var.environment == "prod" ? 1 : 0
  
  name                = "prod-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = 2
  max_size            = 10
  desired_capacity    = 3
}
```

#### For Expressions and Functions
```hcl
locals {
  # Create map from list
  subnet_map = {
    for idx, subnet in aws_subnet.private :
    subnet.availability_zone => subnet.id
  }
  
  # Filter and transform
  prod_instances = [
    for instance in aws_instance.web :
    instance.id
    if instance.tags.Environment == "prod"
  ]
  
  # Complex transformations
  user_permissions = {
    for user in var.users :
    user.name => {
      role        = user.role
      permissions = lookup(var.role_permissions, user.role, [])
      groups      = user.groups
    }
  }
}

# Using built-in functions
resource "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      for bucket in aws_s3_bucket.buckets :
      "${bucket.arn}/*"
    ]
  }
}
```

### Lab 8: Testing and Validation

#### Terraform Testing
**tests/vpc_test.go**:
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../examples/vpc",
        Vars: map[string]interface{}{
            "vpc_cidr":      "10.0.0.0/16",
            "project_name":  "test",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

#### Policy as Code with Sentinel
**policy/aws-instance-type.sentinel**:
```sentinel
import "tfplan/v2" as tfplan

allowed_instance_types = ["t3.micro", "t3.small", "t3.medium"]

deny_instance_types = func() {
    violations = []
    
    for tfplan.resource_changes as _, rc {
        if rc.type is "aws_instance" and
           rc.mode is "managed" and
           rc.change.actions contains "create" {
            
            instance_type = rc.change.after.instance_type
            if instance_type not in allowed_instance_types {
                violations = append(violations, {
                    "address": rc.address,
                    "instance_type": instance_type,
                })
            }
        }
    }
    
    return violations
}

violations = deny_instance_types()

main = rule {
    length(violations) is 0
}
```

#### Custom Validation Rules
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium",
      "t3.large", "m5.large", "m5.xlarge"
    ], var.instance_type)
    error_message = "Instance type must be from approved list."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}
```

### Lab 9: CI/CD Integration

#### GitHub Actions Workflow
**.github/workflows/terraform.yml**:
```yaml
name: Terraform CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  TF_VERSION: 1.5.0
  AWS_REGION: us-west-2

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        environment: [dev, staging, prod]
        
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: ${{ env.TF_VERSION }}
        
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Terraform Init
      run: terraform init
      working-directory: environments/${{ matrix.environment }}
      
    - name: Terraform Validate
      run: terraform validate
      working-directory: environments/${{ matrix.environment }}
      
    - name: Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: environments/${{ matrix.environment }}
      
    - name: Upload Plan
      uses: actions/upload-artifact@v3
      with:
        name: tfplan-${{ matrix.environment }}
        path: environments/${{ matrix.environment }}/tfplan
        
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && matrix.environment != 'prod'
      run: terraform apply -auto-approve tfplan
      working-directory: environments/${{ matrix.environment }}
      
    - name: Production Approval
      if: github.ref == 'refs/heads/main' && matrix.environment == 'prod'
      uses: trstringer/manual-approval@v1
      with:
        secret: ${{ github.TOKEN }}
        approvers: devops-team
        
    - name: Terraform Apply Production
      if: github.ref == 'refs/heads/main' && matrix.environment == 'prod'
      run: terraform apply -auto-approve tfplan
      working-directory: environments/${{ matrix.environment }}
```

#### Atlantis Configuration
**atlantis.yaml**:
```yaml
version: 3
projects:
- name: dev
  dir: environments/dev
  terraform_version: v1.5.0
  autoplan:
    when_modified: ["*.tf", "*.tfvars"]
    enabled: true
  apply_requirements: ["approved"]
  
- name: staging
  dir: environments/staging
  terraform_version: v1.5.0
  autoplan:
    when_modified: ["*.tf", "*.tfvars"]
    enabled: true
  apply_requirements: ["approved"]
  
- name: prod
  dir: environments/prod
  terraform_version: v1.5.0
  autoplan:
    when_modified: ["*.tf", "*.tfvars"]
    enabled: true
  apply_requirements: ["approved", "mergeable"]
  
workflows:
  default:
    plan:
      steps:
      - run: terraform fmt -check
      - init
      - plan
    apply:
      steps:
      - apply
```

### Lab 10: Multi-Cloud and Advanced Patterns

#### Multi-Cloud Setup
```hcl
# AWS Provider
provider "aws" {
  region = var.aws_region
  alias  = "aws"
}

# Azure Provider
provider "azurerm" {
  features {}
  alias = "azure"
}

# GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  alias   = "gcp"
}

# AWS Resources
resource "aws_s3_bucket" "aws_storage" {
  provider = aws.aws
  bucket   = "${var.project_name}-aws-storage"
}

# Azure Resources
resource "azurerm_resource_group" "main" {
  provider = azurerm.azure
  name     = "${var.project_name}-rg"
  location = var.azure_location
}

resource "azurerm_storage_account" "azure_storage" {
  provider                 = azurerm.azure
  name                     = "${var.project_name}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# GCP Resources
resource "google_storage_bucket" "gcp_storage" {
  provider = google.gcp
  name     = "${var.project_name}-gcp-storage"
  location = var.gcp_region
}
```

#### Blue-Green Deployment Pattern
```hcl
locals {
  environments = {
    blue = {
      weight = var.blue_weight
      image  = var.blue_image
    }
    green = {
      weight = var.green_weight
      image  = var.green_image
    }
  }
}

resource "aws_lb_target_group" "app" {
  for_each = local.environments
  
  name     = "${var.project_name}-${each.key}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "weighted" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = local.environments
        content {
          arn    = aws_lb_target_group.app[target_group.key].arn
          weight = target_group.value.weight
        }
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

## Best Practices

### 1. Code Organization
```
terraform-project/
├── modules/
│   ├── vpc/
│   ├── compute/
│   └── database/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── policies/
├── tests/
└── docs/
```

### 2. Security Best Practices
```hcl
# Use data sources for sensitive values
data "aws_ssm_parameter" "db_password" {
  name = "/app/database/password"
}

# Enable encryption
resource "aws_s3_bucket_encryption" "example" {
  bucket = aws_s3_bucket.example.id
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Use least privilege IAM
resource "aws_iam_policy" "app_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.app_data.arn}/*"
      }
    ]
  })
}
```

### 3. Resource Naming
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.team_name
    CostCenter  = var.cost_center
  }
}

resource "aws_instance" "web" {
  # Consistent naming
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-${count.index + 1}"
    Role = "WebServer"
  })
}
```

### 4. Error Handling
```hcl
# Use try() function for optional values
resource "aws_instance" "example" {
  instance_type = try(var.instance_types[var.environment], "t3.micro")
  
  # Handle potential null values
  subnet_id = try(aws_subnet.private[0].id, null)
}

# Lifecycle management
resource "aws_s3_bucket" "important" {
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}
```

## Troubleshooting

### Common Commands
```bash
# Debug output
export TF_LOG=DEBUG
terraform plan

# Refresh state
terraform refresh

# Force resource recreation
terraform taint aws_instance.web
terraform apply

# Check state consistency
terraform plan -detailed-exitcode

# Fix state drift
terraform import aws_instance.example i-1234567890abcdef0
```

### State Issues
```bash
# Unlock state
terraform force-unlock LOCK_ID

# Backup state
terraform state pull > backup.tfstate

# Restore state
terraform state push backup.tfstate
```

This comprehensive Terraform guide covers Infrastructure as Code from basics to enterprise-level patterns, providing hands-on experience with real-world scenarios and best practices.
