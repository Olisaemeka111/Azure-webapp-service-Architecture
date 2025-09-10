#!/bin/bash

# Azure App Service Architecture Deployment Script
# This script automates the deployment of the Azure infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Check Azure CLI login
check_azure_login() {
    print_status "Checking Azure CLI login..."
    
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure CLI. Please run 'az login'"
        exit 1
    fi
    
    print_status "Azure CLI login verified"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_status "Terraform initialized successfully"
}

# Validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    terraform validate
    print_status "Terraform configuration is valid"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_status "Terraform plan completed"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_status "Terraform deployment completed successfully"
}

# Show outputs
show_outputs() {
    print_status "Deployment outputs:"
    terraform output
}

# Main deployment function
main() {
    print_status "Starting Azure App Service Architecture deployment..."
    
    check_prerequisites
    check_azure_login
    init_terraform
    validate_terraform
    plan_terraform
    
    print_warning "This will create Azure resources that may incur costs."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        show_outputs
        print_status "Deployment completed successfully!"
    else
        print_warning "Deployment cancelled by user"
        exit 0
    fi
}

# Run main function
main "$@"
