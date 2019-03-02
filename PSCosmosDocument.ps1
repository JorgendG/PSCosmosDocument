Add-Type -AssemblyName System.Web

# generate authorization key
Function Generate-MasterKeyAuthorizationSignature
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)][String]$verb,
		[Parameter(Mandatory=$true)][String]$resourceLink,
		[Parameter(Mandatory=$true)][String]$resourceType,
		[Parameter(Mandatory=$true)][String]$dateTime,
		[Parameter(Mandatory=$true)][String]$key,
		[Parameter(Mandatory=$true)][String]$keyType,
		[Parameter(Mandatory=$true)][String]$tokenVersion
	)

	$hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
	$hmacSha256.Key = [System.Convert]::FromBase64String($key)

	$payLoad = "$($verb.ToLowerInvariant())`n$($resourceType.ToLowerInvariant())`n$resourceLink`n$($dateTime.ToLowerInvariant())`n`n"
	$hashPayLoad = $hmacSha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($payLoad))
	$signature = [System.Convert]::ToBase64String($hashPayLoad);

	[System.Web.HttpUtility]::UrlEncode("type=$keyType&ver=$tokenVersion&sig=$signature")
}

# query
Function Query-CosmosDb
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)][String]$EndPoint,
		[Parameter(Mandatory=$true)][String]$DataBaseId,
		[Parameter(Mandatory=$true)][String]$CollectionId,
		[Parameter(Mandatory=$true)][String]$MasterKey,
		[Parameter(Mandatory=$true)][String]$Query
	)

	$Verb = "POST"
	$ResourceType = "docs";
	$ResourceLink = "dbs/$DatabaseId/colls/$CollectionId"

	$dateTime = [DateTime]::UtcNow.ToString("r")
	$authHeader = Generate-MasterKeyAuthorizationSignature -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
	$queryJson = @{query=$Query} | ConvertTo-Json
	$header = @{authorization=$authHeader;"x-ms-documentdb-isquery"="True";"x-ms-version"="2017-02-22";"x-ms-date"=$dateTime}
	$contentType= "application/query+json"
	$queryUri = "$EndPoint$ResourceLink/docs"

	$result = Invoke-RestMethod -Method $Verb -ContentType $contentType -Uri $queryUri -Headers $header -Body $queryJson

	$result | ConvertTo-Json -Depth 10
}

Function New-CosmosDocument
{
    [CmdletBinding()]
    Param
    (
    [Parameter(Mandatory=$true)][String]$EndPoint,
    [Parameter(Mandatory=$true)][String]$DataBaseId,
    [Parameter(Mandatory=$true)][String]$CollectionId,
    [Parameter(Mandatory=$true)][String]$MasterKey,
    [Parameter(Mandatory=$true)][String]$JSON
    )
 
    $Verb = "POST"
    $ResourceType = "docs";
    $ResourceLink = "dbs/$DatabaseId/colls/$CollectionId"
 
    $dateTime = [DateTime]::UtcNow.ToString("r")
    $authHeader = Generate-MasterKeyAuthorizationSignature -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
    $header = @{authorization=$authHeader;"x-ms-version"="2017-02-22";"x-ms-date"=$dateTime}
    $contentType= "application/json"
    $queryUri = "$EndPoint$ResourceLink/docs"
 
    $result = Invoke-RestMethod -Method $Verb -ContentType $contentType -Uri $queryUri -Headers $header -Body $JSON
    return $result.statuscode
}

Function Set-CosmosDocument
{
    [CmdletBinding()]
    Param
    (
    [Parameter(Mandatory=$true)][String]$EndPoint,
    [Parameter(Mandatory=$true)][String]$DataBaseId,
    [Parameter(Mandatory=$true)][String]$CollectionId,
    [Parameter(Mandatory=$true)][String]$MasterKey,
    [Parameter(Mandatory=$true)][String]$DocumentID,
    [Parameter(Mandatory=$true)][String]$JSON
    )
 
    $Verb = "PUT"
    $ResourceType = "docs"
    $ResourceLink = "dbs/$DatabaseId/colls/$CollectionId/docs/$DocumentID"
 
    $dateTime = [DateTime]::UtcNow.ToString("r")
    $authHeader = Generate-MasterKeyAuthorizationSignature -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
    $header = @{authorization=$authHeader;"x-ms-version"="2017-02-22";"x-ms-date"=$dateTime}
    $contentType= "application/json"
    $queryUri = "$EndPoint$ResourceLink"
 
    $result = Invoke-RestMethod -Method $Verb -ContentType $contentType -Uri $queryUri -Headers $header -Body $JSON
    return $result.statuscode
}

Function Get-CosmosDocument
{
    [CmdletBinding()]
    Param
    (
    [Parameter(Mandatory=$true)][String]$EndPoint,
    [Parameter(Mandatory=$true)][String]$DataBaseId,
    [Parameter(Mandatory=$true)][String]$CollectionId,
    [Parameter(Mandatory=$true)][String]$MasterKey,
    [Parameter(Mandatory=$true)][String]$DocumentID
    )

    $Verb = "GET"
    $ResourceLink = "dbs/$DataBaseId/colls/$CollectionId/docs/$DocumentID"
    $dateTime = [DateTime]::UtcNow.ToString("r")
    $authHeader = Generate-MasterKeyAuthorizationSignature -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
    $header = @{authorization=$authHeader;"x-ms-version"="2017-02-22";"x-ms-date"=$dateTime}
    $queryUri = "$EndPoint$ResourceLink"
    try
    {
        $result = Invoke-RestMethod -Method $Verb -ContentType "application/json" -Uri $queryUri -Headers $header -ErrorAction Ignore
    }
    catch
    {
        $result = $null
        
    }
    return $result
}

Function Remove-CosmosDocument
{
    [CmdletBinding()]
    Param
    (
    [Parameter(Mandatory=$true)][String]$EndPoint,
    [Parameter(Mandatory=$true)][String]$DataBaseId,
    [Parameter(Mandatory=$true)][String]$CollectionId,
    [Parameter(Mandatory=$true)][String]$MasterKey,
    [Parameter(Mandatory=$true)][String]$DocumentID
    )

    $Verb = "DELETE"
    $ResourceLink = "dbs/$DataBaseId/colls/$CollectionId/docs/$DocumentID"
    $dateTime = [DateTime]::UtcNow.ToString("r")
    $authHeader = Generate-MasterKeyAuthorizationSignature -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
    $header = @{authorization=$authHeader;"x-ms-version"="2017-02-22";"x-ms-date"=$dateTime}
    $queryUri = "$EndPoint$ResourceLink"
    try
    {
        $result = Invoke-RestMethod -Method $Verb -ContentType "application/json" -Uri $queryUri -Headers $header -ErrorAction Ignore
    }
    catch
    {
        $result = $null
        
    }
    return $result
}

# fill the target cosmos database endpoint uri, database id, collection id and masterkey
$CosmosDBEndPoint = "https://youraccountname.documents.azure.com:443/"
$DatabaseId = "DatabaseName"
$CollectionId = "CollectionName"
$MasterKey = "xx Your read/write key xxx"

$bios = Get-WmiObject Win32_Bios
$model = Get-WmiObject Win32_Computersystem

$jsonRequest = @{
    id= "$($bios.SerialNumber)"
    model = "$($model.Model)"
    biosversion = "$($bios.SMBIOSBIOSVersion)"
}

$json = $jsonRequest | ConvertTo-Json

if( (Get-CosmosDocument -EndPoint $CosmosDBEndPoint -DataBaseId $DatabaseId -CollectionId $CollectionId -MasterKey $MasterKey -DocumentID $bios.SerialNumber) -eq $null )
{
    New-CosmosDocument -EndPoint $CosmosDBEndPoint -DataBaseId $DatabaseId -CollectionId $CollectionId -MasterKey $MasterKey -JSON $JSON
}
else
{
    Set-CosmosDocument -EndPoint $CosmosDBEndPoint -DataBaseId $DatabaseId -CollectionId $CollectionId -MasterKey $MasterKey -JSON $JSON -DocumentID $bios.SerialNumber
}

# execute
# query string
#$Query = "SELECT * FROM Root where Root.id='2'"
$Query = "SELECT * FROM Root"
Query-CosmosDb -EndPoint $CosmosDBEndPoint -DataBaseId $DataBaseId -CollectionId $CollectionId -MasterKey $MasterKey -Query $Query

Remove-CosmosDocument -EndPoint $CosmosDBEndPoint -DataBaseId $DatabaseId -CollectionId $CollectionId -MasterKey $MasterKey -DocumentID 1