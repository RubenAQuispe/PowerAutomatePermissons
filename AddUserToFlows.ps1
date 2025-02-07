<#
.SYNOPSIS
    Scans flows in a given PowerApps environment to identify flows where a specified user does not have permissions,
    and optionally grants "CanEdit" rights if desired.

.DESCRIPTION
    This script performs two modes of operation:
      1. Scan Mode (default): When run without parameters, it scans the specified PowerApps environment and lists flows
         where the specified user (by their Azure AD Object ID) does not have permissions.
      2. Change Mode: When run with the -Change switch parameter, the script will:
           - Scan for flows missing the user.
           - Grant the user "CanEdit" permissions (i.e. co-owner permissions) on those flows.
           - Re-scan all flows to confirm that the user now has access.
           
.PARAMETERS
    -Change [switch]
        Optional. If provided, the script will add the user with "CanEdit" rights to flows where they are missing,
        and then re-run the scan to confirm.

CONFIGURATION (Values to update before running)
    - $environmentName:
         The unique name/ID of your PowerApps environment.
         To list your environments, run: Get-AdminPowerAppEnvironment
    - $userObjectId:
         The Azure AD Object ID for the target user.
         To obtain this, use the Azure portal (Azure AD > Users > [Select a user]) or run:
              Get-AzureADUser -SearchString "username"
              
.NOTES
    - Requires the Microsoft.PowerApps.Administration.PowerShell module.
    - If not installed, run:
            Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
    - Ensure you have the necessary permissions to manage flows in the specified environment.

.EXAMPLES
    # To simply scan and display flows where the user is missing:
    .\AddUserToFlows.ps1

    # To scan, add the user to missing flows, and re-scan to confirm:
    .\AddUserToFlows.ps1 -Change
#>

[CmdletBinding()]
param(
    [switch]$Change
)

# Suppress unapproved verb warnings for cleaner output
$WarningPreference = "SilentlyContinue"

# Import the PowerApps Administration module
try {
    Import-Module Microsoft.PowerApps.Administration.PowerShell -ErrorAction Stop
} catch {
    Write-Host "Module Microsoft.PowerApps.Administration.PowerShell is not installed."
    Write-Host "Please install it using:"
    Write-Host "Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber"
    exit
}

# Authenticate to PowerApps (a sign-in window will appear)
Write-Host "Authenticating to PowerApps..."
Add-PowerAppsAccount

# ============================================
# CONFIGURATION - MODIFY THESE VALUES AS NEEDED
# ============================================
# Environment Name:
# To list available environments, run: Get-AdminPowerAppEnvironment
$environmentName = "Default-80f85a20-1d46-4453-8556-7fa4ef991f30"

# User Object ID:
# Obtain this from the Azure AD portal or run: Get-AzureADUser -SearchString "username"
$userObjectId = "d35aa5e8-a280-47f8-bd02-c0e1b63180ed"
# ============================================
# END OF CONFIGURATION
# ============================================

Write-Host "Processing flows in environment: $environmentName"
Write-Host "Target User Object ID: $userObjectId"

# Retrieve all flows in the specified environment
Write-Host "Retrieving all flows..."
$flows = Get-AdminFlow -EnvironmentName $environmentName

if ($flows -eq $null -or $flows.Count -eq 0) {
    Write-Host "No flows found in the environment '$environmentName'."
    exit
}

# Function: Get-FlowsMissingUser
# Scans the flows and returns an array of flows where the specified user does not have permissions.
function Get-FlowsMissingUser {
    param (
        [string]$envName,
        [string]$userId
    )
    $missingFlows = @()
    foreach ($flow in $flows) {
        $owners = Get-AdminFlowOwnerRole -EnvironmentName $envName -FlowName $flow.FlowName
        $userPresent = $owners | Where-Object { $_.PrincipalObjectId -eq $userId }
        if (-not $userPresent) {
            $missingFlows += [PSCustomObject]@{
                DisplayName = $flow.DisplayName
                FlowName    = $flow.FlowName
            }
        }
    }
    return $missingFlows
}

# --- STEP 1: Initial Scan ---
$flowsMissingUser = Get-FlowsMissingUser -envName $environmentName -userId $userObjectId

if ($flowsMissingUser.Count -eq 0) {
    Write-Host "All flows in environment '$environmentName' already have the user with permissions."
} else {
    Write-Host "The following flows do NOT have the user with CanEdit permissions:"
    $flowsMissingUser | Format-Table -Wrap -AutoSize | Out-String -Width 2000 | Write-Host
}

# --- STEP 2: If -Change switch is provided, add the user to missing flows ---
if ($Change) {
    Write-Host "`nChange mode activated. Adding user with CanEdit permissions to missing flows..."
    foreach ($flow in $flowsMissingUser) {
        Write-Host "Adding user with CanEdit permission to flow: $($flow.DisplayName) ($($flow.FlowName))"
        try {
            Set-AdminFlowOwnerRole -EnvironmentName $environmentName `
                                   -FlowName $flow.FlowName `
                                   -PrincipalObjectId $userObjectId `
                                   -PrincipalType "User" `
                                   -RoleName "CanEdit"
            Write-Host "Successfully added user to flow: $($flow.DisplayName)"
        }
        catch {
            Write-Host "Error adding user to flow: $($flow.DisplayName)."
            Write-Host "Error details: $_"
        }
    }

    # --- STEP 3: Re-run scan to confirm the user now has permissions on all flows ---
    Write-Host "`nRe-checking flows for the user after applying changes..."
    $flowsMissingAfter = Get-FlowsMissingUser -envName $environmentName -userId $userObjectId
    if ($flowsMissingAfter.Count -eq 0) {
        Write-Host "The user now has access to all flows in environment '$environmentName'."
    } else {
        Write-Host "The following flows are still missing the user with CanEdit permissions:"
        $flowsMissingAfter | Format-Table -Wrap -AutoSize | Out-String -Width 2000 | Write-Host
    }
}

# Restore warning preference
$WarningPreference = "Continue"

Write-Host "Script execution complete."
