$uname = <<"service principal App ID">>
$passwd = ConvertTo-SecureString -String <<"Service Principal secret">> -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $uname, $passwd
Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant <<tenant ID>>
$context = Get-AzContext
$vault = Get-AzRecoveryServicesVault -Name <<'vault name'>>
$vmmcloud = "<<VMM Cloud Name>>"
$rg = Get-AzResourceGroup -Name $vault.ResourceGroupName
$storageAccount = Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName
$saId = Get-AzResource -Name $storageAccount.StorageAccountName -ResourceGroupName $rg.ResourceGroupName
Set-AzRecoveryServicesAsrVaultContext -Vault $vault
$fabric = Get-AzRecoveryServicesAsrFabric -FriendlyName <<'SCVMM Server name in ASR Site Recovery Infrastructure'>>
$protectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric -FriendlyName $vmmcloud
$containerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $protectioncontainer 
$vm = Get-SCVirtualMachine | Where { $_.cloud.name -eq $vmmcloud }
Write-Host "VM "+ $vm.Name
$vm | ForEach-Object {
    Write-Host "tag for VM "+ $_.Name +" is "+ $_.tag
    $protectableItem = Get-AzRecoveryServicesAsrProtectableItem -ProtectionContainer $protectioncontainer -FriendlyName $_.Name
	If($_.tag -like "*Critical*") {
        Write-Host "Tag is critical for "+ $_.Name
		
        Write-Host "inside if Protection status is "+ $protectableItem.ProtectionStatus
		If( $protectableItem.ProtectionStatus -eq "Unprotected") {
			Write-Host "inside if enabling Protection"
			New-AzRecoveryServicesAsrReplicationProtectedItem -HyperVToAzure -ProtectableItem $protectableItem -ProtectionContainerMapping $containerMapping -Name $protectableItem.Name -OS $protectableItem.OS -RecoveryAzureStorageAccountId $said.ResourceId -OSDiskName $protectableItem.Disks.Name -RecoveryResourceGroupId $rg.ResourceId
		}
	}else{
        Write-Host "inside else "+ $_.Name +" tag "+ $_.tag
		
        Write-Host "Inside else Protection status is "+ $protectableItem.ProtectionStatus
		If( $protectableItem.ProtectionStatus -eq "Protected") {
			Write-Host "inside if disabling Protection"
			$protectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $protectioncontainer -FriendlyName $_.Name
			Remove-AzRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $protectedItem
		}
	}
}