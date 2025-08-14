#!/bin/bash

# AWS CLI Setup Script for E-commerce Application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
check_aws_cli() {
    if command -v aws &> /dev/null; then
        print_status "✅ AWS CLI is already installed"
        aws --version
        return 0
    else
        return 1
    fi
}

# Install AWS CLI
install_aws_cli() {
    print_status "📦 Installing AWS CLI..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux installation
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if command -v brew &> /dev/null; then
            brew install awscli
        else
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows installation
        print_status "For Windows, please download and install AWS CLI from:"
        print_status "https://awscli.amazonaws.com/AWSCLIV2.msi"
        exit 1
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_status "✅ AWS CLI installed successfully"
}

# Configure AWS CLI
configure_aws_cli() {
    print_status "⚙️ Configuring AWS CLI..."
    
    # Check if already configured
    if aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS CLI is already configured"
        CURRENT_USER=$(aws sts get-caller-identity --query 'UserName' --output text 2>/dev/null || echo "Unknown")
        CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
        print_status "Current user: $CURRENT_USER"
        print_status "Current account: $CURRENT_ACCOUNT"
        
        echo -n "Do you want to reconfigure? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo "Please provide your AWS credentials:"
    echo "You can find these in the AWS Console under IAM > Users > [Your User] > Security credentials"
    echo ""
    
    read -p "AWS Access Key ID: " ACCESS_KEY_ID
    read -s -p "AWS Secret Access Key: " SECRET_ACCESS_KEY
    echo ""
    read -p "Default region name [us-east-1]: " REGION
    REGION=${REGION:-us-east-1}
    read -p "Default output format [json]: " OUTPUT_FORMAT
    OUTPUT_FORMAT=${OUTPUT_FORMAT:-json}
    
    # Configure AWS CLI
    aws configure set aws_access_key_id "$ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY"
    aws configure set default.region "$REGION"
    aws configure set default.output "$OUTPUT_FORMAT"
    
    # Test configuration
    print_status "🔍 Testing AWS CLI configuration..."
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
        USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
        print_status "✅ AWS CLI configured successfully"
        print_status "Account ID: $ACCOUNT_ID"
        print_status "User ARN: $USER_ARN"
    else
        print_error "❌ AWS CLI configuration failed. Please check your credentials."
        exit 1
    fi
}

# Create additional profiles
create_profiles() {
    echo -n "Do you want to create additional AWS profiles? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    while true; do
        echo ""
        read -p "Profile name: " PROFILE_NAME
        if [[ -z "$PROFILE_NAME" ]]; then
            break
        fi
        
        read -p "AWS Access Key ID for $PROFILE_NAME: " ACCESS_KEY_ID
        read -s -p "AWS Secret Access Key for $PROFILE_NAME: " SECRET_ACCESS_KEY
        echo ""
        read -p "Default region name [us-east-1]: " REGION
        REGION=${REGION:-us-east-1}
        
        aws configure set aws_access_key_id "$ACCESS_KEY_ID" --profile "$PROFILE_NAME"
        aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY" --profile "$PROFILE_NAME"
        aws configure set default.region "$REGION" --profile "$PROFILE_NAME"
        aws configure set default.output "json" --profile "$PROFILE_NAME"
        
        print_status "✅ Profile '$PROFILE_NAME' created successfully"
        
        echo -n "Create another profile? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            break
        fi
    done
}

# Set up necessary permissions
check_permissions() {
    print_status "🔍 Checking AWS permissions..."
    
    # List of required permissions to test
    PERMISSIONS=(
        "iam:GetUser"
        "ec2:DescribeVpcs"
        "ecs:ListClusters"
        "rds:DescribeDBInstances"
        "elasticache:DescribeReplicationGroups"
        "ecr:DescribeRepositories"
        "cloudformation:ListStacks"
        "secretsmanager:ListSecrets"
    )
    
    FAILED_PERMISSIONS=()
    
    for permission in "${PERMISSIONS[@]}"; do
        service=$(echo "$permission" | cut -d':' -f1)
        action=$(echo "$permission" | cut -d':' -f2)
        
        case $service in
            "iam")
                if ! aws iam get-user &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "ec2")
                if ! aws ec2 describe-vpcs --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "ecs")
                if ! aws ecs list-clusters --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "rds")
                if ! aws rds describe-db-instances --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "elasticache")
                if ! aws elasticache describe-replication-groups --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "ecr")
                if ! aws ecr describe-repositories --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "cloudformation")
                if ! aws cloudformation list-stacks --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
            "secretsmanager")
                if ! aws secretsmanager list-secrets --max-items 1 &> /dev/null; then
                    FAILED_PERMISSIONS+=("$permission")
                fi
                ;;
        esac
    done
    
    if [ ${#FAILED_PERMISSIONS[@]} -eq 0 ]; then
        print_status "✅ All required permissions are available"
    else
        print_warning "⚠️ Some permissions are missing or access denied:"
        for perm in "${FAILED_PERMISSIONS[@]}"; do
            print_warning "  - $perm"
        done
        print_status "Please ensure your IAM user has the necessary policies attached."
    fi
}

# Main execution
main() {
    print_status "🚀 AWS CLI Setup for E-commerce Application"
    print_status "==========================================="
    
    if ! check_aws_cli; then
        install_aws_cli
    fi
    
    configure_aws_cli
    create_profiles
    check_permissions
    
    print_status ""
    print_status "🎉 AWS CLI setup completed successfully!"
    print_status ""
    print_status "📋 Next steps:"
    print_status "  1. Review the permission check results above"
    print_status "  2. If any permissions are missing, contact your AWS administrator"
    print_status "  3. You can now run the deployment scripts for EKS, ECS, or Elastic Beanstalk"
    print_status ""
    print_status "🔧 Useful commands:"
    print_status "  aws sts get-caller-identity    # Check current credentials"
    print_status "  aws configure list             # List current configuration"
    print_status "  aws configure list-profiles    # List all profiles"
    print_status "  aws --profile PROFILE_NAME ... # Use specific profile"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
