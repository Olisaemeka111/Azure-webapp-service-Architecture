#!/bin/bash

# Azure App Service Architecture - Dangling Resources Check
# This script checks for any remaining resources after infrastructure destruction

set -e

# Configuration
RESOURCE_GROUP="azure-app-arch-prod-rg"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
OUTPUT_DIR="./dangling-resources-report"
DATE=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p $OUTPUT_DIR

echo -e "${BLUE}🔍 Azure Dangling Resources Check${NC}"
echo -e "${BLUE}=================================${NC}"
echo "Date: $(date)"
echo "Subscription: $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo ""

# Function to check if resource group exists
check_resource_group() {
    echo -e "${YELLOW}📁 Checking Resource Group...${NC}"
    
    if az group show --name $RESOURCE_GROUP &>/dev/null; then
        echo -e "${RED}❌ Resource Group '$RESOURCE_GROUP' still exists!${NC}"
        
        # Get resources in the resource group
        local resources=$(az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type, Location:location}" --output table 2>/dev/null || echo "No resources found")
        echo "Resources in Resource Group:"
        echo "$resources"
        echo "$resources" > "$OUTPUT_DIR/resource_group_resources_${DATE}.txt"
        
        return 1
    else
        echo -e "${GREEN}✅ Resource Group '$RESOURCE_GROUP' has been deleted${NC}"
        return 0
    fi
}

# Function to check for resources by name pattern
check_resources_by_name() {
    echo -e "${YELLOW}🔍 Checking Resources by Name Pattern...${NC}"
    
    local name_patterns=(
        "azure-app-arch-prod"
        "azure-app-arch"
        "appdb"
        "wafpolicy"
    )
    
    local found_resources=()
    
    for pattern in "${name_patterns[@]}"; do
        echo "Checking pattern: $pattern"
        
        # Search for resources with this pattern
        local resources=$(az resource list --query "[?contains(name, '$pattern')].{Name:name, Type:type, ResourceGroup:resourceGroup, Location:location}" --output table 2>/dev/null || echo "")
        
        if [ -n "$resources" ] && [ "$resources" != "Name    Type    ResourceGroup    Location" ]; then
            echo -e "${RED}❌ Found resources matching '$pattern':${NC}"
            echo "$resources"
            echo "$resources" >> "$OUTPUT_DIR/dangling_resources_${DATE}.txt"
            found_resources+=("$pattern")
        else
            echo -e "${GREEN}✅ No resources found matching '$pattern'${NC}"
        fi
        echo ""
    done
    
    if [ ${#found_resources[@]} -gt 0 ]; then
        echo -e "${RED}⚠️ Found dangling resources matching patterns: ${found_resources[*]}${NC}"
        return 1
    else
        echo -e "${GREEN}✅ No dangling resources found by name patterns${NC}"
        return 0
    fi
}

# Function to check for resources by tags
check_resources_by_tags() {
    echo -e "${YELLOW}🏷️ Checking Resources by Tags...${NC}"
    
    local tag_queries=(
        "Project eq 'azure-app-arch'"
        "Environment eq 'prod'"
        "ManagedBy eq 'Terraform'"
    )
    
    local found_resources=()
    
    for tag_query in "${tag_queries[@]}"; do
        echo "Checking tag: $tag_query"
        
        # Search for resources with this tag
        local resources=$(az resource list --query "[?tags.$tag_query].{Name:name, Type:type, ResourceGroup:resourceGroup, Location:location}" --output table 2>/dev/null || echo "")
        
        if [ -n "$resources" ] && [ "$resources" != "Name    Type    ResourceGroup    Location" ]; then
            echo -e "${RED}❌ Found resources with tag '$tag_query':${NC}"
            echo "$resources"
            echo "$resources" >> "$OUTPUT_DIR/tagged_resources_${DATE}.txt"
            found_resources+=("$tag_query")
        else
            echo -e "${GREEN}✅ No resources found with tag '$tag_query'${NC}"
        fi
        echo ""
    done
    
    if [ ${#found_resources[@]} -gt 0 ]; then
        echo -e "${RED}⚠️ Found resources with project tags: ${found_resources[*]}${NC}"
        return 1
    else
        echo -e "${GREEN}✅ No resources found with project tags${NC}"
        return 0
    fi
}

# Function to check for specific resource types
check_specific_resource_types() {
    echo -e "${YELLOW}🔧 Checking Specific Resource Types...${NC}"
    
    local resource_types=(
        "Microsoft.Web/sites"
        "Microsoft.Web/serverFarms"
        "Microsoft.Sql/servers"
        "Microsoft.Sql/servers/databases"
        "Microsoft.Network/virtualNetworks"
        "Microsoft.Network/networkSecurityGroups"
        "Microsoft.Network/publicIPAddresses"
        "Microsoft.Network/bastionHosts"
        "Microsoft.Cdn/profiles"
        "Microsoft.OperationalInsights/workspaces"
        "Microsoft.Insights/components"
    )
    
    local found_resources=()
    
    for resource_type in "${resource_types[@]}"; do
        echo "Checking resource type: $resource_type"
        
        # Search for resources of this type
        local resources=$(az resource list --resource-type "$resource_type" --query "[].{Name:name, Type:type, ResourceGroup:resourceGroup, Location:location}" --output table 2>/dev/null || echo "")
        
        if [ -n "$resources" ] && [ "$resources" != "Name    Type    ResourceGroup    Location" ]; then
            echo -e "${RED}❌ Found resources of type '$resource_type':${NC}"
            echo "$resources"
            echo "$resources" >> "$OUTPUT_DIR/resource_type_${resource_type//\//_}_${DATE}.txt"
            found_resources+=("$resource_type")
        else
            echo -e "${GREEN}✅ No resources found of type '$resource_type'${NC}"
        fi
        echo ""
    done
    
    if [ ${#found_resources[@]} -gt 0 ]; then
        echo -e "${RED}⚠️ Found resources of types: ${found_resources[*]}${NC}"
        return 1
    else
        echo -e "${GREEN}✅ No resources found of specific types${NC}"
        return 0
    fi
}

# Function to check for private DNS zones
check_private_dns_zones() {
    echo -e "${YELLOW}🌐 Checking Private DNS Zones...${NC}"
    
    local dns_zones=(
        "privatelink.database.windows.net"
        "privatelink.azurewebsites.net"
        "privatelink.blob.core.windows.net"
        "privatelink.file.core.windows.net"
    )
    
    local found_zones=()
    
    for zone in "${dns_zones[@]}"; do
        echo "Checking DNS zone: $zone"
        
        # Check if DNS zone exists
        local zone_info=$(az network private-dns zone show --name "$zone" --resource-group $RESOURCE_GROUP 2>/dev/null || echo "")
        
        if [ -n "$zone_info" ]; then
            echo -e "${RED}❌ Found private DNS zone '$zone'${NC}"
            echo "$zone_info" | jq -r '{Name: .name, ResourceGroup: .resourceGroup, RecordSets: .numberOfRecordSets}' 2>/dev/null || echo "$zone_info"
            echo "$zone_info" >> "$OUTPUT_DIR/dns_zone_${zone//\./_}_${DATE}.txt"
            found_zones+=("$zone")
        else
            echo -e "${GREEN}✅ Private DNS zone '$zone' not found${NC}"
        fi
        echo ""
    done
    
    if [ ${#found_zones[@]} -gt 0 ]; then
        echo -e "${RED}⚠️ Found private DNS zones: ${found_zones[*]}${NC}"
        return 1
    else
        echo -e "${GREEN}✅ No private DNS zones found${NC}"
        return 0
    fi
}

# Function to check for storage accounts
check_storage_accounts() {
    echo -e "${YELLOW}💾 Checking Storage Accounts...${NC}"
    
    # Search for storage accounts that might be related
    local storage_accounts=$(az storage account list --query "[?contains(name, 'azure-app-arch') || contains(name, 'appdb') || contains(name, 'bastion')].{Name:name, ResourceGroup:resourceGroup, Location:location, Kind:kind}" --output table 2>/dev/null || echo "")
    
    if [ -n "$storage_accounts" ] && [ "$storage_accounts" != "Name    ResourceGroup    Location    Kind" ]; then
        echo -e "${RED}❌ Found storage accounts:${NC}"
        echo "$storage_accounts"
        echo "$storage_accounts" > "$OUTPUT_DIR/storage_accounts_${DATE}.txt"
        return 1
    else
        echo -e "${GREEN}✅ No related storage accounts found${NC}"
        return 0
    fi
}

# Function to check for key vaults
check_key_vaults() {
    echo -e "${YELLOW}🔐 Checking Key Vaults...${NC}"
    
    # Search for key vaults that might be related
    local key_vaults=$(az keyvault list --query "[?contains(name, 'azure-app-arch') || contains(name, 'appdb') || contains(name, 'bastion')].{Name:name, ResourceGroup:resourceGroup, Location:location}" --output table 2>/dev/null || echo "")
    
    if [ -n "$key_vaults" ] && [ "$key_vaults" != "Name    ResourceGroup    Location" ]; then
        echo -e "${RED}❌ Found key vaults:${NC}"
        echo "$key_vaults"
        echo "$key_vaults" > "$OUTPUT_DIR/key_vaults_${DATE}.txt"
        return 1
    else
        echo -e "${GREEN}✅ No related key vaults found${NC}"
        return 0
    fi
}

# Function to check for managed identities
check_managed_identities() {
    echo -e "${YELLOW}🆔 Checking Managed Identities...${NC}"
    
    # Search for managed identities that might be related
    local managed_identities=$(az identity list --query "[?contains(name, 'azure-app-arch') || contains(name, 'appdb') || contains(name, 'bastion')].{Name:name, ResourceGroup:resourceGroup, Location:location}" --output table 2>/dev/null || echo "")
    
    if [ -n "$managed_identities" ] && [ "$managed_identities" != "Name    ResourceGroup    Location" ]; then
        echo -e "${RED}❌ Found managed identities:${NC}"
        echo "$managed_identities"
        echo "$managed_identities" > "$OUTPUT_DIR/managed_identities_${DATE}.txt"
        return 1
    else
        echo -e "${GREEN}✅ No related managed identities found${NC}"
        return 0
    fi
}

# Function to check for cost management resources
check_cost_management() {
    echo -e "${YELLOW}💰 Checking Cost Management Resources...${NC}"
    
    # Check for budgets
    local budgets=$(az consumption budget list --query "[?contains(name, 'azure-app-arch') || contains(name, 'monthly-budget')].{Name:name, Amount:amount, TimeGrain:timeGrain}" --output table 2>/dev/null || echo "")
    
    if [ -n "$budgets" ] && [ "$budgets" != "Name    Amount    TimeGrain" ]; then
        echo -e "${RED}❌ Found budgets:${NC}"
        echo "$budgets"
        echo "$budgets" > "$OUTPUT_DIR/budgets_${DATE}.txt"
        return 1
    else
        echo -e "${GREEN}✅ No related budgets found${NC}"
    fi
    
    # Check for action groups
    local action_groups=$(az monitor action-group list --query "[?contains(name, 'cost-alert') || contains(name, 'azure-app-arch')].{Name:name, ResourceGroup:resourceGroup, Location:location}" --output table 2>/dev/null || echo "")
    
    if [ -n "$action_groups" ] && [ "$action_groups" != "Name    ResourceGroup    Location" ]; then
        echo -e "${RED}❌ Found action groups:${NC}"
        echo "$action_groups"
        echo "$action_groups" > "$OUTPUT_DIR/action_groups_${DATE}.txt"
        return 1
    else
        echo -e "${GREEN}✅ No related action groups found${NC}"
    fi
    
    return 0
}

# Function to generate cleanup script
generate_cleanup_script() {
    echo -e "${YELLOW}🧹 Generating Cleanup Script...${NC}"
    
    cat > "$OUTPUT_DIR/cleanup_dangling_resources.sh" << 'EOF'
#!/bin/bash

# Cleanup script for dangling resources
# WARNING: This script will delete resources. Review carefully before running!

set -e

echo "🧹 Dangling Resources Cleanup Script"
echo "===================================="
echo "WARNING: This will delete resources. Are you sure? (y/N)"
read -r confirmation

if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Add cleanup commands here based on the dangling resources found
echo "Starting cleanup..."

# Example cleanup commands (uncomment and modify as needed):
# az resource delete --ids <resource-id>
# az group delete --name <resource-group-name> --yes --no-wait

echo "Cleanup completed."
EOF
    
    chmod +x "$OUTPUT_DIR/cleanup_dangling_resources.sh"
    echo -e "${GREEN}✅ Cleanup script generated: $OUTPUT_DIR/cleanup_dangling_resources.sh${NC}"
}

# Function to generate summary report
generate_summary_report() {
    echo -e "${BLUE}📋 Generating Summary Report...${NC}"
    
    local report_file="$OUTPUT_DIR/dangling_resources_summary_${DATE}.txt"
    
    cat > "$report_file" << EOF
Azure App Service Architecture - Dangling Resources Check
========================================================
Generated: $(date)
Subscription: $SUBSCRIPTION_ID
Resource Group: $RESOURCE_GROUP

CHECK RESULTS:
==============

EOF
    
    # Add results from each check
    echo "Resource Group Check: $([ -f "$OUTPUT_DIR/resource_group_resources_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Name Pattern Check: $([ -f "$OUTPUT_DIR/dangling_resources_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Tag Check: $([ -f "$OUTPUT_DIR/tagged_resources_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Resource Type Check: $([ -f "$OUTPUT_DIR/resource_type_"*"_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Private DNS Zones: $([ -f "$OUTPUT_DIR/dns_zone_"*"_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Storage Accounts: $([ -f "$OUTPUT_DIR/storage_accounts_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Key Vaults: $([ -f "$OUTPUT_DIR/key_vaults_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Managed Identities: $([ -f "$OUTPUT_DIR/managed_identities_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    echo "Cost Management: $([ -f "$OUTPUT_DIR/budgets_${DATE}.txt" ] || [ -f "$OUTPUT_DIR/action_groups_${DATE}.txt" ] && echo "❌ FOUND" || echo "✅ CLEAN")" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "FILES GENERATED:" >> "$report_file"
    echo "================" >> "$report_file"
    ls -la "$OUTPUT_DIR"/*.txt 2>/dev/null | awk '{print $9}' >> "$report_file" || echo "No files generated" >> "$report_file"
    
    echo -e "${GREEN}✅ Summary report generated: $report_file${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Dangling Resources Check...${NC}"
    echo ""
    
    # Check if user is logged in
    if ! az account show &>/dev/null; then
        echo -e "${RED}❌ Please login to Azure CLI first: az login${NC}"
        exit 1
    fi
    
    local has_dangling=false
    
    # Run all checks
    check_resource_group || has_dangling=true
    check_resources_by_name || has_dangling=true
    check_resources_by_tags || has_dangling=true
    check_specific_resource_types || has_dangling=true
    check_private_dns_zones || has_dangling=true
    check_storage_accounts || has_dangling=true
    check_key_vaults || has_dangling=true
    check_managed_identities || has_dangling=true
    check_cost_management || has_dangling=true
    
    # Generate reports
    generate_cleanup_script
    generate_summary_report
    
    echo ""
    echo -e "${BLUE}🎉 Dangling Resources Check Completed!${NC}"
    echo -e "${GREEN}📁 Reports saved in: $OUTPUT_DIR${NC}"
    
    if [ "$has_dangling" = true ]; then
        echo -e "${RED}⚠️ DANGING RESOURCES FOUND!${NC}"
        echo -e "${YELLOW}📋 Review the generated reports and cleanup script${NC}"
        echo -e "${YELLOW}🧹 Run the cleanup script to remove dangling resources${NC}"
    else
        echo -e "${GREEN}✅ NO DANGING RESOURCES FOUND!${NC}"
        echo -e "${GREEN}🎉 Infrastructure cleanup was successful${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Review the summary report"
    echo "2. Check individual resource files if any were found"
    echo "3. Run cleanup script if dangling resources exist"
    echo "4. Verify cost management shows no charges"
}

# Run main function
main "$@"
