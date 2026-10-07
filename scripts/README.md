# Microsoft Graph PowerShell Scripts

These six scripts implement the Day 17 lab. They use delegated authentication and contain intentional checks for the original Baltic Finance accounts. They are not a general tenant deployment package.

## Prerequisites

- PowerShell 7 and the Microsoft Graph v1.0 PowerShell SDK. The lab evidence records PowerShell 7.6.6 and Microsoft.Graph.Authentication 2.40.0; those are observed versions, not a tested minimum-version guarantee.
- Access to the intended lab tenant and consent for the requested delegated Graph scopes.
- An operator with the Entra role permissions needed for each operation. Graph consent and the operator's Entra role are separate requirements.

Run this in PowerShell 7 to install the SDK if required:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery
Get-InstalledModule Microsoft.Graph
Get-Command Connect-MgGraph, Get-MgUser, Get-MgGroup
```

The full SDK includes the submodules used by these scripts. See [Microsoft's installation guide](https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation).

## Connection Modes

| Mode | Requested scopes | Purpose |
| --- | --- | --- |
| `Read` | `User.Read.All`, `Group.Read.All`, `Application.Read.All`, `RoleManagement.Read.Directory`, `Policy.Read.All` | Inventory and role-assignment dry run |
| `IdentityWrite` | `User.ReadWrite.All`, `User.Read.All`, `Group.ReadWrite.All`, `GroupMember.ReadWrite.All`, `Group.Read.All` | Lab user, group and membership provisioning |
| `RoleWrite` | `User.Read.All`, `RoleManagement.ReadWrite.Directory` | Explicit direct directory-role assignment |

The mode selects requested scopes. It does not guarantee that the resulting context contains only those scopes. Inspect `Get-MgContext`; the original Read-mode capture included additional grants.

For every example below, start in the repository root. Supply the tenant GUID when prompted. Complete the sign-in with the named operator and check the printed account and tenant before proceeding. When changing operators, disconnect and use a fresh PowerShell session to avoid reusing the previous context.

## Read and Export

Sign in as the original `adm-lab` account:

```powershell
$labTenantId = Read-Host 'Enter the Baltic Finance tenant GUID'
./scripts/01-connect-graph.ps1 -TenantId $labTenantId -Mode Read
Get-MgContext | Select-Object Account, TenantId, AuthType, Scopes
./scripts/06-export-tenant-state.ps1
Disconnect-MgGraph
```

The export writes timestamped CSV summaries under `local-output/day-17/`, which is excluded by `.gitignore`. `Policy.Read.All` and an appropriate active Entra role are needed for the CA query. If CA access is denied, verify the role/PIM activation and reconnect; a requested scope alone does not grant the administrator's role permissions.

Review warnings as well as the completion message. Membership failures are caught per group, CA export can be skipped or fail, and non-user/unresolved principals can appear as placeholders. The result is a selected inventory, not a complete backup or effective-access report.

## Create the Lab User and Group

Sign in as `adm-lab`. User creation asks for a temporary password only when the target does not already exist.

```powershell
$labTenantId = Read-Host 'Enter the Baltic Finance tenant GUID'
$labOperatorUpn = 'graph.operator@steglitzer1outlook.onmicrosoft.com'
./scripts/01-connect-graph.ps1 -TenantId $labTenantId -Mode IdentityWrite
./scripts/02-create-user.ps1 -UserPrincipalName $labOperatorUpn
./scripts/03-create-group.ps1
./scripts/04-group-membership.ps1 -UserPrincipalName $labOperatorUpn
Disconnect-MgGraph
```

The group is `SG-Graph-Automation-Lab`. Reruns check for existing objects or membership. An existing user/group is not automatically reconciled to every expected attribute.

## Privileged Role Test

`05-role-assignment.ps1` targets only `graph.operator` and the tenant-wide `Conditional Access Administrator` role. Its default invocation performs reads and prints the proposed operation:

```powershell
$labTenantId = Read-Host 'Enter the Baltic Finance tenant GUID'
$labOperatorUpn = 'graph.operator@steglitzer1outlook.onmicrosoft.com'
./scripts/01-connect-graph.ps1 -TenantId $labTenantId -Mode Read
./scripts/05-role-assignment.ps1 -TargetUpn $labOperatorUpn
Disconnect-MgGraph
```

The original negative test returned `403 Forbidden` for `adm-lab`. To deliberately repeat the authorized write, start a fresh session as the privileged operator `roleops-lab` with an appropriate active role:

```powershell
$labTenantId = Read-Host 'Enter the Baltic Finance tenant GUID'
$labOperatorUpn = 'graph.operator@steglitzer1outlook.onmicrosoft.com'
./scripts/01-connect-graph.ps1 -TenantId $labTenantId -Mode RoleWrite
./scripts/05-role-assignment.ps1 -TargetUpn $labOperatorUpn -Execute
Disconnect-MgGraph
```

The script additionally requires typing `ASSIGN`. This creates a direct Active assignment with no automatic one-hour expiry. After a deliberate retest, remove that specific test assignment using the authorized operator, verify the Active list and retain the removal audit. Day 18 already documents cleanup of the original run; running the write again changes that final state.

## Reuse in Another Lab

Scripts 02, 03, 04 and 06 check the original `adm-lab` UPN; scripts 02, 04 and 05 also restrict the target UPN. Review and replace these identity checks together with the tenant configuration in a separate lab copy. Preserve the guards, duplicate checks and privileged-write confirmation. No password, secret or token should be added to source.

The six scripts were retained unchanged by the documentation review. These instructions were checked against their parameters and guards; the review did not execute Graph writes or create a new tenant test result.

See [Day 17 implementation](../docs/day-17.md), [test history](../tests/day-17.md) and [Day 18 closure](../docs/day-18.md).

## Day 13 — Read-only Key Vault Runbook

[rb-bfl-keyvault-read.ps1](day-13/rb-bfl-keyvault-read.ps1) is the maintained lab source for the Key Vault read scenario. It performs one secret GET, withholds the token and secret value, and distinguishes RBAC denial from other HTTP or transport failures. An exact source export from the historical published job is unavailable; this repository copy does not establish byte-for-byte identity with that job.

Runbook requirements:

- Azure Automation PowerShell **7.4** runtime with **Az.Accounts** available.
- Automation account `aa-bfl-identity-lab` with its system-assigned Managed Identity enabled.
- Vault `kv-bfl-identity-ks01`, secret `bfl-kv-proof`, and network access to the vault endpoint.
- For the allowed-read scenario, **Key Vault Secrets User** assigned to that identity at **vault scope** under the vault's Azure RBAC permission model.

The parameter defaults to `ExpectedResult = Denied`. The published allowed-read scenario already has the role grant, so set **ExpectedResult to Allowed** when rerunning that job. The runbook does not create secrets or change role assignments; an unexpected result fails the job.

The source requests `Get-AzAccessToken -AsSecureString`. A historical breaking-change warning is not proof that the switch was missing: the [Az.Accounts 4.0.1 changelog](https://github.com/Azure/azure-powershell/blob/main/src/Accounts/Accounts/ChangeLog.md#version-401) records a fix for warnings appearing despite its use.

Run the [16 offline fixture checks](../tests/offline/key-vault-read.Tests.ps1) locally in a separate PowerShell 7.4+ process:

```powershell
pwsh -NoProfile -File ./tests/offline/key-vault-read.Tests.ps1
```

The harness parses the repository runbook and stubs every Azure/network command. Passing it validates local response handling and output redaction, not a new Azure job or RBAC result. See [Day 13 documentation](../docs/day-13.md) and [evidence](../evidence/day-13/README.md).
