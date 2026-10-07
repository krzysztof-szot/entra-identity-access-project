# Day 13 — Workload Identities and Managed Identity

**Day 18 follow-up:** the [final Storage IAM evidence](../evidence/day-18/22-workload-rbac.png) separately confirms `Storage Blob Data Reader` at Storage Account scope for both managed identities. The original Blob runtime tests below retain their Day 13 context; the later Key Vault extension is dated separately.

## Objectives

The goal of Day 13 was to authenticate an Azure workload to another Azure resource without storing a password, client secret, SAS token or Storage Account key in Runbook code.

The lab compared **System-assigned** and **User-assigned Managed Identities**, implemented Microsoft Entra authentication from Azure Automation to a private Azure Blob, and tested authorization boundaries with Azure RBAC. It extends Day 12's app-only authentication topic, but uses Azure-managed credentials and Storage data-plane RBAC rather than Microsoft Graph application permissions.

## Implemented

### Resources and workload

The lab reused `rg-bfl-identity-lab` in Baltic Finance and created:

| Resource | Name / purpose |
| --- | --- |
| Storage Account | `bflmi13a7k29` |
| Blob container | `identity-lab` |
| Proof blob | `bfl-identity-proof.txt` |
| Automation Account | `aa-bfl-identity-lab` |
| System-assigned Runbook | `rb-bfl-managed-identity` |
| User-assigned identity | `mi-bfl-shared-reader` |
| User-assigned Runbook | `rb-bfl-user-assigned` |
| Write-denial Runbook | `rb-bfl-mi-write-denied` |

The proof blob contained the marker `BFL-MI-READ-SUCCESS`. The Azure Portal container screenshot shows the **administrator's portal session using an access key** to browse the file; it is not evidence of the Runbook's authentication method.

### System-assigned identity and service principal

The Automation Account's System-assigned Managed Identity was enabled, and the corresponding `aa-bfl-identity-lab` service principal was located under Microsoft Entra Enterprise Applications. No separate conventional App Registration or manually managed application credential was required for this workload identity.

The main PowerShell Runbook used `Connect-AzAccount -Identity` and `New-AzStorageContext -UseConnectedAccount` for Microsoft Entra-authenticated Blob access. Its job output recorded successful authentication without a client secret or password in the Runbook code.

### Negative test before Storage data RBAC

Before granting the required data-plane role, the System-assigned Managed Identity authenticated but could not read the private Blob. The Runbook test failed with HTTP `403`, `AuthorizationPermissionMismatch`.

This distinguishes **authentication** (getting a token as the workload) from **authorization** (permission to perform a particular Blob operation).

### Least-privilege Azure RBAC and successful read

`Storage Blob Data Reader` was assigned to `aa-bfl-identity-lab` at the Storage Account scope. The Storage IAM view recorded the resulting role assignment, and Azure Activity Log showed a successful `Create role assignment` event.

With the role in place, the same Runbook completed authentication and Blob read successfully. It returned the proof marker `BFL-MI-READ-SUCCESS` and `DAY 13 RESULT: PASS`.

The Runbook was published using the `re-bfl-ps74` PowerShell 7.4 runtime. A separate completed job showed the published Runbook could also read the Blob; the Test pane was not the only successful execution.

### Negative write test

`rb-bfl-mi-write-denied` used the System-assigned identity to attempt an upload to `identity-lab`. The test output recorded:

```text
AUTHENTICATION: SUCCESS
EXPECTED WRITE DENIED
Authorization: FAILED AS EXPECTED
Least Privilege: PASS
DAY 13 WRITE TEST: PASS
```

The observed behavior is consistent with a read-only data role: the workload could read the Blob but could not upload a new one. The screenshot shows the controlled Runbook result; it does not separately expose the raw Storage HTTP error for this write attempt.

### User-assigned identity

The standalone `mi-bfl-shared-reader` identity was created and attached to `aa-bfl-identity-lab`. A separate Runbook selected that identity explicitly with:

```powershell
Connect-AzAccount -Identity -AccountId $userAssignedClientId
```

The User-assigned Runbook reported `mi-bfl-shared-reader`, successful authentication, a successful Blob read, and `DAY 13 RESULT: PASS`. Its success demonstrates that this second identity had effective read authorization; the evidence set does not include a separate screenshot of its role assignment.

### Monitoring

Microsoft Entra **Managed identity sign-ins** showed successful entries for both `aa-bfl-identity-lab` and `mi-bfl-shared-reader` targeting Azure Storage and Azure Resource Manager. These sign-ins demonstrate authentication/token issuance; the Runbook outputs provide the separate proof of allowed and denied Blob operations.

## Design Decisions

- Use Azure Automation instead of an additional VM to execute the workload.
- Keep System-assigned and User-assigned identities distinct, including explicit `-AccountId` selection for the latter.
- Authenticate to Storage with Microsoft Entra rather than keys, SAS tokens or manually stored secrets in the Runbook.
- Grant `Storage Blob Data Reader` at the test Storage Account scope instead of broad Contributor/Owner access.
- Record **deny → role assignment → successful read → denied write** to validate least privilege, not only successful connectivity.
- Retain a completed published Runbook job and Entra sign-in evidence in addition to Test pane outputs.

## Verification and Scope

The recorded evidence establishes successful passwordless-in-code workload authentication, a pre-RBAC read denial (`403`), successful read after Azure RBAC, denied write under the read-only role, a successful published Runbook job, User-assigned identity selection and successful sign-ins for both identities.

This day did **not** implement a Windows gMSA, test Microsoft Graph permissions for a Managed Identity, or demonstrate automatic infrastructure cleanup. No full access tokens or application credentials are published.

## Key Vault extension (2026-10-07)

This later extension reused `aa-bfl-identity-lab` to read a test secret from Azure Key Vault. It adds a separate resource authorization scenario without changing the historical Blob Storage results above or integrating Key Vault with Expense Portal.

| Component | Name / scope |
| --- | --- |
| Key Vault | `kv-bfl-identity-ks01` |
| Test secret | `bfl-kv-proof` |
| Automation Account / System-assigned identity | `aa-bfl-identity-lab` |
| Read Runbook | `rb-bfl-keyvault-read` |
| Observed data role | `Key Vault Secrets User` at the Key Vault resource scope |

### Identity and scoped permission

[Screenshot 18](../evidence/day-13/18-key-vault-system-assigned-identity.png) shows the Automation Account's System-assigned identity On. [Screenshot 21](../evidence/day-13/21-key-vault-secrets-user-role.png) shows the Managed Identity named `aa-bfl-identity-lab` with `Key Vault Secrets User`, scoped to `This resource` on `kv-bfl-identity-ks01`.

`Key Vault Secrets User` permits reading secret contents under the Azure RBAC permission model; it is distinct from the metadata-only `Key Vault Reader` role. The assignment is at the vault, not the resource group or subscription. See [Microsoft Learn — Key Vault RBAC](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide). The permission is available to Runbooks using that identity, not exclusively to this named Runbook.

The principal identifiers are masked, and IAM is filtered by name. The captures therefore do not independently correlate an exact caller Object ID or establish all effective permissions. The IAM banner also reports **two users with elevated access in the tenant**. Their identities, assignments and remediation are not shown; this remains a separate unresolved observation.

### Reported denial and captured successful reads

| Observation | UTC on 2026-10-07 | Evidence and boundary |
| --- | --- | --- |
| Read denied before the reported role grant | `06:28:56.0200272Z` | Owner-supplied transcript: HTTP `403`, `Forbidden`, `ForbiddenByRbac`, `EXPECTED_RBAC_DENIAL`. No screenshot or exported job record is available; this negative test remains Partial. |
| Read allowed in the Test pane | `06:41:01.6307592Z` | Screenshot 19: Completed, Azure, `ExpectedResult: Allowed`, HTTP `200`, `EXPECTED_READ_ALLOWED`; secret value withheld. |
| Read allowed in a separate published job | `06:51:05.5666305Z` | Screenshot 20: Completed, Ran on Azure, same vault and secret, HTTP `200`, `EXPECTED_READ_ALLOWED`. |

The [denial transcript](../evidence/day-13/key-vault-denied-transcript.md) preserves the result fields pasted by the owner. [Screenshot 19](../evidence/day-13/19-key-vault-read-allowed-test.png) and [screenshot 20](../evidence/day-13/20-key-vault-read-allowed-job.png) independently support the two captured successful outputs. Screenshot numbering follows capture order; the later IAM capture is not the timestamp of the role grant and does not independently establish the full deny → grant → allow timeline.

`Ran As: User` in the job view is job metadata, not evidence of the identity authenticating to Key Vault. The output reports Managed Identity token acquisition; no token or secret value is published.

### Reference Runbook and verification boundary

The [PowerShell 7.4 reference Runbook](../scripts/day-13/rb-bfl-keyvault-read.ps1) preserves the guided implementation with `ExpectedResult` values `Denied` and `Allowed`. It uses Managed Identity authentication, checks the Key Vault HTTP result and withholds token and secret contents. This is the repository reference source, **not an exported source snapshot of the captured Azure job**. Its local validation is not a tenant rerun.

Screenshot 19 includes a `Get-AzAccessToken` breaking-change warning. The [Az.Accounts 4.0.1 changelog](https://github.com/Azure/azure-powershell/blob/main/src/Accounts/Accounts/ChangeLog.md#version-401) records a fix for this warning when `-AsSecureString` is used; older module behavior is a possible explanation, not a verified diagnosis of this Runbook. The warning did not prevent the captured read. Screenshot 20 shows only Output, so it does not establish an empty Warnings stream.

The extension demonstrates the captured secret-read workflow and vault-scoped role assignment. It does **not** establish Key Vault write denial, certificate operations, User-assigned identity access to Key Vault, a Key Vault data-plane audit event, or the current network configuration. These are outside this basic extension, not additional passed tests.

## Evidence and Tests

- [Day 13 test results](../tests/day-13.md)
- [Day 13 evidence](../evidence/day-13/README.md)

Sensitive tenant, subscription and identity identifiers were redacted where appropriate.
