#Requires -Version 7.4
param(
    [ValidateSet('Denied', 'Allowed')]
    [string]$ExpectedResult = 'Denied'
)

$ErrorActionPreference = 'Stop'
$vaultName = 'kv-bfl-identity-ks01'
$secretName = 'bfl-kv-proof'

Import-Module Az.Accounts -ErrorAction Stop
Disable-AzContextAutosave -Scope Process | Out-Null
$context = (Connect-AzAccount -Identity -Scope Process -SkipContextPopulation).Context
if ($null -eq $context) { throw 'AUTHENTICATION_FAILED: no Managed Identity context.' }

$accessToken = Get-AzAccessToken -ResourceUrl 'https://vault.azure.net' -DefaultProfile $context -AsSecureString
$bearer = $accessToken.Token
if ($bearer -is [string]) {
    $bearer = ConvertTo-SecureString -String $bearer -AsPlainText -Force
}
if ($bearer -isnot [System.Security.SecureString] -or $bearer.Length -eq 0) {
    throw 'AUTHENTICATION_FAILED: no usable token.'
}

Write-Output "UTC: $([DateTime]::UtcNow.ToString('o'))"
Write-Output 'AUTHENTICATION: Managed Identity token acquired'
Write-Output "TARGET: $vaultName / $secretName"
Write-Output "EXPECTED: $ExpectedResult"

$request = @{
    Uri = "https://$vaultName.vault.azure.net/secrets/${secretName}?api-version=2025-07-01"
    Method = 'Get'
    Authentication = 'Bearer'
    Token = $bearer
    SkipHttpErrorCheck = $true
    TimeoutSec = 60
    ErrorAction = 'Stop'
}
try {
    $response = Invoke-WebRequest @request
} catch {
    throw "REQUEST_FAILED: $($_.Exception.GetType().Name). No Key Vault HTTP result was obtained."
}
$status = [int]$response.StatusCode
Write-Output "HTTP: $status"
try {
    $data = ConvertFrom-Json -InputObject $response.Content -AsHashtable -ErrorAction Stop
} catch {
    # A parsing exception can contain response fragments, including a secret value.
    throw 'UNEXPECTED_RESPONSE: response is not valid JSON; content withheld.'
}
if ($data -isnot [System.Collections.IDictionary]) {
    throw 'UNEXPECTED_RESPONSE: expected a JSON object; content withheld.'
}

if ($status -eq 200) {
    if ($data.value -isnot [string] -or $data.value.Length -eq 0) {
        throw 'UNEXPECTED_RESPONSE: no nonempty secret value was returned.'
    }
    Write-Output 'READ: ALLOWED (secret value withheld)'
    if ($ExpectedResult -ne 'Allowed') {
        throw 'UNEXPECTED_ACCESS: read succeeded while denial was expected. Review existing permissions.'
    }
    Write-Output 'RESULT: EXPECTED_READ_ALLOWED'
    return
}

$code = [string]$data.error.code
$innerCode = [string]$data.error.innererror.code
Write-Output "ERROR_CODE: $code"
Write-Output "INNER_ERROR: $innerCode"
if ($status -eq 403 -and $code -eq 'Forbidden' -and $innerCode -eq 'ForbiddenByRbac') {
    Write-Output 'READ: DENIED_BY_RBAC'
    if ($ExpectedResult -ne 'Denied') {
        throw 'UNEXPECTED_DENIAL: RBAC denied the read while access was expected.'
    }
    Write-Output 'RESULT: EXPECTED_RBAC_DENIAL'
    return
}
throw 'UNEXPECTED_RESPONSE: this result does not establish the expected RBAC outcome.'
