# AddUserToFlows

A PowerShell script that scans PowerApps flows in a specified environment to identify flows where a specified user does not have permissions, and optionally grants the user **CanEdit** rights (co-owner permissions) to those flows. After applying the changes, the script re-scans to confirm that the user now has access to all flows.

## Overview

This script is designed for administrators managing PowerApps flows. It offers two modes of operation:

- **Scan Mode (Default):**  
  When run without any parameters, the script scans your PowerApps environment and lists all flows where the specified user is missing permissions.

- **Change Mode:**  
  When run with the `-Change` switch, the script will:
  1. Scan for flows missing the user.
  2. Add **CanEdit** permissions for the user to those flows.
  3. Re-scan to confirm the user now has access to all flows.

## Prerequisites

- **PowerShell 5.1 or later** (or PowerShell Core on supported platforms)
- **Microsoft.PowerApps.Administration.PowerShell** module  
  Install with:
  ```powershell
  Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
