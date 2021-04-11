# Include variables
. .\Variables.ps1

Remove-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName

Remove-AzResourceGroup -Name $imageResourceGroup