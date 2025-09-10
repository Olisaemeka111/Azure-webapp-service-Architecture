# Azure App Service Architecture with Terraform

This Terraform configuration implements a comprehensive Azure App Service architecture with the following components:

## Architecture Overview

The infrastructure follows the optimized reference design pattern:

**Front Door (global LB, WAF, CDN)** → **App Service / AKS (autoscaling)** → **Azure SQL Database (HA/DR)**

**Azure Bastion + Azure AD DS** for management

**Azure Monitor, Defender, and Sentinel** for observability and security

## Components

### 1. Networking Module (`modules/networking/`)
- Virtual Network with multiple subnets
- Network Security Groups for each subnet
- Subnet delegations for App Service integration

### 2. Azure Front Door Module (`modules/front-door/`)
- Global load balancer with CDN capabilities
- Web Application Firewall (WAF) with custom rules
- Custom domain configuration
- SSL/TLS termination

### 3. App Service Module (`modules/app-service/`)
- Linux App Service with .NET 6.0
- VNet integration for secure connectivity
- Autoscaling configuration (CPU and Memory based)
- Application Insights integration
- Private endpoint for secure access

### 4. SQL Database Module (`modules/sql-database/`)
- Azure SQL Database with Business Critical tier
- Zone redundancy for high availability
- Geo-redundant backups
- Private endpoint for secure connectivity
- VNet integration

### 5. Azure Bastion Module (`modules/bastion/`)
- Secure management access to resources
- Public IP for internet connectivity
- Comprehensive NSG rules for security
- Logging and monitoring

### 6. Azure AD DS Module (`modules/azure-ad-ds/`)
- Active Directory Domain Services
- Domain controller deployment
- Comprehensive security rules
- Integration with monitoring

### 7. Monitoring Module (`modules/monitoring/`)
- Log Analytics workspace
- Application Insights
- Azure Monitor alerts and action groups
- Azure Security Center (Defender for Cloud)
- Azure Sentinel for SIEM capabilities
- Custom dashboards and workbooks

## Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure subscription** with appropriate permissions
4. **Service Principal** or Azure CLI authentication

## Deployment Instructions

### 1. Clone and Setup

```bash
git clone <repository-url>
cd azure-app-service-architecture
```

### 2. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
project_name = "my-azure-app"
environment  = "prod"
location     = "West US 2"
domain_name  = "contoso.com"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

### 6. Verify Deployment

After deployment, you can access:

- **Front Door URL**: Check the `front_door_url` output
- **App Service URL**: Check the `app_service_url` output
- **Bastion Access**: Use Azure Portal to connect via Bastion
- **Monitoring**: Access Log Analytics workspace and Application Insights

## Configuration Details

### Networking
- **VNet Address Space**: 10.0.0.0/16
- **App Service Subnet**: 10.0.1.0/24
- **Database Subnet**: 10.0.2.0/24
- **Bastion Subnet**: 10.0.3.0/24
- **Private Endpoint Subnet**: 10.0.4.0/24

### Security Features
- **WAF**: Enabled with custom rules for rate limiting and geo-blocking
- **Private Endpoints**: All services use private connectivity
- **NSGs**: Comprehensive security rules for each subnet
- **Azure AD DS**: Domain services for identity management
- **Defender for Cloud**: Security monitoring and recommendations

### Monitoring and Observability
- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging
- **Azure Monitor**: Metrics and alerting
- **Azure Sentinel**: Security information and event management
- **Custom Dashboards**: Visual monitoring interfaces

## Cost Optimization

This configuration uses:
- **Premium V2** App Service plan for production workloads
- **Business Critical** SQL Database for HA/DR
- **Standard** Log Analytics workspace
- **Premium** Front Door for WAF capabilities

For development environments, consider:
- Using **Standard** App Service plan
- **General Purpose** SQL Database
- **Basic** Front Door tier

## Security Considerations

1. **Network Security**: All resources are deployed in private subnets
2. **Access Control**: Use Azure AD DS for domain-joined resources
3. **Encryption**: All data encrypted in transit and at rest
4. **Monitoring**: Comprehensive security monitoring with Sentinel
5. **Compliance**: Built-in compliance features with Defender for Cloud

## Troubleshooting

### Common Issues

1. **DNS Resolution**: Ensure custom domain DNS is properly configured
2. **Private Endpoints**: Verify VNet integration and DNS resolution
3. **WAF Rules**: Check WAF logs for blocked requests
4. **Autoscaling**: Monitor metrics to ensure proper scaling behavior

### Useful Commands

```bash
# Check resource status
terraform show

# View outputs
terraform output

# Destroy infrastructure
terraform destroy
```

## Support

For issues and questions:
1. Check Azure documentation for specific services
2. Review Terraform provider documentation
3. Check Azure Advisor for optimization recommendations
4. Use Azure Support for production issues

## License

This project is licensed under the MIT License - see the LICENSE file for details.
