# Day 13 — Evidence

This folder documents workload authentication with Microsoft Entra Managed Identities in Baltic Finance: Azure Automation accessing a private Azure Blob through Microsoft Entra ID, an initial access denial, least-privilege Azure RBAC, successful read access, a reported write denial, and a separate user-assigned identity test.

**Key Vault extension — 2026-10-07:** screenshots 18–21 add System-assigned identity configuration, successful secret reads in a Test pane and published job, and the vault-scoped role assignment. The earlier Key Vault denial is available only as an [owner-supplied transcript](key-vault-denied-transcript.md), not a screenshot. The image sequence follows capture order, not the order of RBAC changes.

## 01 — Storage Account deployment

![Storage Account deployment](01-storage-account-created.png)

**Shows:** The deployment of `bflmi13a7k29` in `rg-bfl-identity-lab` completed successfully.

**Why it matters:** Establishes the Storage resource used by the workload access tests.

## 02 — Proof Blob in the lab container

![Proof Blob in the lab container](02-private-blob-container.png)

**Shows:** The `identity-lab` container contains `bfl-identity-proof.txt`; the portal session uses an access key.

**Why it matters:** Identifies the test object. This view does not demonstrate Managed Identity authentication or expose the container's anonymous-access setting.

## 03 — Automation Account deployment

![Automation Account deployment](03-automation-account-created.png)

**Shows:** The deployment of `aa-bfl-identity-lab` completed successfully.

**Why it matters:** Establishes the Azure Automation host for the Managed Identity Runbooks.

## 04 — System-assigned identity enabled

![System-assigned identity enabled](04-system-assigned-managed-identity.png)

**Shows:** The System-assigned identity for `aa-bfl-identity-lab` is On; its principal ID is masked.

**Why it matters:** Records the workload identity configuration before the authentication and authorization tests.

## 05 — Managed Identity service principal

![Managed Identity service principal](05-managed-identity-service-principal.png)

**Shows:** Microsoft Entra Enterprise Applications lists `aa-bfl-identity-lab`.

**Why it matters:** Shows the Automation identity's Entra representation; masked IDs prevent independent object-ID correlation.

## 06 — Blob read denied before data RBAC

![Blob read denied before data RBAC](06-managed-identity-rbac-denied.png)

**Shows:** The Runbook test reports successful Managed Identity authentication followed by HTTP `403` / `AuthorizationPermissionMismatch` on Blob access.

**Why it matters:** Distinguishes authentication from data authorization in the documented pre-assignment test. The screenshot does not show the earlier RBAC inventory.

## 07 — Storage Blob Data Reader assignment

![Storage Blob Data Reader assignment](07-managed-identity-storage-rbac.png)

**Shows:** Storage IAM lists `aa-bfl-identity-lab` with `Storage Blob Data Reader` at `This resource` on the test Storage Account.

**Why it matters:** Records the scoped data-plane role used for the subsequent read test.

## 08 — Successful System-assigned Blob read

![Successful System-assigned Blob read](08-managed-identity-blob-access-success.png)

**Shows:** The completed Runbook test reports successful authentication and Blob read, returning `BFL-MI-READ-SUCCESS`.

**Why it matters:** Provides runtime output after the reader assignment; the full executed Runbook source is not shown.

## 09 — Published PowerShell Runbook

![Published PowerShell Runbook](09-runbook-published.jpg)

**Shows:** `rb-bfl-managed-identity` has Published status and the `re-bfl-ps74` runtime environment.

**Why it matters:** Shows that the Runbook was published; publication alone does not prove a successful job.

## 10 — Completed published Runbook job

![Completed published Runbook job](10-published-runbook-job-success.png)

**Shows:** A separate job is Completed and its output reports a successful Blob read with `BFL-MI-READ-SUCCESS`.

**Why it matters:** Extends the read evidence beyond the Test pane to a published Runbook job.

## 11 — Role assignment in Azure Activity Log

![Role assignment in Azure Activity Log](11-storage-role-assignment-activity.png)

**Shows:** Azure Activity Log records `Create role assignment` with status Succeeded.

**Why it matters:** Records the permission change before the published job. The unopened event details do not identify the exact role or principal, and this is not a Blob-read log.

## 12 — User-assigned identity resource

![User-assigned identity resource](12-user-assigned-identity-created.png)

**Shows:** The standalone `mi-bfl-shared-reader` Managed Identity exists in the lab resource group.

**Why it matters:** Introduces the second workload identity, whose lifecycle is separate from the Automation Account.

## 13 — User-assigned identity attached to Automation

![User-assigned identity attached to Automation](13-user-assigned-identity-attached.png)

**Shows:** The Automation Account's User-assigned identity list contains `mi-bfl-shared-reader`.

**Why it matters:** Shows the identity is attached to the workload host; runtime selection is demonstrated separately.

## 14 — Successful User-assigned Blob read

![Successful User-assigned Blob read](14-user-assigned-identity-success.png)

**Shows:** The completed test names `mi-bfl-shared-reader` and reports successful authentication and Blob read with the proof marker.

**Why it matters:** Supports the recorded second-identity read scenario; the identity name is Runbook output rather than an exposed token claim.

## 15 — Reported write denial under the reader role

![Reported write denial under the reader role](15-managed-identity-write-denied.png)

**Shows:** The test output records an attempted upload, `EXPECTED WRITE DENIED` and `Least Privilege: PASS`.

**Why it matters:** Documents the handled negative-test result. Without the raw Storage error or exception-handling source, the screenshot does not independently establish the cause of the denial.

## 16 — Managed Identity sign-in records

![Managed Identity sign-in records](16-managed-identity-sign-in-log.png)

**Shows:** Both `aa-bfl-identity-lab` and `mi-bfl-shared-reader` have successful sign-ins to Azure Storage and Azure Resource Manager.

**Why it matters:** Corroborates workload authentication and token issuance; sign-in success does not authorize every Blob operation.

## 17 — Explicit User-assigned identity selection

![Explicit User-assigned identity selection](17-user-assigned-identity-code.png)

**Shows:** The PowerShell 7.4 Runbook fragment uses `Connect-AzAccount -Identity -AccountId $userAssignedClientId -ErrorAction Stop`.

**Why it matters:** Shows explicit selection of a User-assigned identity. The masked client ID and missing remainder of the Runbook limit source-level verification.

## 18 — System-assigned identity for Key Vault

![System-assigned identity enabled on aa-bfl-identity-lab](18-key-vault-system-assigned-identity.png)

**Shows:** The System-assigned identity of Automation Account `aa-bfl-identity-lab` is On; the principal ID is masked.

**Why it matters:** Records the enabled identity configuration for the Key Vault extension. The masked ID prevents independent Object ID correlation with the caller or role assignment.

## 19 — Successful Key Vault read in the Test pane

![Completed Key Vault read test with HTTP 200 and the secret value withheld](19-key-vault-read-allowed-test.png)

**Shows:** `rb-bfl-keyvault-read` is Completed in the Azure Test pane with `ExpectedResult: Allowed`. Output at `2026-10-07T06:41:01.6307592Z` names `kv-bfl-identity-ks01 / bfl-kv-proof`, reports Managed Identity token acquisition, HTTP `200` and `EXPECTED_READ_ALLOWED`; the secret value is withheld.

**Why it matters:** Captures the successful secret-read result. The visible `Get-AzAccessToken` breaking-change warning did not prevent that result; it does not identify the loaded module version or prove the absence of `-AsSecureString` in the executed code.

## 20 — Completed published Key Vault Runbook job

![Completed Azure Runbook job reporting a successful Key Vault read](20-key-vault-read-allowed-job.png)

**Shows:** A separate `rb-bfl-keyvault-read` job is Completed and Ran on Azure. Output at `2026-10-07T06:51:05.5666305Z` reports the same vault and secret, `Expected: Allowed`, HTTP `200` and `EXPECTED_READ_ALLOWED`, with the secret value withheld.

**Why it matters:** Extends the read evidence beyond the Test pane to a separate published job. `Ran As: User` is job metadata, not the Key Vault authentication identity. The source snapshot is not opened, and this Output view does not establish an empty Warnings stream.

## 21 — Key Vault Secrets User at vault scope

![Managed Identity assigned Key Vault Secrets User on kv-bfl-identity-ks01](21-key-vault-secrets-user-role.png)

**Shows:** IAM for `kv-bfl-identity-ks01`, filtered by `aa-bfl-identity-lab`, lists the Managed Identity with `Key Vault Secrets User` at `This resource`. The identifier is masked. A separate banner reports two users with elevated access in the tenant.

**Why it matters:** Documents the vault-scoped secret-reading role used by the lab. This filtered view is not a complete effective-access review or the role-grant timestamp. The banner's users, assignments and remediation are not shown and remain a separate unresolved observation.

**Key Vault evidence boundary:** the [denial transcript](key-vault-denied-transcript.md) is owner-reported and remains Partial; no negative-test screenshot is available. The [reference Runbook](../../scripts/day-13/rb-bfl-keyvault-read.ps1) is not an exported source snapshot of the captured job. No Key Vault write-denial, certificate, User-assigned identity or data-plane audit-log test is established by these read results.

Sensitive credentials, identifiers and tenant-specific values were redacted before publication.
