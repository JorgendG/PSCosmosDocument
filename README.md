# PSCosmosDocument
Interact with Azure CosmosDB document using Powershell

Change these variables to make it work for your account.
```
$CosmosDBEndPoint = "https://youraccountname.documents.azure.com:443/"
$DatabaseId = "DatabaseName"
$CollectionId = "CollectionName"
$MasterKey = "xx Your read/write key xxx"
```

This script use the REST api to interact with Cosmos documents.

I've created/copied/modified 6 functions.
- Generate-MasterKeyAuthorizationSignature
- Query-CosmosDb
- New-CosmosDocument
- Set-CosmosDocument
- Get-CosmosDocument
- Remove-CosmosDocument

As an example the script retrieves the serialnumber, model and BIOS version of my computer and creates a Cosmos document.
