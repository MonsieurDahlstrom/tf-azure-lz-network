# PowerShell script for cleaning up Azure Data Collection resources created by Network Watcher Flow Logs
# Usage: .\dcr_cleanup.ps1 -ResourceGroup <MODULE_RG> -SubscriptionId <SUBSCRIPTION_ID> -NamePattern <NAME_PATTERN>

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$NamePattern = "NWTA"  # Default to "NWTA" which appears in the DCR name
)

Write-Host "Starting Azure Data Collection resource cleanup in subscription $SubscriptionId"

# Set context to the right subscription
Write-Host "Setting Azure subscription context..."
try {
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to set Azure subscription context" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: Failed to set Azure subscription context: $_" -ForegroundColor Red
    exit 1
}

# Enable preview extensions and install required extension
Write-Host "Configuring Azure CLI extensions..."
az config set extension.dynamic_install_allow_preview=true
az extension add --name monitor-control-service --allow-preview true --yes

#######################
# PART 1: CLEAN UP DATA COLLECTION RULES
#######################

Write-Host "===== DATA COLLECTION RULES CLEANUP =====" -ForegroundColor Cyan
# Get all DCRs directly without filtering first
Write-Host "Getting all DCRs in the subscription..."
# Save the full list to a file for reference
az monitor data-collection rule list --subscription $SubscriptionId --query "[].{name:name, resourceGroup:resourceGroup, id:id}" -o table | Out-File -FilePath "all_dcrs.txt"
Write-Host "Full list of DCRs saved to all_dcrs.txt"

# Get all DCR IDs from the module resource group
Write-Host "Getting all DCR IDs from resource group $ResourceGroup"
$moduleDcrIds = (az monitor data-collection rule list --resource-group $ResourceGroup --query "[].id" -o tsv)
$dcrCount = ($moduleDcrIds | Where-Object {$_ -ne ""} | Measure-Object).Count
Write-Host "DCRs found in resource group $ResourceGroup`: $dcrCount"

# Delete matching DCRs
if ([string]::IsNullOrEmpty($moduleDcrIds) -or $dcrCount -eq 0) {
    Write-Host "No Data Collection Rules found to delete."
} else {
    Write-Host "Found DCRs to clean up. Starting deletion..." -ForegroundColor Yellow
    # Loop through each DCR ID and delete it
    $moduleDcrIds | Where-Object {$_ -ne ""} | ForEach-Object {
        $dcrId = $_
        if (![string]::IsNullOrEmpty($dcrId)) {
            $dcrRg = $dcrId.Split('/')[4]
            $dcrName = $dcrId.Split('/')[8]
            Write-Host "Processing DCR: $dcrName in resource group $dcrRg" -ForegroundColor Yellow
            
            # First, check and delete any associations
            Write-Host "Checking for associations on DCR $dcrName..."
            $associations = (az monitor data-collection rule association list --rule-id $dcrId --query "[].id" -o tsv 2>$null)
            
            if (![string]::IsNullOrEmpty($associations)) {
                Write-Host "Found associations for DCR $dcrName. Deleting associations first..."
                $associations | ForEach-Object {
                    $assocId = $_
                    Write-Host "Deleting association: $assocId"
                    az monitor data-collection rule association delete --ids $assocId --yes
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Successfully deleted association: $assocId" -ForegroundColor Green
                    } else {
                        Write-Host "WARNING: Failed to delete association: $assocId" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "No associations found for DCR $dcrName"
            }
            
            # Check for locks on the resource
            Write-Host "Checking for locks on DCR $dcrName..."
            $locks = (az lock list --resource $dcrId --query "[].id" -o tsv 2>$null)
            
            if (![string]::IsNullOrEmpty($locks)) {
                Write-Host "Found locks on DCR $dcrName. Attempting to remove locks..."
                $locks | ForEach-Object {
                    $lockId = $_
                    Write-Host "Deleting lock: $lockId"
                    az lock delete --ids $lockId
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Successfully deleted lock: $lockId" -ForegroundColor Green
                    } else {
                        Write-Host "WARNING: Failed to delete lock: $lockId" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "No locks found for DCR $dcrName"
            }
            
            # Now try to delete the DCR
            Write-Host "Attempting to delete DCR: $dcrName..."
            # Try without debug flag first
            az monitor data-collection rule delete --ids $dcrId --yes
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully deleted DCR: $dcrName" -ForegroundColor Green
            } else {
                Write-Host "Initial deletion attempt failed. Trying with debug flag for more information..." -ForegroundColor Yellow
                # Try with debug flag for more information
                az monitor data-collection rule delete --ids $dcrId --yes --debug
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Successfully deleted DCR: $dcrName with debug mode" -ForegroundColor Green
                } else {
                    Write-Host "ERROR: Failed to delete DCR: $dcrName" -ForegroundColor Red
                    Write-Host "Manual intervention may be required. Try deleting this resource from the Azure portal."
                }
            }
            
            Write-Host "------------------------------------------"
        }
    }
}

#######################
# PART 2: CLEAN UP DATA COLLECTION ENDPOINTS
#######################

Write-Host "===== DATA COLLECTION ENDPOINTS CLEANUP =====" -ForegroundColor Cyan
# Get all DCEs in the module resource group
Write-Host "Getting all Data Collection Endpoints in resource group $ResourceGroup..."
# Save the full list to a file for reference
az monitor data-collection endpoint list --resource-group $ResourceGroup --query "[].{name:name, id:id}" -o table | Out-File -FilePath "all_dces.txt"
Write-Host "Full list of DCEs saved to all_dces.txt"

# Get all DCE IDs from the module resource group
$moduleDceIds = (az monitor data-collection endpoint list --resource-group $ResourceGroup --query "[].id" -o tsv)
$dceCount = ($moduleDceIds | Where-Object {$_ -ne ""} | Measure-Object).Count
Write-Host "DCEs found in resource group $ResourceGroup`: $dceCount"

# Delete Data Collection Endpoints
if ([string]::IsNullOrEmpty($moduleDceIds) -or $dceCount -eq 0) {
    Write-Host "No Data Collection Endpoints found to delete."
} else {
    Write-Host "Found DCEs to clean up. Starting deletion..." -ForegroundColor Yellow
    # Loop through each DCE ID and delete it
    $moduleDceIds | Where-Object {$_ -ne ""} | ForEach-Object {
        $dceId = $_
        if (![string]::IsNullOrEmpty($dceId)) {
            $dceRg = $dceId.Split('/')[4]
            $dceName = $dceId.Split('/')[8]
            Write-Host "Processing DCE: $dceName in resource group $dceRg" -ForegroundColor Yellow
            
            # Check for locks on the resource
            Write-Host "Checking for locks on DCE $dceName..."
            $locks = (az lock list --resource $dceId --query "[].id" -o tsv 2>$null)
            
            if (![string]::IsNullOrEmpty($locks)) {
                Write-Host "Found locks on DCE $dceName. Attempting to remove locks..."
                $locks | ForEach-Object {
                    $lockId = $_
                    Write-Host "Deleting lock: $lockId"
                    az lock delete --ids $lockId
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Successfully deleted lock: $lockId" -ForegroundColor Green
                    } else {
                        Write-Host "WARNING: Failed to delete lock: $lockId" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "No locks found for DCE $dceName"
            }
            
            # Now try to delete the DCE
            Write-Host "Attempting to delete DCE: $dceName..."
            # Try without debug flag first
            az monitor data-collection endpoint delete --ids $dceId --yes
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully deleted DCE: $dceName" -ForegroundColor Green
            } else {
                Write-Host "Initial deletion attempt failed. Trying with debug flag for more information..." -ForegroundColor Yellow
                # Try with debug flag for more information
                az monitor data-collection endpoint delete --ids $dceId --yes --debug
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Successfully deleted DCE: $dceName with debug mode" -ForegroundColor Green
                } else {
                    Write-Host "ERROR: Failed to delete DCE: $dceName" -ForegroundColor Red
                    Write-Host "Manual intervention may be required. Try deleting this resource from the Azure portal."
                }
            }
            
            Write-Host "------------------------------------------"
        }
    }
}

Write-Host "Data Collection resources cleanup process complete" -ForegroundColor Green

# Clean up temporary files
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path "all_dcrs.txt", "all_dces.txt" -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup complete" -ForegroundColor Green 