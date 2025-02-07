# PowerAutomatePermissons
A PowerShell script that scans PowerApps flows in a specified environment to identify flows where a specified user does not have permissions, and optionally grants the user **CanEdit** rights (co-owner permissions) to those flows. After applying the changes, the script re-scans to confirm that the user now has access to all flows.
