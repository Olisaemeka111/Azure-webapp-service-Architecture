#!/bin/bash

# Azure App Service Architecture Destruction Script
# This script safely destroys the Azure infrastructure

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

# Plan Terraform destruction
plan_terraform_destroy() {
    print_status "Planning Terraform destruction..."
    terraform plan -destroy -out=destroy.tfplan
    print_status "Terraform destroy plan completed"
}

# Apply Terraform destruction
apply_terraform_destroy() {
    print_status "Applying Terraform destruction..."
    terraform apply destroy.tfplan
    print_status "Terraform destruction completed successfully"
}

# Main destruction function
main() {
    print_status "Starting Azure App Service Architecture destruction..."
    
    check_prerequisites
    check_azure_login
    init_terraform
    plan_terraform_destroy
    
    print_warning "This will DESTROY all Azure resources created by this Terraform configuration."
    print_warning "This action is IRREVERSIBLE and will result in data loss."
    print_warning "Make sure you have backed up any important data."
    
    read -p "Are you absolutely sure you want to destroy all resources? (yes/NO): " -r
    echo
    
    if [[ $REPLY == "yes" ]]; then
        print_warning "Final confirmation required..."
        read -p "Type 'DESTROY' to confirm: " -r
        echo
        
        if [[ $REPLY == "DESTROY" ]]; then
            apply_terraform_destroy
            print_status "Destruction completed successfully!"
        else
            print_warning "Destruction cancelled - confirmation text did not match"
            exit 0
        fi
    else
        print_warning "Destruction cancelled by user"
        exit 0
    fi
}

# Run main function
main "$@"
