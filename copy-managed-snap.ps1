#Provide the subscription Id of the subscription where snapshot is created
$subscriptionId = "SUBSCRIPTION ID HERE"

#Provide the name of your resource group where snapshot is created
$resourceGroupName ="RESOURCE GROUP NAME HERE"

#Provide the snapshot name 
$snapshotName = "NAME OF THE SNAPSHOT"

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/azure/storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "3600"

#Provide storage account name where you want to copy the snapshot. 
$storageAccountName = "STORAGE ACCOUNT NAME"

#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = "STORAGE ACCOUNT CONTAINER WHERE FILE"

#Provide the key of the storage account where you want to copy snapshot. 
$storageAccountKey = 'STORAGE ACCOUNT KEY HERE'

#Provide the name of the VHD file to which snapshot will be copied.
$destinationVHDFileName = "FILENAME.VHD"

# Set the context to the subscription Id where Snapshot is created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

#Create the context for the storage account which will be used to copy snapshot to the storage account 
$destinationContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey  

#Generate the SAS for the snapshot using the Azure portal and then paste for Uri
#Copy the snapshot to the storage account 
Start-AzureStorageBlobCopy -AbsoluteUri "PASTE THE URI THAT YOU CREATED HERE" -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName