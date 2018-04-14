<# 

.File Name
 - LabvmFromVHD-clearn.ps1

*What calls this script?*
 - This script should be run manually from a workstation or a VM in Azure.
 - Azure PowerShell cmdlets and WMF < 5.x should be installed on the workstation
 - Must have rights to create a New Resource Group, VNET, VM, NIC, DISK, PUBLIP IPs
 - Target VM with VHD must be deallocated in order to ensure this process works correctly
 - The VHD must be copied to a Standard Storage Account and the container set with a Public Access Policy for Blobs

*What does this script do?*
 - Perform a Blob Copy of VHD from Current VM's Storage Account to a new standard storage account
 - Creates a new Resource Group in the location provided by the user in the $LabRG variable (all reside here)
 - Provisions VNET with one Subnet
 - Creates a new Azure Managed Disk using SSDs from the VHD
 - Creates a new Azure VM attaching the new Managed disk created by this script based on the VHD
 
#>

#Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

### Defines the location of the VHD we want to copy
$sourceVhdUri = "https://STUDENT-ACCT-NAME-HERE.blob.core.windows.net/vhd/VHD-NAME-HERE.vhd"
 
### Defines the source Storage Account (Teacher's Account with VHD)
$sourceStorageAccountName = "TEACHER-STORAGEACCT-NAME-HERE"
$sourceStorageKey = "STORAGE-ACCT-KEY-HERE"
 
### Defines the target Storage Account (Student should create new account)
$destStorageAccountName = "STUDENT-STORAGEACCT-NAME-HERE"
$destStorageKey = "STORAGE-ACCT-KEY-HERE"
 
### Create a context for the source storage account
$sourceContext = New-AzureStorageContext  –StorageAccountName $sourceStorageAccountName `
                                        -StorageAccountKey $sourceStorageKey  
 
### Create a context for the target storage account
$destContext = New-AzureStorageContext  –StorageAccountName $destStorageAccountName `
                                        -StorageAccountKey $destStorageKey  
 
### Name for the destination storage container
$containerName = "vhd"
 
### Create a new container in the destination storage
New-AzureStorageContainer -Name $containerName -Context $destContext 
 
### Start the async copy operation
$blob1 = Start-AzureStorageBlobCopy -srcUri $sourceVhdUri `
                                    -SrcContext $srcContext `
                                    -DestContainer $containerName `
                                    -DestBlob "VHD-NAME-HERE.vhd" `
                                    -DestContext $destContext
 
### Get the status of the copy operation
$status = $blob1 | Get-AzureStorageBlobCopyState 
 
### Output the status every 10 seconds until it is finished                                    
While($status.Status -eq "Pending"){
  $status = $blob1 | Get-AzureStorageBlobCopyState 
  Start-Sleep 10
  $status
}

#Login to Azure
Login-AzureRmAccount

#Provide the name of your resource group where the LabVM will be created
#This location should be same as the storage account where the instructors VHD file is stored
$LabRG = New-AzureRmResourceGroup -Name LabRG -Location westus2

#Create a VNET for the LabVM
$vNet = New-AzureRmVirtualNetwork `
  -ResourceGroupName $LabRG.ResourceGroupName `
  -Location $LabRG.location `
  -Name LabVNET `
  -AddressPrefix 192.168.0.0/24

  $subnetConfigPublic = Add-AzureRmVirtualNetworkSubnetConfig `
  -Name Lab `
  -AddressPrefix 192.168.0.0/24 `
  -VirtualNetwork $vNet

  $vNet | Set-AzureRmVirtualNetwork

#Provide the subscription Id where Managed Disks will be created
#$subscriptionId = 'yourSubscriptionId'
$subscriptionId = 'STUDENT-SUBSCRIPTION-ID-HERE'

#Provide the name of the Managed Disk
$diskName = 'labvmosdisk'

#Provide the size of the disks in GB. It should be greater than the VHD file size.
$diskSize = '128'

#Provide the storage type for Managed Disk. PremiumLRS or StandardLRS.
$storageType = 'PremiumLRS'

#Provide the Azure region (e.g. westus2) where Managed Disk will be located.
#This location should be same as the resource group above and where the instructor VHD is located
$location = 'westus2'

#Provide the URI of the VHD file (page blob) in a storage account. 
#$sourceVHDURI = 'https://contosostorageaccount1.blob.core.windows.net/vhds/contosovhd123.vhd'
$sourceVHDURI = 'https://STUDENT-STORAGEACCT-NAME-HERE.blob.core.windows.net/vhd/VHD-NAME-HERE.vhd'

#Set the context to the subscription Id where Managed Disk will be created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId
$diskConfig = New-AzureRmDiskConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI
New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $LabRG.ResourceGroupName -DiskName $diskName
$disk = Get-AzureRmDisk -Name $diskName -ResourceGroupName $LabRG.ResourceGroupName

#Create a public IP for the VM  
$publicIp = New-AzureRmPublicIpAddress -Name LabVMPubIP -ResourceGroupName $LabRG.ResourceGroupName -Location $LabRG.Location -AllocationMethod Dynamic

# Create NIC in the first subnet of the virtual network 
$virtualNetwork = Get-AzureRmVirtualNetwork -Name $vnet.Name -ResourceGroupName $LabRg.ResourceGroupName
$nic = New-AzureRmNetworkInterface -Name LabVMNIC -ResourceGroupName $LabRG.ResourceGroupName -Location $LabRG.Location -SubnetId $virtualnetwork.Subnets[0].Id -PublicIpAddressId $publicIp.Id

#Initialize virtual machine configuration
$virtualMachineName = "LabVM"
$virtualMachineSize = 'Standard_E2s_v3'
$virtualMachine = New-AzureRmVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize
$virtualMachine = Add-AzureRmVMNetworkInterface -VM $virtualMachine -Id $nic.Id
$virtualMachine = Set-AzureRmVMOSDisk -VM $virtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

#Create the virtual machine with Managed Disk
New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $LabRG.ResourceGroupName -Location $LabRG.Location
