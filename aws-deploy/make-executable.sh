#!/bin/bash

# Make AWS deployment scripts executable

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[SCRIPT]${NC} $1"
}

print_status "🚀 Making AWS deployment scripts executable..."

# Find all shell scripts in aws-deploy directory and make them executable
find . -name "*.sh" -type f | while read script; do
    chmod +x "$script"
    print_info "Made executable: $script"
done

print_status "✅ All AWS deployment scripts are now executable!"
print_status ""
print_status "📋 Available deployment scripts:"
print_status "  Elastic Beanstalk: ./elastic-beanstalk/deploy-eb.sh"
print_status "  Amazon EKS:        ./eks/deploy-eks.sh"
print_status "  Amazon ECS:        ./ecs-fargate/deploy-ecs.sh"
print_status ""
print_status "🔧 Utility scripts:"
print_status "  AWS CLI Setup:     ./scripts/setup-aws-cli.sh"
print_status "  ECR Setup:         ./scripts/create-ecr-repo.sh"
print_status "  Build & Push:      ./scripts/build-and-push.sh"
