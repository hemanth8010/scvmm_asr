#Connection object scvmm, Variable objects such as vaultName, vmmCloudName and vmmServerName are to be created in Azure Automation prior to running this script.

$Credential = Get-AutomationPSCredential -Name 'scvmm'
Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant ca9ebe88-c751-4d5b-88c8-1471413e3b44
$context = Get-AzContext
$vaultName = Get-AutomationVariable -Name 'vaultName'
$vault = Get-AzRecoveryServicesVault -Name $vaultName
$vmmcloud = Get-AutomationVariable -Name 'vmmCloudName'
try {
$rg = Get-AzResourceGroup -Name $vault.ResourceGroupName
Write-Output "resource group $($rg)"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName
$saId = Get-AzResource -Name $storageAccount.StorageAccountName -ResourceGroupName $rg.ResourceGroupName
Set-AzRecoveryServicesAsrVaultContext -Vault $vault
$vmmServer = Get-AutomationVariable -Name 'vmmServerName'
$fabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $vmmServer
$protectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric -FriendlyName $vmmcloud
$containerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $protectioncontainer 
$VMMConn = Get-SCVMMServer -ComputerName "labazvmm2016.invisodev.com"
$vm = Get-SCVirtualMachine | Where { $_.cloud.name -eq $vmmcloud }
}
catch {
    Write-Output "error: $($_.exception.message)"
}
$vm | ForEach-Object {
		Write-Output "tag for VM  $($_.Name)  is  $($_.tag)"
		$protectableItem = Get-AzRecoveryServicesAsrProtectableItem -ProtectionContainer $protectioncontainer -FriendlyName $_.Name
		If($_.tag -like "*Critical*") {
			
			Write-Output "Tag is critical for $($_.Name)"

			Write-Output "inside if Protection status is $($protectableItem.ProtectionStatus)"
			If( $protectableItem.ProtectionStatus -eq "Unprotected") {

				Write-Output "inside if enabling Protection"
				try {
					New-AzRecoveryServicesAsrReplicationProtectedItem -HyperVToAzure -ProtectableItem $protectableItem -ProtectionContainerMapping $containerMapping -Name $protectableItem.Name -OS $protectableItem.OS -RecoveryAzureStorageAccountId $said.ResourceId -OSDiskName $protectableItem.Disks.Name -RecoveryResourceGroupId $rg.ResourceId
				}
				catch{
					Write-Output "Failed to enable protection: $($_.exception.message)"
				}
			}
		}else{

			Write-Output "inside else $($_.Name) tag $($_.tag)"

			Write-Output "Inside else Protection status is $($protectableItem.ProtectionStatus)"
			If( $protectableItem.ProtectionStatus -eq "Protected") {

				Write-Output "inside if disabling Protection"
				try {
					$protectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $protectioncontainer -FriendlyName $_.Name
					Remove-AzRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $protectedItem
				}
				catch{
					Write-Output "Failed to disable protection: $($_.exception.message)"
				}
			}
		}

	
    
    
}