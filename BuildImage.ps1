# Include variables
. .\Variables.ps1

Connect-AzAccount

# Your Azure Subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Output $subscriptionID

# Create a Resource Group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

# Create a managed identity
[int]$timeInt = $(Get-Date -UFormat '%s')
$imageRoleDefName = "Azure Image Builder Image Def $timeInt"
$identityName = "myIdentity$timeInt"

New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

# Load role definition template
$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json'
$myRoleImageCreationPath = "$env:TEMP\myRoleImageCreation.json"

Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing

# Replace placeholders in template
$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

# Create new role definition
New-AzRoleDefinition -InputFile $myRoleImageCreationPath

# Assign role definition to managed identity
$RoleAssignParams = @{
    ObjectId = $identityNamePrincipalId
    RoleDefinitionName = $imageRoleDefName
    Scope = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
  }
New-AzRoleAssignment @RoleAssignParams

# Create new Shared Image Gallery
New-AzGallery -GalleryName $myGalleryName -ResourceGroupName $imageResourceGroup -Location $location

# Create new image definition in gallery
$GalleryParams = @{
    GalleryName = $myGalleryName
    ResourceGroupName = $imageResourceGroup
    Location = $location
    Name = $imageDefName
    OsState = 'generalized'
    OsType = 'Windows'
    Publisher = 'Alex'
    Offer = 'CompileMachine'
    Sku = 'dSpace-2019'
  }
New-AzGalleryImageDefinition @GalleryParams

# Define source object for image builder
$SrcObjParams = @{
    SourceTypePlatformImage = $true
    Publisher = 'MicrosoftWindowsDesktop'
    Offer = 'Windows-10'
    Sku = '19h1-ent'
    Version = 'latest'
  }
$srcPlatform = New-AzImageBuilderSourceObject @SrcObjParams

# Define distributor object for image builder to distribute image to shared gallery
$disObjParams = @{
    SharedImageDistributor = $true
    ArtifactTag = @{tag='dis-share'}
    GalleryImageId = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup/providers/Microsoft.Compute/galleries/$myGalleryName/images/$imageDefName"
    ReplicationRegion = $location
    RunOutputName = $runOutputName
    ExcludeFromLatest = $false
  }
$disSharedImg = New-AzImageBuilderDistributorObject @disObjParams

# Add customization to image builder
$ImgCustomParams01 = @{
    PowerShellCustomizer = $true
    CustomizerName = 'settingUpMgmtAgtPath'
    RunElevated = $false
    Inline = @("mkdir c:\\buildActions", "mkdir c:\\buildArtifacts", "echo Azure-Image-Builder-Was-Here-At $((Get-Date).ToUniversalTime()) > c:\\buildActions\\buildActionsOutput.txt")
  }
$Customizer01 = New-AzImageBuilderCustomizerObject @ImgCustomParams01

# Add another customization to image builder
$ImgCustomParams02 = @{
    FileCustomizer = $true
    CustomizerName = 'downloadBuildArtifacts'
    Destination = 'c:\\buildArtifacts\\index.html'
    SourceUri = 'https://raw.githubusercontent.com/azure/azvmimagebuilder/master/quickquickstarts/exampleArtifacts/buildArtifacts/index.html'
  }
$Customizer02 = New-AzImageBuilderCustomizerObject @ImgCustomParams02

# Install Chocolatey
$ImgCustomParams03 = @{
  PowerShellCustomizer = $true
  CustomizerName = 'installSoftware'
  RunElevated = $true
  ScriptUri = 'https://github.com/neumannalex/aib/blob/master/InstallSoftware.ps1'
}
$Customizer03 = New-AzImageBuilderCustomizerObject @ImgCustomParams03

# Create image template
$ImgTemplateParams = @{
    ImageTemplateName = $imageTemplateName
    ResourceGroupName = $imageResourceGroup
    Source = $srcPlatform
    Distribute = $disSharedImg
    Customize = $Customizer01, $Customizer02, $Customizer03
    Location = $location
    UserAssignedIdentityId = $identityNameResourceId
  }
New-AzImageBuilderTemplate @ImgTemplateParams

# Check if image template was created successfully
Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup | Select-Object -Property Name, LastRunStatusRunState, LastRunStatusMessage, ProvisioningState

# Start image build (can take op to an hour!)
Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName