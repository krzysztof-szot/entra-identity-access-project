# Offline fixtures only: every Azure/network command used by the runbook is stubbed.
# No Azure authentication, token request or network operation is executed.
# From the repository root, use a separate PowerShell 7.4+ process:
# pwsh -NoProfile -File ./tests/offline/key-vault-read.Tests.ps1
# Do not dot-source this harness into an interactive Azure session.
$ErrorActionPreference = 'Stop'
$target = Join-Path $PSScriptRoot '../../scripts/day-13/rb-bfl-keyvault-read.ps1'
$tokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($target, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }

function Import-Module {
    [CmdletBinding()] param([string]$Name)
    if ($Name -ne 'Az.Accounts') { throw 'Unexpected import' }
}
function Disable-AzContextAutosave {
    param([string]$Scope)
    if ($Scope -ne 'Process') { throw 'Unexpected scope' }
}
function Connect-AzAccount {
    param([switch]$Identity, [string]$Scope, [switch]$SkipContextPopulation)
    if (!$Identity -or !$SkipContextPopulation -or $Scope -ne 'Process') { throw 'Unexpected auth mode' }
    [pscustomobject]@{ Context = [pscustomobject]@{ TestContext = 'offline' } }
}
function Get-AzAccessToken {
    param([string]$ResourceUrl, $DefaultProfile, [switch]$AsSecureString)
    if ($ResourceUrl -ne 'https://vault.azure.net' -or $DefaultProfile.TestContext -ne 'offline' -or !$AsSecureString) { throw 'Unexpected token context or output mode' }
    $value = if ($global:kvMockFixture.Legacy) { 'TOKEN_DO_NOT_PRINT' } else { ConvertTo-SecureString 'TOKEN_DO_NOT_PRINT' -AsPlainText -Force }
    [pscustomobject]@{ Token = $value }
}
function Invoke-WebRequest {
    [CmdletBinding()] param([string]$Uri, [string]$Method, [string]$Authentication, $Token, [switch]$SkipHttpErrorCheck, [int]$TimeoutSec)
    if ($Uri -ne 'https://kv-bfl-identity-ks01.vault.azure.net/secrets/bfl-kv-proof?api-version=2025-07-01' -or $Method -ne 'Get') { throw 'Unexpected target or operation' }
    if ($Authentication -ne 'Bearer' -or $Token -isnot [Security.SecureString] -or !$SkipHttpErrorCheck) { throw 'Unexpected HTTP options' }
    if ($global:kvMockFixture.NetworkFailure) { throw 'Offline transport failure fixture' }
    [pscustomobject]@{ StatusCode = $global:kvMockFixture.Status; Content = $global:kvMockFixture.Body }
}
$rbac = '{"error":{"code":"Forbidden","innererror":{"code":"ForbiddenByRbac"}}}'
$secret = '{"value":"SECRET_DO_NOT_PRINT"}'
$cases = @(
    @{ Name='RBAC denial'; Status=403; Body=$rbac; Expected='Denied'; Success=$true; Marker='EXPECTED_RBAC_DENIAL' },
    @{ Name='Allowed read'; Status=200; Body=$secret; Expected='Allowed'; Success=$true; Marker='EXPECTED_READ_ALLOWED' },
    @{ Name='Legacy token'; Status=200; Body=$secret; Expected='Allowed'; Success=$true; Legacy=$true; Marker='EXPECTED_READ_ALLOWED' },
    @{ Name='Unexpected access'; Status=200; Body=$secret; Expected='Denied'; Success=$false },
    @{ Name='Unexpected RBAC denial'; Status=403; Body=$rbac; Expected='Allowed'; Success=$false },
    @{ Name='Firewall denial'; Status=403; Body='{"error":{"code":"Forbidden","innererror":{"code":"ForbiddenByFirewall"}}}'; Expected='Denied'; Success=$false },
    @{ Name='Unclassified forbidden'; Status=403; Body='{"error":{"code":"Forbidden"}}'; Expected='Denied'; Success=$false },
    @{ Name='Wrong outer error'; Status=403; Body='{"error":{"code":"Other","innererror":{"code":"ForbiddenByRbac"}}}'; Expected='Denied'; Success=$false },
    @{ Name='Unauthorized'; Status=401; Body='{"error":{"code":"Unauthorized"}}'; Expected='Denied'; Success=$false },
    @{ Name='Missing secret'; Status=404; Body='{"error":{"code":"SecretNotFound"}}'; Expected='Denied'; Success=$false },
    @{ Name='Throttling'; Status=429; Body='{"error":{"code":"Throttled"}}'; Expected='Denied'; Success=$false },
    @{ Name='Malformed JSON'; Status=200; Body='{"value":"SECRET_DO_NOT_PRINT"'; Expected='Allowed'; Success=$false },
    @{ Name='Empty secret'; Status=200; Body='{"value":""}'; Expected='Allowed'; Success=$false },
    @{ Name='Missing value'; Status=200; Body='{}'; Expected='Allowed'; Success=$false },
    @{ Name='Wrong JSON shape'; Status=200; Body='["SECRET_DO_NOT_PRINT"]'; Expected='Allowed'; Success=$false },
    @{ Name='Transport failure'; Expected='Denied'; NetworkFailure=$true; Success=$false }
)
foreach ($case in $cases) {
    $global:kvMockFixture = $case
    $captured = [System.Collections.Generic.List[string]]::new()
    $failed = $false
    try {
        & $target -ExpectedResult $case.Expected 2>&1 | ForEach-Object { $captured.Add($_.ToString()) }
    } catch {
        $failed = $true
        $captured.Add($_.Exception.Message)
    }
    $log = $captured -join "`n"
    if ($log -match 'SECRET_DO_NOT_PRINT|TOKEN_DO_NOT_PRINT') { throw "Disclosure in $($case.Name)" }
    if ($failed -eq [bool]$case.Success) { throw "Wrong outcome for $($case.Name): $log" }
    if ($case.Success -and $log -notmatch [regex]::Escape($case.Marker)) { throw "Missing result marker for $($case.Name): $log" }
    if (!$case.Success -and $log -match 'RESULT: EXPECTED_') { throw "False success in $($case.Name)" }
    Write-Output "OFFLINE CHECK OK: $($case.Name)"
}
Write-Output "Syntax valid; $($cases.Count) offline cases passed. No Azure or network operations executed."
