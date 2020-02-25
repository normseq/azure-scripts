This PowerShell script allows you to view the 'orphaned' backup items in your Azure Recovery Vault. 
Over time, you may have backups in your vaults, but the corresponding VM's might've been deleted and these backups may not be required. 

This feature is now also available in the Backup Explorer (Preview). 
You can filter using the 'Resource State' column and view the items which are flagged off as 'VM not active'. 
https://docs.microsoft.com/en-us/azure/backup/monitor-azure-backup-with-backup-explorer#the-backup-items-tab
