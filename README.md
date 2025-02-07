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
  3. Re-scan to confirm that the user now has access to all flows.

## Prerequisites

- **PowerShell 5.1 or later** (or PowerShell Core on supported platforms)
- **Microsoft.PowerApps.Administration.PowerShell** module  
  Install with:
  ```powershell
  Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
  ```
- Appropriate permissions to manage flows in your PowerApps environment.
- Azure Active Directory permissions to retrieve the target user's Object ID.

## Getting Started

### Clone or Download the Repository

Clone the repository using Git:
```sh
git clone https://github.com/YourUsername/AddUserToFlows.git
cd AddUserToFlows
```
Or download the repository as a ZIP file and extract it.

### Configure the Script

Open `AddUserToFlows.ps1` in your favorite text editor and update the configuration parameters at the top of the file:

- **`$environmentName`**: The unique name/ID of your PowerApps environment.  
  To list your environments, run:
  ```powershell
  Get-AdminPowerAppEnvironment
  ```

- **`$userObjectId`**: The Azure AD Object ID of the user you want to add.  
  To obtain this, use the Azure portal (Azure AD > Users > [Select a user]) or run:
  ```powershell
  Get-AzureADUser -SearchString "username"
  ```

### Running the Script

#### Scan Mode (Default)

To scan and display flows where the user is missing, open PowerShell in the repository directory and run:
```powershell
.\AddUserToFlows.ps1
```
The script will output a list of flows (showing both the Display Name and Flow Name) where the user does not currently have **CanEdit** permissions.

#### Change Mode

To add the user with **CanEdit** permissions to all flows where they are missing, run:
```powershell
.\AddUserToFlows.ps1 -Change
```
In this mode, the script will:
- Scan for flows missing the user.
- Add **CanEdit** rights (co-owner permissions) to those flows.
- Re-run the scan and print a confirmation message if the user now has access to all flows.

## Script Details

### Authentication
The script authenticates using `Add-PowerAppsAccount`, which will prompt you to sign in with your PowerApps credentials.

### Adding Permissions
The script uses the `Set-AdminFlowOwnerRole` cmdlet with the following parameters:
- **PrincipalType:** `"User"`
- **RoleName:** `"CanEdit"`

This ensures the user is added with edit rights (co-owner) without modifying any existing permissions.

### Error Handling
Basic error handling is built in. Errors encountered while adding permissions will be displayed in the console.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

Use this script at your own risk. It is recommended to test in a non-production environment first and ensure you have proper backups before running it in production.

