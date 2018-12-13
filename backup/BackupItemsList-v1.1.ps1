


param (
[switch] $classicMode = $false,
[string] $subscriptionId,
[string] $outputFile= "AzureBackupItemsList.csv"
 )

$ErrorActionPreference = "SilentlyContinue"

Connect-AzureRmAccount 

if($classicMode)
{
    #Classic Login
    Add-AzureAccount
}

# Get list of subscriptions
If ($subscriptionId)
    { $subscriptionList = Get-AzureRmSubscription -SubscriptionId $subscriptionId }
Else
    { $subscriptionList = Get-AzureRmSubscription }


    $backupItemsList = @()

# Get all VMs in all subscriptions
foreach($subscription in $subscriptionList)
{
    Select-AzureRmSubscription -SubscriptionName $subscription.Name

    Select-AzureSubscription -SubscriptionName $subscription.Name

     $VMlist = Get-AzureRmVM 
     $ClassicVMlist = Get-AzureVM
    
       
     # Fetching the list of Azure Recovery Services Vault
    $azure_recovery_services_vault_list = Get-AzureRmRecoveryServicesVault


    foreach($azure_recovery_services_vault_list_iterator in $azure_recovery_services_vault_list)
    {

        #Write-Host "*******************************************************************************"
        #Write-Host "Backup Vault Name: "  $azure_recovery_services_vault_list_iterator.Name

        #Setting context
        Set-AzureRmRecoveryServicesVaultContext -Vault $azure_recovery_services_vault_list_iterator
        
        #MARS Backup items
        $container_list = Get-AzureRmRecoveryServicesBackupContainer -ContainerType Windows -BackupManagementType MARS

         foreach($container_list_iterator in $container_list)
        {
            $containerName = $container_list_iterator.Name
            $VMName = $ContainerName.Substring(0,$containerName.IndexOf("."))   
            
            $backupItemInfo = New-Object System.Object
            $backupItemInfo | Add-Member -type NoteProperty -name BackupVault -value $azure_recovery_services_vault_list_iterator.Name
    
            $backupItemInfo | Add-Member -type NoteProperty -name BackupType -value "MARS"
                    
        
            # Search for a VM based on container name
            
            $VM = $VMlist | Where-Object {$_.Name -eq $VMName}
            #Check Classic VM list
            if($VM -eq $null)
            {
                
                if($classicMode)
                {
                    $VM = $ClassicVMlist | Where-Object {$_.Name -eq $VMName}
                }
              
                 if($VM -eq $null)
                {
                    $backupItemInfo | Add-Member -type NoteProperty -name ContainerName -value $containerName
                    $backupItemInfo | Add-Member -type NoteProperty -name Status -value "Orphaned backup/On-Premises VM"
                }
                else
                {
                    $backupItemInfo | Add-Member -type NoteProperty -name ContainerName -value $containerName
                    $backupItemInfo | Add-Member -type NoteProperty -name Status -value "Classic VM exists"
                }

            }
            else
            {
                    $backupItemInfo | Add-Member -type NoteProperty -name ContainerName -value $containerName
                    $backupItemInfo | Add-Member -type NoteProperty -name Status -value "ARM VM exists"
                                   
            }

            $backupItemsList += $backupItemInfo     

        }

        
        #VM Backup items
        $container_listVM = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM -BackupManagementType AzureVM

        foreach($container_list_iteratorVM in $container_listVM)
        {
           
            $containerNameVM = $container_list_iteratorVM.Name
            $containerSep = $ContainerNameVM.IndexOf(";") + 1
            $rgSep = $ContainerNameVM.IndexOf(";",$containerSep)+1

        
            $rgName = $containerNameVM.Substring($containerSep,$rgSep-$containerSep-1)   
            $VMName = $containerNameVM.Substring($rgSep,$containerNameVM.Length-$rgSep)

            
            $backupItemInfo = New-Object System.Object
            $backupItemInfo | Add-Member -type NoteProperty -name BackupVault -value $azure_recovery_services_vault_list_iterator.Name
            $backupItemInfo | Add-Member -type NoteProperty -name BackupType -value "AzureVM"

            # Search for a VM based on container name
            
            $VM = $VMlist | Where-Object {($_.Name -eq $VMName) -and ($_.ResourceGroupName -eq $rgName)}
            #Check Classic VM list
            if($VM -eq $null)
            {
                if($classicMode)
                {
                    $VM = $ClassicVMlist | Where-Object {($_.Name -eq $VMName) -and ($_.ResourceGroupName -eq $rgName) }
                }

              
                   if($VM -eq $null)
                {
                    $backupItemInfo | Add-Member -type NoteProperty -name ContainerName -value $containerNameVM
                    $backupItemInfo | Add-Member -type NoteProperty -name Status -value "Orphaned backup"
                }
                else
                {
                    $backupItemInfo | Add-Member -type NoteProperty -name ContainerName -value $containerNameVM
                    $backupItemInfo | Add-Member -type NoteProperty -name Status -value "Classic VM exists"
                }
            }
            else
            {
                    $backupItemInfo | Add-Member -type NoteProperty -name ContainerName -value $containerNameVM
                    $backupItemInfo | Add-Member -type NoteProperty -name Status -value "ARM VM exists"
               
            }

            $backupItemsList += $backupItemInfo     
        }
        
    }
}

# Write result
$backupItemsList | Format-Table
# Create CSV file
$backupItemsList | Export-csv -NoType  $outputFile -Force 
