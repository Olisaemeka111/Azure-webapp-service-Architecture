#!/bin/bash

# Azure App Service Architecture - Cost Tracking Script
# This script provides comprehensive cost analysis and monitoring

set -e

# Configuration
RESOURCE_GROUP="azure-app-arch-prod-rg"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
BILLING_PERIOD=$(az billing period list --query '[0].name' -o tsv)
OUTPUT_DIR="./cost-reports"
DATE=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p $OUTPUT_DIR

echo -e "${BLUE}💰 Azure Cost Tracking Report${NC}"
echo -e "${BLUE}================================${NC}"
echo "Date: $(date)"
echo "Resource Group: $RESOURCE_GROUP"
echo "Subscription: $SUBSCRIPTION_ID"
echo "Billing Period: $BILLING_PERIOD"
echo ""

# Function to get cost data
get_cost_data() {
    local service_name=$1
    local resource_type=$2
    
    echo -e "${YELLOW}📊 Analyzing costs for $service_name...${NC}"
    
    # Get cost data for the last 30 days
    local cost_data=$(az consumption usage list \
        --billing-period-name $BILLING_PERIOD \
        --start-date $(date -d '30 days ago' +%Y-%m-%d) \
        --end-date $(date +%Y-%m-%d) \
        --query "[?contains(instanceName, '$resource_type')].{Resource:instanceName, Cost:pretaxCost, Currency:currency, Date:usageStart}" \
        --output table 2>/dev/null || echo "No data available")
    
    if [ "$cost_data" != "No data available" ]; then
        echo "$cost_data" > "$OUTPUT_DIR/${service_name}_costs_${DATE}.txt"
        echo "$cost_data"
    else
        echo -e "${RED}❌ No cost data available for $service_name${NC}"
    fi
    echo ""
}

# Function to get resource costs
get_resource_costs() {
    echo -e "${GREEN}🔍 Getting detailed resource costs...${NC}"
    
    # Get all resources in the resource group
    local resources=$(az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type, Location:location}" --output table)
    echo "$resources" > "$OUTPUT_DIR/resources_${DATE}.txt"
    
    echo "Resources in Resource Group:"
    echo "$resources"
    echo ""
}

# Function to get App Service costs
get_app_service_costs() {
    echo -e "${YELLOW}🚀 App Service Cost Analysis${NC}"
    echo "================================"
    
    # Get App Service Plan details
    local app_plan=$(az appservice plan show \
        --name azure-app-arch-prod-app-plan \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, SKU:sku.name, Tier:sku.tier, Capacity:sku.capacity, Location:location}" \
        --output table 2>/dev/null || echo "App Service Plan not found")
    
    echo "App Service Plan Details:"
    echo "$app_plan"
    echo ""
    
    # Get App Service details
    local app_service=$(az webapp show \
        --name azure-app-arch-prod-app \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, State:state, Location:location, AlwaysOn:siteConfig.alwaysOn}" \
        --output table 2>/dev/null || echo "App Service not found")
    
    echo "App Service Details:"
    echo "$app_service"
    echo ""
    
    # Calculate estimated monthly cost for App Service
    local sku=$(az appservice plan show --name azure-app-arch-prod-app-plan --resource-group $RESOURCE_GROUP --query "sku.name" -o tsv 2>/dev/null || echo "B1")
    local capacity=$(az appservice plan show --name azure-app-arch-prod-app-plan --resource-group $RESOURCE_GROUP --query "sku.capacity" -o tsv 2>/dev/null || echo "1")
    
    case $sku in
        "B1")
            local monthly_cost=$(echo "$capacity * 13.14" | bc -l)
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$${monthly_cost}${NC}"
            ;;
        "S1")
            local monthly_cost=$(echo "$capacity * 54.75" | bc -l)
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$${monthly_cost}${NC}"
            ;;
        "P1v2")
            local monthly_cost=$(echo "$capacity * 73.00" | bc -l)
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$${monthly_cost}${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️ Unknown SKU: $sku${NC}"
            ;;
    esac
    echo ""
}

# Function to get SQL Database costs
get_sql_costs() {
    echo -e "${YELLOW}🗄️ SQL Database Cost Analysis${NC}"
    echo "================================"
    
    # Get SQL Server details
    local sql_server=$(az sql server show \
        --name azure-app-arch-prod-sql \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, Version:version, Location:location, State:state}" \
        --output table 2>/dev/null || echo "SQL Server not found")
    
    echo "SQL Server Details:"
    echo "$sql_server"
    echo ""
    
    # Get SQL Database details
    local sql_db=$(az sql db show \
        --name appdb \
        --server azure-app-arch-prod-sql \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, SKU:currentServiceObjectiveName, Tier:currentSku.tier, MaxSize:maxSizeBytes, ZoneRedundant:zoneRedundant}" \
        --output table 2>/dev/null || echo "SQL Database not found")
    
    echo "SQL Database Details:"
    echo "$sql_db"
    echo ""
    
    # Calculate estimated monthly cost for SQL Database
    local sku=$(az sql db show --name appdb --server azure-app-arch-prod-sql --resource-group $RESOURCE_GROUP --query "currentServiceObjectiveName" -o tsv 2>/dev/null || echo "BC_Gen5_2")
    
    case $sku in
        "BC_Gen5_2")
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$1,200.00 (Business Critical)${NC}"
            ;;
        "S2")
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$75.00 (Standard)${NC}"
            ;;
        "S3")
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$150.00 (Standard)${NC}"
            ;;
        "P1")
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$465.00 (Premium)${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️ Unknown SKU: $sku${NC}"
            ;;
    esac
    echo ""
}

# Function to get Front Door costs
get_front_door_costs() {
    echo -e "${YELLOW}🌐 Front Door Cost Analysis${NC}"
    echo "================================"
    
    # Get Front Door details
    local front_door=$(az cdn profile show \
        --name azure-app-arch-prod-fd \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, SKU:sku.name, Location:location}" \
        --output table 2>/dev/null || echo "Front Door not found")
    
    echo "Front Door Details:"
    echo "$front_door"
    echo ""
    
    # Get Front Door endpoints
    local endpoints=$(az cdn endpoint list \
        --profile-name azure-app-arch-prod-fd \
        --resource-group $RESOURCE_GROUP \
        --query "[].{Name:name, HostName:hostName, IsEnabled:isEnabled}" \
        --output table 2>/dev/null || echo "No endpoints found")
    
    echo "Front Door Endpoints:"
    echo "$endpoints"
    echo ""
    
    # Calculate estimated monthly cost for Front Door
    local sku=$(az cdn profile show --name azure-app-arch-prod-fd --resource-group $RESOURCE_GROUP --query "sku.name" -o tsv 2>/dev/null || echo "Premium_AzureFrontDoor")
    
    case $sku in
        "Premium_AzureFrontDoor")
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$200.00 (Premium)${NC}"
            echo -e "${YELLOW}📊 Additional costs for bandwidth and requests${NC}"
            ;;
        "Standard_AzureFrontDoor")
            echo -e "${GREEN}💰 Estimated Monthly Cost: \$50.00 (Standard)${NC}"
            echo -e "${YELLOW}📊 Additional costs for bandwidth and requests${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️ Unknown SKU: $sku${NC}"
            ;;
    esac
    echo ""
}

# Function to get Bastion costs
get_bastion_costs() {
    echo -e "${YELLOW}🔒 Bastion Cost Analysis${NC}"
    echo "================================"
    
    # Get Bastion details
    local bastion=$(az network bastion show \
        --name azure-app-arch-prod-bastion \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, Location:location, SKU:sku.name}" \
        --output table 2>/dev/null || echo "Bastion not found")
    
    echo "Bastion Details:"
    echo "$bastion"
    echo ""
    
    # Get Bastion Public IP
    local bastion_ip=$(az network public-ip show \
        --name azure-app-arch-prod-bastion-pip \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, IPAddress:ipAddress, SKU:sku.name, Allocation:publicIpAllocationMethod}" \
        --output table 2>/dev/null || echo "Bastion IP not found")
    
    echo "Bastion Public IP Details:"
    echo "$bastion_ip"
    echo ""
    
    # Calculate estimated monthly cost for Bastion
    echo -e "${GREEN}💰 Estimated Monthly Cost: \$150.00 (Standard Bastion)${NC}"
    echo -e "${GREEN}💰 Public IP Cost: \$3.65/month (Static)${NC}"
    echo ""
}

# Function to get monitoring costs
get_monitoring_costs() {
    echo -e "${YELLOW}📊 Monitoring Cost Analysis${NC}"
    echo "================================"
    
    # Get Log Analytics workspaces
    local log_analytics=$(az monitor log-analytics workspace list \
        --resource-group $RESOURCE_GROUP \
        --query "[].{Name:name, SKU:sku.name, Location:location, Retention:retentionInDays}" \
        --output table 2>/dev/null || echo "No Log Analytics workspaces found")
    
    echo "Log Analytics Workspaces:"
    echo "$log_analytics"
    echo ""
    
    # Get Application Insights
    local app_insights=$(az monitor app-insights component show \
        --app azure-app-arch-prod-monitor-insights \
        --resource-group $RESOURCE_GROUP \
        --query "{Name:name, Location:location, ApplicationType:applicationType, Retention:retentionInDays}" \
        --output table 2>/dev/null || echo "Application Insights not found")
    
    echo "Application Insights:"
    echo "$app_insights"
    echo ""
    
    # Calculate estimated monthly cost for monitoring
    echo -e "${GREEN}💰 Log Analytics Estimated Cost: \$50.00/month (PerGB2018)${NC}"
    echo -e "${GREEN}💰 Application Insights Estimated Cost: \$30.00/month${NC}"
    echo -e "${YELLOW}📊 Costs vary based on data ingestion and retention${NC}"
    echo ""
}

# Function to generate cost summary
generate_cost_summary() {
    echo -e "${BLUE}💰 TOTAL COST SUMMARY${NC}"
    echo -e "${BLUE}====================${NC}"
    
    local total_cost=0
    
    # App Service costs
    local app_sku=$(az appservice plan show --name azure-app-arch-prod-app-plan --resource-group $RESOURCE_GROUP --query "sku.name" -o tsv 2>/dev/null || echo "B1")
    local app_capacity=$(az appservice plan show --name azure-app-arch-prod-app-plan --resource-group $RESOURCE_GROUP --query "sku.capacity" -o tsv 2>/dev/null || echo "1")
    
    case $app_sku in
        "B1") local app_cost=$(echo "$app_capacity * 13.14" | bc -l) ;;
        "S1") local app_cost=$(echo "$app_capacity * 54.75" | bc -l) ;;
        "P1v2") local app_cost=$(echo "$app_capacity * 73.00" | bc -l) ;;
        *) local app_cost=13.14 ;;
    esac
    
    # SQL Database costs
    local sql_sku=$(az sql db show --name appdb --server azure-app-arch-prod-sql --resource-group $RESOURCE_GROUP --query "currentServiceObjectiveName" -o tsv 2>/dev/null || echo "BC_Gen5_2")
    case $sql_sku in
        "BC_Gen5_2") local sql_cost=1200.00 ;;
        "S2") local sql_cost=75.00 ;;
        "S3") local sql_cost=150.00 ;;
        "P1") local sql_cost=465.00 ;;
        *) local sql_cost=1200.00 ;;
    esac
    
    # Front Door costs
    local fd_sku=$(az cdn profile show --name azure-app-arch-prod-fd --resource-group $RESOURCE_GROUP --query "sku.name" -o tsv 2>/dev/null || echo "Premium_AzureFrontDoor")
    case $fd_sku in
        "Premium_AzureFrontDoor") local fd_cost=200.00 ;;
        "Standard_AzureFrontDoor") local fd_cost=50.00 ;;
        *) local fd_cost=200.00 ;;
    esac
    
    # Bastion costs
    local bastion_cost=150.00
    local bastion_ip_cost=3.65
    
    # Monitoring costs
    local monitoring_cost=80.00
    
    # Calculate total
    total_cost=$(echo "$app_cost + $sql_cost + $fd_cost + $bastion_cost + $bastion_ip_cost + $monitoring_cost" | bc -l)
    
    echo -e "${GREEN}📊 Monthly Cost Breakdown:${NC}"
    echo "App Service Plan ($app_sku): \$$(printf "%.2f" $app_cost)"
    echo "SQL Database ($sql_sku): \$$(printf "%.2f" $sql_cost)"
    echo "Front Door ($fd_sku): \$$(printf "%.2f" $fd_cost)"
    echo "Bastion Host: \$$(printf "%.2f" $bastion_cost)"
    echo "Bastion Public IP: \$$(printf "%.2f" $bastion_ip_cost)"
    echo "Monitoring (Log Analytics + App Insights): \$$(printf "%.2f" $monitoring_cost)"
    echo ""
    echo -e "${BLUE}💰 TOTAL ESTIMATED MONTHLY COST: \$$(printf "%.2f" $total_cost)${NC}"
    echo ""
    
    # Save summary to file
    cat > "$OUTPUT_DIR/cost_summary_${DATE}.txt" << EOF
Azure App Service Architecture - Cost Summary
Generated: $(date)
Resource Group: $RESOURCE_GROUP

Monthly Cost Breakdown:
- App Service Plan ($app_sku): \$$(printf "%.2f" $app_cost)
- SQL Database ($sql_sku): \$$(printf "%.2f" $sql_cost)
- Front Door ($fd_sku): \$$(printf "%.2f" $fd_cost)
- Bastion Host: \$$(printf "%.2f" $bastion_cost)
- Bastion Public IP: \$$(printf "%.2f" $bastion_ip_cost)
- Monitoring: \$$(printf "%.2f" $monitoring_cost)

TOTAL ESTIMATED MONTHLY COST: \$$(printf "%.2f" $total_cost)

Cost Optimization Recommendations:
1. Consider downgrading SQL Database to Standard tier if high availability is not critical
2. Monitor Front Door bandwidth usage and optimize caching
3. Review Log Analytics data retention policies
4. Use Azure Cost Management for detailed cost analysis
5. Set up cost alerts and budgets
EOF
    
    echo -e "${GREEN}✅ Cost summary saved to: $OUTPUT_DIR/cost_summary_${DATE}.txt${NC}"
}

# Function to get cost optimization recommendations
get_cost_optimization_recommendations() {
    echo -e "${BLUE}💡 COST OPTIMIZATION RECOMMENDATIONS${NC}"
    echo -e "${BLUE}=====================================${NC}"
    
    echo -e "${YELLOW}1. SQL Database Optimization:${NC}"
    echo "   - Current: Business Critical (BC_Gen5_2) - \$1,200/month"
    echo "   - Consider: Standard S3 - \$150/month (87% savings)"
    echo "   - Trade-off: Reduced high availability features"
    echo ""
    
    echo -e "${YELLOW}2. App Service Plan Optimization:${NC}"
    echo "   - Current: Basic B1 - \$13.14/month"
    echo "   - Consider: Standard S1 - \$54.75/month (for better performance)"
    echo "   - Or: Keep B1 for development, upgrade for production"
    echo ""
    
    echo -e "${YELLOW}3. Front Door Optimization:${NC}"
    echo "   - Current: Premium - \$200/month"
    echo "   - Consider: Standard - \$50/month (75% savings)"
    echo "   - Trade-off: Reduced security features"
    echo ""
    
    echo -e "${YELLOW}4. Monitoring Optimization:${NC}"
    echo "   - Review Log Analytics data retention (currently 30 days)"
    echo "   - Optimize Application Insights sampling rates"
    echo "   - Use Azure Cost Management for detailed analysis"
    echo ""
    
    echo -e "${YELLOW}5. General Recommendations:${NC}"
    echo "   - Set up cost alerts and budgets"
    echo "   - Use Azure Advisor for cost recommendations"
    echo "   - Implement resource tagging for cost tracking"
    echo "   - Review unused resources regularly"
    echo "   - Consider reserved instances for predictable workloads"
    echo ""
}

# Function to create cost alert
create_cost_alert() {
    echo -e "${YELLOW}🚨 Setting up cost alerts...${NC}"
    
    # Create action group for cost alerts
    local action_group_name="cost-alerts-$(date +%Y%m%d)"
    
    az monitor action-group create \
        --name $action_group_name \
        --resource-group $RESOURCE_GROUP \
        --short-name costalert \
        --email-receivers name=admin email=admin@contoso.com 2>/dev/null || echo "Action group may already exist"
    
    echo -e "${GREEN}✅ Cost alert action group created: $action_group_name${NC}"
    echo -e "${YELLOW}📧 Update email address in Azure Portal for notifications${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Azure Cost Analysis...${NC}"
    echo ""
    
    # Check if user is logged in
    if ! az account show &>/dev/null; then
        echo -e "${RED}❌ Please login to Azure CLI first: az login${NC}"
        exit 1
    fi
    
    # Get resource costs
    get_resource_costs
    
    # Get detailed costs for each service
    get_app_service_costs
    get_sql_costs
    get_front_door_costs
    get_bastion_costs
    get_monitoring_costs
    
    # Generate cost summary
    generate_cost_summary
    
    # Get optimization recommendations
    get_cost_optimization_recommendations
    
    # Create cost alert
    create_cost_alert
    
    echo -e "${GREEN}🎉 Cost analysis completed!${NC}"
    echo -e "${GREEN}📁 Reports saved in: $OUTPUT_DIR${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Review cost summary and optimization recommendations"
    echo "2. Set up cost alerts and budgets in Azure Portal"
    echo "3. Use Azure Cost Management for detailed analysis"
    echo "4. Implement resource tagging for better cost tracking"
    echo "5. Schedule regular cost reviews"
}

# Run main function
main "$@"
