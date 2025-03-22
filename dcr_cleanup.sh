#!/bin/bash
# Cleanup script for Azure Data Collection resources created by Network Watcher Flow Logs
# Usage: ./dcr_cleanup.sh <RESOURCE_GROUP> <SUBSCRIPTION_ID> [NAME_PATTERN]

# Get parameters
MODULE_RG="$1"
SUBSCRIPTION_ID="$2"
NAME_PATTERN="${3:-NWTA}"  # Default to "NWTA" which appears in the DCR name

# Validate input
if [ -z "$MODULE_RG" ] || [ -z "$SUBSCRIPTION_ID" ]; then
  echo "Error: Required parameters missing"
  echo "Usage: ./dcr_cleanup.sh <MODULE_RG> <SUBSCRIPTION_ID> [NAME_PATTERN]"
  exit 1
fi

echo "Starting Azure Data Collection resource cleanup in subscription $SUBSCRIPTION_ID"

# Set context to the right subscription
echo "Setting Azure subscription context..."
az account set --subscription "$SUBSCRIPTION_ID"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set Azure subscription context"
  exit 1
fi

# Enable preview extensions and install required extension
echo "Configuring Azure CLI extensions..."
az config set extension.dynamic_install_allow_preview=true
az extension add --name monitor-control-service --allow-preview true --yes

#######################
# PART 1: CLEAN UP DATA COLLECTION RULES
#######################

echo "===== DATA COLLECTION RULES CLEANUP ====="
# Get all DCRs directly without filtering first
echo "Getting all DCRs in the subscription..."
# Save the full list to a file for reference
az monitor data-collection rule list --subscription "$SUBSCRIPTION_ID" --query "[].{name:name, resourceGroup:resourceGroup, id:id}" -o table > all_dcrs.txt
echo "Full list of DCRs saved to all_dcrs.txt"

# Get all DCR IDs from the module resource group
echo "Getting all DCR IDs from resource group $MODULE_RG"
MODULE_DCR_IDS=$(az monitor data-collection rule list --resource-group "$MODULE_RG" --query "[].id" -o tsv)
DCR_COUNT=$(echo "$MODULE_DCR_IDS" | grep -v "^$" | wc -l)
echo "DCRs found in resource group $MODULE_RG: $DCR_COUNT"

# Delete matching DCRs
if [ -z "$MODULE_DCR_IDS" ] || [ "$DCR_COUNT" -eq 0 ]; then
  echo "No Data Collection Rules found to delete."
else
  echo "Found DCRs to clean up. Starting deletion..."
  # Loop through each DCR ID and delete it
  echo "$MODULE_DCR_IDS" | grep -v "^$" | while read -r DCR_ID; do
    if [ -n "$DCR_ID" ]; then
      DCR_RG=$(echo "$DCR_ID" | cut -d'/' -f5)
      DCR_NAME=$(echo "$DCR_ID" | cut -d'/' -f9)
      echo "Processing DCR: $DCR_NAME in resource group $DCR_RG"
      
      # First, check and delete any associations
      echo "Checking for associations on DCR $DCR_NAME..."
      ASSOCIATIONS=$(az monitor data-collection rule association list --rule-id "$DCR_ID" --query "[].id" -o tsv 2>/dev/null)
      
      if [ -n "$ASSOCIATIONS" ]; then
        echo "Found associations for DCR $DCR_NAME. Deleting associations first..."
        for ASSOC_ID in $ASSOCIATIONS; do
          echo "Deleting association: $ASSOC_ID"
          az monitor data-collection rule association delete --ids "$ASSOC_ID" --yes
          if [ $? -eq 0 ]; then
            echo "Successfully deleted association: $ASSOC_ID"
          else
            echo "WARNING: Failed to delete association: $ASSOC_ID"
          fi
        done
      else
        echo "No associations found for DCR $DCR_NAME"
      fi
      
      # Check for locks on the resource
      echo "Checking for locks on DCR $DCR_NAME..."
      LOCKS=$(az lock list --resource "$DCR_ID" --query "[].id" -o tsv 2>/dev/null)
      
      if [ -n "$LOCKS" ]; then
        echo "Found locks on DCR $DCR_NAME. Attempting to remove locks..."
        for LOCK_ID in $LOCKS; do
          echo "Deleting lock: $LOCK_ID"
          az lock delete --ids "$LOCK_ID"
          if [ $? -eq 0 ]; then
            echo "Successfully deleted lock: $LOCK_ID"
          else
            echo "WARNING: Failed to delete lock: $LOCK_ID"
          fi
        done
      else
        echo "No locks found for DCR $DCR_NAME"
      fi
      
      # Now try to delete the DCR
      echo "Attempting to delete DCR: $DCR_NAME..."
      # Try without debug flag first
      az monitor data-collection rule delete --ids "$DCR_ID" --yes
      
      if [ $? -eq 0 ]; then
        echo "Successfully deleted DCR: $DCR_NAME"
      else
        echo "Initial deletion attempt failed. Trying with debug flag for more information..."
        # Try with debug flag for more information
        az monitor data-collection rule delete --ids "$DCR_ID" --yes --debug
        if [ $? -eq 0 ]; then
          echo "Successfully deleted DCR: $DCR_NAME with debug mode"
        else
          echo "ERROR: Failed to delete DCR: $DCR_NAME"
          echo "Manual intervention may be required. Try deleting this resource from the Azure portal."
        fi
      fi
      
      echo "------------------------------------------"
    fi
  done
fi

#######################
# PART 2: CLEAN UP DATA COLLECTION ENDPOINTS
#######################

echo "===== DATA COLLECTION ENDPOINTS CLEANUP ====="
# Get all DCEs in the module resource group
echo "Getting all Data Collection Endpoints in resource group $MODULE_RG..."
# Save the full list to a file for reference
az monitor data-collection endpoint list --resource-group "$MODULE_RG" --query "[].{name:name, id:id}" -o table > all_dces.txt
echo "Full list of DCEs saved to all_dces.txt"

# Get all DCE IDs from the module resource group
MODULE_DCE_IDS=$(az monitor data-collection endpoint list --resource-group "$MODULE_RG" --query "[].id" -o tsv)
DCE_COUNT=$(echo "$MODULE_DCE_IDS" | grep -v "^$" | wc -l)
echo "DCEs found in resource group $MODULE_RG: $DCE_COUNT"

# Delete Data Collection Endpoints
if [ -z "$MODULE_DCE_IDS" ] || [ "$DCE_COUNT" -eq 0 ]; then
  echo "No Data Collection Endpoints found to delete."
else
  echo "Found DCEs to clean up. Starting deletion..."
  # Loop through each DCE ID and delete it
  echo "$MODULE_DCE_IDS" | grep -v "^$" | while read -r DCE_ID; do
    if [ -n "$DCE_ID" ]; then
      DCE_RG=$(echo "$DCE_ID" | cut -d'/' -f5)
      DCE_NAME=$(echo "$DCE_ID" | cut -d'/' -f9)
      echo "Processing DCE: $DCE_NAME in resource group $DCE_RG"
      
      # Check for locks on the resource
      echo "Checking for locks on DCE $DCE_NAME..."
      LOCKS=$(az lock list --resource "$DCE_ID" --query "[].id" -o tsv 2>/dev/null)
      
      if [ -n "$LOCKS" ]; then
        echo "Found locks on DCE $DCE_NAME. Attempting to remove locks..."
        for LOCK_ID in $LOCKS; do
          echo "Deleting lock: $LOCK_ID"
          az lock delete --ids "$LOCK_ID"
          if [ $? -eq 0 ]; then
            echo "Successfully deleted lock: $LOCK_ID"
          else
            echo "WARNING: Failed to delete lock: $LOCK_ID"
          fi
        done
      else
        echo "No locks found for DCE $DCE_NAME"
      fi
      
      # Now try to delete the DCE
      echo "Attempting to delete DCE: $DCE_NAME..."
      # Try without debug flag first
      az monitor data-collection endpoint delete --ids "$DCE_ID" --yes
      
      if [ $? -eq 0 ]; then
        echo "Successfully deleted DCE: $DCE_NAME"
      else
        echo "Initial deletion attempt failed. Trying with debug flag for more information..."
        # Try with debug flag for more information
        az monitor data-collection endpoint delete --ids "$DCE_ID" --yes --debug
        if [ $? -eq 0 ]; then
          echo "Successfully deleted DCE: $DCE_NAME with debug mode"
        else
          echo "ERROR: Failed to delete DCE: $DCE_NAME"
          echo "Manual intervention may be required. Try deleting this resource from the Azure portal."
        fi
      fi
      
      echo "------------------------------------------"
    fi
  done
fi

echo "Data Collection resources cleanup process complete"

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -f all_dcrs.txt all_dces.txt
echo "Cleanup complete" 