# Include variables
. .\Variables.ps1

Write-Host $imageResourceGroup

# Find image publisher, offer and sku for base image
$locName = "WestEurope"
Get-AzVMImagePublisher -Location $locName | Select-Object PublisherName

$pubName = "MicrosoftWindowsDesktop"
Get-AzVMImageOffer -Location $locName -PublisherName $pubName | Select-Object Offer

$offerName="Windows-10"
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select-Object Skus

$skuName="19h1-ent"
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Sku $skuName | Select-Object Version