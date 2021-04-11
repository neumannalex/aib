# Include variables
. .\Variables.ps1

# Name of the VM
$vmName = 'myWinVM01'

$Cred = Get-Credential

$ArtifactId = (Get-AzImageBuilderRunOutput -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup).ArtifactId

New-AzVM -ResourceGroupName $imageResourceGroup -Image $ArtifactId -Name $vmName -Credential $Cred