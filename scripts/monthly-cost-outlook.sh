#!/bin/bash

# Azure App Service Architecture - Monthly Cost Outlook
# This script provides monthly cost projections and budget management

set -e

# Configuration
RESOURCE_GROUP="azure-app-arch-prod-rg"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
OUTPUT_DIR="./cost-reports"
DATE=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p $OUTPUT_DIR

echo -e "${BLUE}📅 Azure Monthly Cost Outlook${NC}"
echo -e "${BLUE}=============================${NC}"
echo "Date: $(date)"
echo "Resource Group: $RESOURCE_GROUP"
echo "Subscription: $SUBSCRIPTION_ID"
echo ""

# Function to get current month costs
get_current_month_costs() {
    echo -e "${YELLOW}📊 Current Month Cost Analysis${NC}"
    echo "================================"
    
    local current_month=$(date +%Y-%m)
    local start_date="${current_month}-01"
    local end_date=$(date +%Y-%m-%d)
    
    echo "Period: $start_date to $end_date"
    echo ""
    
    # Get current month usage
    local usage_data=$(az consumption usage list \
        --start-date $start_date \
        --end-date $end_date \
        --query "[?contains(instanceName, 'azure-app-arch')].{Resource:instanceName, Cost:pretaxCost, Currency:currency, Date:usageStart}" \
        --output table 2>/dev/null || echo "No usage data available")
    
    if [ "$usage_data" != "No usage data available" ]; then
        echo "Current Month Usage:"
        echo "$usage_data"
        echo "$usage_data" > "$OUTPUT_DIR/current_month_usage_${DATE}.txt"
    else
        echo -e "${YELLOW}⚠️ No usage data available for current month${NC}"
    fi
    echo ""
}

# Function to calculate monthly projections
calculate_monthly_projections() {
    echo -e "${GREEN}📈 Monthly Cost Projections${NC}"
    echo "============================="
    
    # Get current resource configurations
    local app_sku=$(az appservice plan show --name azure-app-arch-prod-app-plan --resource-group $RESOURCE_GROUP --query "sku.name" -o tsv 2>/dev/null || echo "B1")
    local app_capacity=$(az appservice plan show --name azure-app-arch-prod-app-plan --resource-group $RESOURCE_GROUP --query "sku.capacity" -o tsv 2>/dev/null || echo "1")
    local sql_sku=$(az sql db show --name appdb --server azure-app-arch-prod-sql --resource-group $RESOURCE_GROUP --query "currentServiceObjectiveName" -o tsv 2>/dev/null || echo "BC_Gen5_2")
    local fd_sku=$(az cdn profile show --name azure-app-arch-prod-fd --resource-group $RESOURCE_GROUP --query "sku.name" -o tsv 2>/dev/null || echo "Premium_AzureFrontDoor")
    
    # Calculate base costs
    case $app_sku in
        "B1") local app_cost=$(echo "$app_capacity * 13.14" | bc -l) ;;
        "S1") local app_cost=$(echo "$app_capacity * 54.75" | bc -l) ;;
        "P1v2") local app_cost=$(echo "$app_capacity * 73.00" | bc -l) ;;
        *) local app_cost=13.14 ;;
    esac
    
    case $sql_sku in
        "BC_Gen5_2") local sql_cost=1200.00 ;;
        "S2") local sql_cost=75.00 ;;
        "S3") local sql_cost=150.00 ;;
        "P1") local sql_cost=465.00 ;;
        *) local sql_cost=1200.00 ;;
    esac
    
    case $fd_sku in
        "Premium_AzureFrontDoor") local fd_cost=200.00 ;;
        "Standard_AzureFrontDoor") local fd_cost=50.00 ;;
        *) local fd_cost=200.00 ;;
    esac
    
    local bastion_cost=150.00
    local bastion_ip_cost=3.65
    local monitoring_cost=80.00
    
    # Calculate total base cost
    local base_cost=$(echo "$app_cost + $sql_cost + $fd_cost + $bastion_cost + $bastion_ip_cost + $monitoring_cost" | bc -l)
    
    echo -e "${BLUE}Current Configuration Costs:${NC}"
    echo "App Service Plan ($app_sku): \$$(printf "%.2f" $app_cost)"
    echo "SQL Database ($sql_sku): \$$(printf "%.2f" $sql_cost)"
    echo "Front Door ($fd_sku): \$$(printf "%.2f" $fd_cost)"
    echo "Bastion Host: \$$(printf "%.2f" $bastion_cost)"
    echo "Bastion Public IP: \$$(printf "%.2f" $bastion_ip_cost)"
    echo "Monitoring: \$$(printf "%.2f" $monitoring_cost)"
    echo ""
    echo -e "${GREEN}Base Monthly Cost: \$$(printf "%.2f" $base_cost)${NC}"
    echo ""
    
    # Calculate projections for next 12 months
    echo -e "${PURPLE}📅 12-Month Cost Projections${NC}"
    echo "=============================="
    
    local current_date=$(date +%Y-%m)
    local total_annual_cost=$(echo "$base_cost * 12" | bc -l)
    
    echo "Month          | Base Cost | With Growth | Cumulative"
    echo "---------------|-----------|-------------|------------"
    
    for i in {0..11}; do
        local month_date=$(date -d "$current_date + $i months" +%Y-%m)
        local growth_factor=$(echo "1 + ($i * 0.02)" | bc -l)  # 2% monthly growth
        local projected_cost=$(echo "$base_cost * $growth_factor" | bc -l)
        local cumulative_cost=$(echo "$base_cost * $i + $projected_cost" | bc -l)
        
        printf "%-14s | \$%8.2f | \$%10.2f | \$%10.2f\n" \
            "$month_date" \
            "$(printf "%.2f" $base_cost)" \
            "$(printf "%.2f" $projected_cost)" \
            "$(printf "%.2f" $cumulative_cost)"
    done
    
    echo ""
    echo -e "${GREEN}Total Annual Projection: \$$(printf "%.2f" $total_annual_cost)${NC}"
    echo ""
    
    # Save projections to file
    cat > "$OUTPUT_DIR/monthly_projections_${DATE}.txt" << EOF
Azure App Service Architecture - Monthly Cost Projections
Generated: $(date)
Resource Group: $RESOURCE_GROUP

Current Configuration:
- App Service Plan ($app_sku): \$$(printf "%.2f" $app_cost)
- SQL Database ($sql_sku): \$$(printf "%.2f" $sql_cost)
- Front Door ($fd_sku): \$$(printf "%.2f" $fd_cost)
- Bastion Host: \$$(printf "%.2f" $bastion_cost)
- Bastion Public IP: \$$(printf "%.2f" $bastion_ip_cost)
- Monitoring: \$$(printf "%.2f" $monitoring_cost)

Base Monthly Cost: \$$(printf "%.2f" $base_cost)
Total Annual Projection: \$$(printf "%.2f" $total_annual_cost)

12-Month Projections (with 2% monthly growth):
EOF
    
    for i in {0..11}; do
        local month_date=$(date -d "$current_date + $i months" +%Y-%m)
        local growth_factor=$(echo "1 + ($i * 0.02)" | bc -l)
        local projected_cost=$(echo "$base_cost * $growth_factor" | bc -l)
        echo "$month_date: \$$(printf "%.2f" $projected_cost)" >> "$OUTPUT_DIR/monthly_projections_${DATE}.txt"
    done
}

# Function to create budget scenarios
create_budget_scenarios() {
    echo -e "${BLUE}💰 Budget Scenarios${NC}"
    echo "=================="
    
    local base_cost=$(echo "13.14 + 1200.00 + 200.00 + 150.00 + 3.65 + 80.00" | bc -l)
    
    echo -e "${YELLOW}Scenario 1: Current Configuration${NC}"
    echo "Cost: \$$(printf "%.2f" $base_cost)/month"
    echo "Features: Full HA/DR, Premium security, Global distribution"
    echo ""
    
    echo -e "${YELLOW}Scenario 2: Cost Optimized (Development)${NC}"
    local dev_cost=$(echo "13.14 + 75.00 + 50.00 + 0.00 + 0.00 + 30.00" | bc -l)
    echo "Cost: \$$(printf "%.2f" $dev_cost)/month"
    echo "Features: Basic App Service, Standard SQL, Standard Front Door, No Bastion"
    echo "Savings: \$$(printf "%.2f" $(echo "$base_cost - $dev_cost" | bc -l))/month ($(printf "%.1f" $(echo "($base_cost - $dev_cost) / $base_cost * 100" | bc -l))%)"
    echo ""
    
    echo -e "${YELLOW}Scenario 3: Balanced (Production)${NC}"
    local prod_cost=$(echo "54.75 + 150.00 + 200.00 + 150.00 + 3.65 + 80.00" | bc -l)
    echo "Cost: \$$(printf "%.2f" $prod_cost)/month"
    echo "Features: Standard App Service, Standard SQL, Premium Front Door, Bastion"
    echo "Savings: \$$(printf "%.2f" $(echo "$base_cost - $prod_cost" | bc -l))/month ($(printf "%.1f" $(echo "($base_cost - $prod_cost) / $base_cost * 100" | bc -l))%)"
    echo ""
    
    echo -e "${YELLOW}Scenario 4: Enterprise (High Performance)${NC}"
    local ent_cost=$(echo "73.00 + 1200.00 + 200.00 + 150.00 + 3.65 + 80.00" | bc -l)
    echo "Cost: \$$(printf "%.2f" $ent_cost)/month"
    echo "Features: Premium App Service, Business Critical SQL, Premium Front Door, Bastion"
    echo "Additional: \$$(printf "%.2f" $(echo "$ent_cost - $base_cost" | bc -l))/month"
    echo ""
    
    # Save scenarios to file
    cat > "$OUTPUT_DIR/budget_scenarios_${DATE}.txt" << EOF
Azure App Service Architecture - Budget Scenarios
Generated: $(date)
Resource Group: $RESOURCE_GROUP

Scenario 1: Current Configuration
Cost: \$$(printf "%.2f" $base_cost)/month
Features: Full HA/DR, Premium security, Global distribution

Scenario 2: Cost Optimized (Development)
Cost: \$$(printf "%.2f" $dev_cost)/month
Features: Basic App Service, Standard SQL, Standard Front Door, No Bastion
Savings: \$$(printf "%.2f" $(echo "$base_cost - $dev_cost" | bc -l))/month

Scenario 3: Balanced (Production)
Cost: \$$(printf "%.2f" $prod_cost)/month
Features: Standard App Service, Standard SQL, Premium Front Door, Bastion
Savings: \$$(printf "%.2f" $(echo "$base_cost - $prod_cost" | bc -l))/month

Scenario 4: Enterprise (High Performance)
Cost: \$$(printf "%.2f" $ent_cost)/month
Features: Premium App Service, Business Critical SQL, Premium Front Door, Bastion
Additional: \$$(printf "%.2f" $(echo "$ent_cost - $base_cost" | bc -l))/month
EOF
}

# Function to create cost alerts and budgets
create_cost_alerts() {
    echo -e "${YELLOW}🚨 Setting up Cost Alerts and Budgets${NC}"
    echo "====================================="
    
    # Create action group for cost alerts
    local action_group_name="cost-budget-alerts-$(date +%Y%m%d)"
    
    echo "Creating action group: $action_group_name"
    az monitor action-group create \
        --name $action_group_name \
        --resource-group $RESOURCE_GROUP \
        --short-name costalert \
        --email-receivers name=admin email=admin@contoso.com 2>/dev/null || echo "Action group may already exist"
    
    # Create budget alerts
    local base_cost=$(echo "13.14 + 1200.00 + 200.00 + 150.00 + 3.65 + 80.00" | bc -l)
    local budget_amount=$(echo "$base_cost * 1.2" | bc -l)  # 20% buffer
    
    echo "Creating budget alert for \$$(printf "%.2f" $budget_amount)/month"
    
    # Create budget using Azure CLI (if supported)
    cat > "$OUTPUT_DIR/budget_config_${DATE}.json" << EOF
{
  "budgetName": "azure-app-arch-monthly-budget",
  "amount": $(printf "%.2f" $budget_amount),
  "category": "Cost",
  "timeGrain": "Monthly",
  "timePeriod": {
    "startDate": "$(date +%Y-%m-01)",
    "endDate": "$(date -d "+1 year" +%Y-%m-01)"
  },
  "notifications": {
    "actual": {
      "enabled": true,
      "operator": "GreaterThan",
      "threshold": 80,
      "contactEmails": ["admin@contoso.com"]
    },
    "forecasted": {
      "enabled": true,
      "operator": "GreaterThan",
      "threshold": 100,
      "contactEmails": ["admin@contoso.com"]
    }
  }
}
EOF
    
    echo -e "${GREEN}✅ Budget configuration saved to: $OUTPUT_DIR/budget_config_${DATE}.json${NC}"
    echo -e "${YELLOW}📝 Apply budget using Azure Portal or PowerShell${NC}"
    echo ""
}

# Function to generate cost optimization recommendations
generate_optimization_recommendations() {
    echo -e "${PURPLE}💡 Cost Optimization Recommendations${NC}"
    echo "====================================="
    
    echo -e "${YELLOW}Immediate Actions (0-30 days):${NC}"
    echo "1. Set up cost alerts and budgets"
    echo "2. Implement resource tagging for cost tracking"
    echo "3. Review and optimize Log Analytics data retention"
    echo "4. Monitor Front Door bandwidth usage"
    echo "5. Set up Azure Cost Management dashboards"
    echo ""
    
    echo -e "${YELLOW}Short-term Actions (1-3 months):${NC}"
    echo "1. Evaluate SQL Database tier based on actual usage"
    echo "2. Consider reserved instances for predictable workloads"
    echo "3. Implement auto-shutdown for development environments"
    echo "4. Optimize Application Insights sampling rates"
    echo "5. Review and clean up unused resources"
    echo ""
    
    echo -e "${YELLOW}Long-term Actions (3-12 months):${NC}"
    echo "1. Implement multi-tier architecture (dev/staging/prod)"
    echo "2. Consider Azure Hybrid Benefit for cost savings"
    echo "3. Evaluate spot instances for non-critical workloads"
    echo "4. Implement cost allocation and chargeback models"
    echo "5. Regular cost reviews and optimization cycles"
    echo ""
    
    echo -e "${YELLOW}Advanced Optimization:${NC}"
    echo "1. Use Azure Advisor for cost recommendations"
    echo "2. Implement FinOps practices for cloud cost management"
    echo "3. Consider Azure Arc for hybrid cloud cost optimization"
    echo "4. Evaluate third-party cost management tools"
    echo "5. Implement automated cost optimization policies"
    echo ""
}

# Function to create cost dashboard configuration
create_cost_dashboard() {
    echo -e "${BLUE}📊 Cost Dashboard Configuration${NC}"
    echo "==============================="
    
    cat > "$OUTPUT_DIR/cost_dashboard_${DATE}.json" << EOF
{
  "dashboardName": "Azure App Service Architecture - Cost Dashboard",
  "resourceGroup": "$RESOURCE_GROUP",
  "widgets": [
    {
      "type": "Cost",
      "title": "Monthly Cost Trend",
      "query": "Usage | where ResourceGroup == '$RESOURCE_GROUP' | summarize sum(Cost) by bin(TimeGenerated, 1d)"
    },
    {
      "type": "Cost",
      "title": "Cost by Service",
      "query": "Usage | where ResourceGroup == '$RESOURCE_GROUP' | summarize sum(Cost) by ResourceType"
    },
    {
      "type": "Cost",
      "title": "Daily Cost Breakdown",
      "query": "Usage | where ResourceGroup == '$RESOURCE_GROUP' | summarize sum(Cost) by ResourceName, bin(TimeGenerated, 1d)"
    }
  ],
  "alerts": [
    {
      "name": "High Daily Cost",
      "condition": "Cost > 100",
      "action": "Email notification"
    },
    {
      "name": "Monthly Budget Exceeded",
      "condition": "MonthlyCost > 2000",
      "action": "Email and SMS notification"
    }
  ]
}
EOF
    
    echo -e "${GREEN}✅ Cost dashboard configuration saved to: $OUTPUT_DIR/cost_dashboard_${DATE}.json${NC}"
    echo -e "${YELLOW}📝 Import this configuration in Azure Portal > Cost Management${NC}"
    echo ""
}

# Function to generate executive summary
generate_executive_summary() {
    echo -e "${BLUE}📋 Executive Summary${NC}"
    echo "=================="
    
    local base_cost=$(echo "13.14 + 1200.00 + 200.00 + 150.00 + 3.65 + 80.00" | bc -l)
    local annual_cost=$(echo "$base_cost * 12" | bc -l)
    
    cat > "$OUTPUT_DIR/executive_summary_${DATE}.txt" << EOF
Azure App Service Architecture - Executive Cost Summary
Generated: $(date)
Resource Group: $RESOURCE_GROUP

CURRENT STATUS:
- Monthly Cost: \$$(printf "%.2f" $base_cost)
- Annual Projection: \$$(printf "%.2f" $annual_cost)
- Cost per User (assuming 1000 users): \$$(printf "%.2f" $(echo "$base_cost / 1000" | bc -l))

KEY METRICS:
- Infrastructure Uptime: 99.9% (Business Critical SQL)
- Global Distribution: Yes (Azure Front Door)
- Security Level: Enterprise (WAF, Private Endpoints, Bastion)
- Monitoring: Comprehensive (Application Insights, Log Analytics)

COST BREAKDOWN:
- Database (60%): \$$(printf "%.2f" $(echo "$base_cost * 0.6" | bc -l)) - Business Critical SQL
- Front Door (12%): \$$(printf "%.2f" $(echo "$base_cost * 0.12" | bc -l)) - Global CDN/WAF
- App Service (8%): \$$(printf "%.2f" $(echo "$base_cost * 0.08" | bc -l)) - Web hosting
- Bastion (9%): \$$(printf "%.2f" $(echo "$base_cost * 0.09" | bc -l)) - Secure management
- Monitoring (5%): \$$(printf "%.2f" $(echo "$base_cost * 0.05" | bc -l)) - Observability
- Other (6%): \$$(printf "%.2f" $(echo "$base_cost * 0.06" | bc -l)) - Networking, etc.

OPTIMIZATION OPPORTUNITIES:
1. SQL Database: Potential 87% savings (\$1,125/month) by downgrading to Standard
2. Front Door: Potential 75% savings (\$150/month) by using Standard tier
3. Development Environment: Potential 90% savings by using separate dev resources

RECOMMENDATIONS:
1. Implement cost alerts and budgets immediately
2. Evaluate SQL Database tier based on actual HA requirements
3. Consider multi-environment strategy (dev/staging/prod)
4. Set up regular cost review cycles
5. Implement FinOps practices for ongoing optimization

RISK ASSESSMENT:
- Low Risk: Current configuration provides enterprise-grade reliability
- Medium Risk: High cost may impact budget if not monitored
- High Risk: No cost controls in place (recommend immediate action)

NEXT STEPS:
1. Approve budget alerts and monitoring setup
2. Schedule monthly cost review meetings
3. Evaluate optimization opportunities
4. Implement cost allocation model
5. Set up automated cost reporting
EOF
    
    echo -e "${GREEN}✅ Executive summary saved to: $OUTPUT_DIR/executive_summary_${DATE}.txt${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Monthly Cost Outlook Analysis...${NC}"
    echo ""
    
    # Check if user is logged in
    if ! az account show &>/dev/null; then
        echo -e "${RED}❌ Please login to Azure CLI first: az login${NC}"
        exit 1
    fi
    
    # Run all analysis functions
    get_current_month_costs
    calculate_monthly_projections
    create_budget_scenarios
    create_cost_alerts
    generate_optimization_recommendations
    create_cost_dashboard
    generate_executive_summary
    
    echo -e "${GREEN}🎉 Monthly cost outlook analysis completed!${NC}"
    echo -e "${GREEN}📁 Reports saved in: $OUTPUT_DIR${NC}"
    echo ""
    echo -e "${BLUE}Generated Reports:${NC}"
    echo "• current_month_usage_${DATE}.txt"
    echo "• monthly_projections_${DATE}.txt"
    echo "• budget_scenarios_${DATE}.txt"
    echo "• budget_config_${DATE}.json"
    echo "• cost_dashboard_${DATE}.json"
    echo "• executive_summary_${DATE}.txt"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Review executive summary and budget scenarios"
    echo "2. Set up cost alerts and budgets in Azure Portal"
    echo "3. Implement cost optimization recommendations"
    echo "4. Schedule regular cost review meetings"
    echo "5. Set up automated cost reporting"
}

# Run main function
main "$@"
