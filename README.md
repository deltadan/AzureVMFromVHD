# AzureVMFromVHD
Create a VM from an exsisting VHD
Have you ever wished you could take a VHD from a VM and make another one with it?

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
