# Access Matrix

This matrix summarizes the Baltic Finance Lab through Day 18, with the dated 2026-10-07 Key Vault extension below. Each row names its evidence point: an earlier lab record is not a fresh inventory of every current permission. Day 18 confirms selected final states, including PIM eligibility, emergency CA exclusions, revoked external access and workload RBAC.

## Workforce and External Identities

| Identity | Documented purpose or department | Access and lifecycle evidence |
| --- | --- | --- |
| `anna.finance` | Finance; business reviewer and app test user | `Expense.Submitter`; delegated Graph `User.Read` profile visible in Day 18 |
| `peter.finance` | Finance; app approver and negative-test user | Day 02/12 sessions show `Expense.Submitter` and `Expense.Approver`; later negative tests have scenario-specific conditions |
| `eva.hr` | HR | Day 01 workforce baseline; no final application entitlement asserted |
| `thomas.it` | IT | Day 01 workforce and CA-pilot baseline |
| `jan.mover` | **IT after Day 06** | Finance access removed, `SG-IT-Users` added, fresh Expense Portal sign-in denied |
| `alexandra.leaver` | Former Finance employee | Day 06 account disabled, memberships and assignments removed, fresh sign-in blocked |
| `Marc Joiner` | Finance | Day 06 `SG-Finance-Users` membership and Expense Portal access |
| `Hybrid Finance` | Synchronized AD DS identity | Days 07–08 PHS authentication, app access and device-state tests |
| `graph.operator` | IT automation test account | Day 17 provisioning; temporary CA Administrator role removed and audited in Day 18 |
| `External Auditor` | Amber Audit Partners B2B Guest | Day 18 contractor group empty; package assignment Expired/Governed; fresh Expense Portal access denied with `AADSTS50105` |

Workforce identities are Member accounts. The partner auditor is a Guest in Baltic Finance. A retained Guest object or a `Governed` label does not by itself grant application access.

Sources: [Day 01](day-01.md), [Day 06](day-06.md), [Day 12](day-12.md), [Day 18](day-18.md).

## Administrative Access

| Identity | Role or responsibility | Assignment state / evidence point |
| --- | --- | --- |
| `adm-lab` | User Administrator | Delegated identity administration established in Day 01 |
| `adm-lab` | Reports Reader | Log-reading role added in Day 03 |
| `adm-lab` | Conditional Access Administrator | **Permanent Eligible** in Day 18; no Active assignment at capture; activation requires MFA, justification, separate approval and a maximum of one hour |
| `adm-finance` | User Administrator | Scoped to `AU-Finance` in Day 06; in-scope success and out-of-scope denial demonstrated |
| `appops-lab` | Cloud Application Administrator | Application-administration identity from the baseline model; not independently re-inventoried in Day 18 |
| `roleops-lab` | Privileged Role Administrator | Privileged operator in the baseline model; authorized direct role assignment demonstrated in Day 17 |
| `pim-approver` | PIM approval responsibility | Separate approver in Days 09/18; approval responsibility is not itself a directory role assignment |
| `bg01`, `bg02` | Global Administrator | **Permanent Active**, intentionally retained for emergency access and shown in Day 18 |
| Tenant bootstrap account | Initial tenant setup | Historical bootstrap identity; it is not shown in the Day 18 Global Administrator Active list, so this matrix does not assert a current GA assignment |

Permanent Eligible and Permanent Active are different states. The Day 17 direct role grant to `graph.operator` was not a PIM activation; its removal is independently confirmed by the [Day 18 audit](../evidence/day-18/05-privilege-remediation.png).

## Groups and Application Entitlements

| Group | Purpose / resource | Last documented membership or scope |
| --- | --- | --- |
| `SG-App-Expense-Users` | Expense Portal → `Expense.Submitter` | Day 02 baseline application access group |
| `SG-App-Expense-Approvers` | Expense Portal → `Expense.Approver` | Peter's approval role demonstrated in Days 02/12 |
| `SG-Dept-Finance`, `SG-Dept-HR`, `SG-Dept-IT` | Department groups from Day 01 | Historical baseline; the later lifecycle lab uses separate groups below |
| `SG-Finance-Users` | Day 06 Finance access → `Expense.Submitter` | Marc Joiner receives access; Jan Mover and Alexandra Leaver lose Finance access |
| `SG-IT-Users` | Day 06 destination group | Jan Mover added after transfer to IT |
| `SG-Hybrid-Finance` | AD DS hybrid identity group | Hybrid Finance membership shown in Day 07 screenshot 02 |
| `SG-CA-Pilot` | Initial CA rollout | Anna and Thomas in the Day 01 baseline |
| `SG-Auth-Hardening-Pilot` | CA003 and SSPR pilot | Authentication-strength testing and SSPR configuration in Day 04 |
| `SG-Passwordless-Pilot` | Passkey registration rollout | Day 04 registration campaign target |
| `SG-Emergency-Access` | Emergency-account CA exclusions | Both emergency accounts resolve to effective exclusions across ten reviewed policies in Day 18 |
| `SG-External-Contractors` | B2B Expense Portal access → `Expense.Submitter` | **Zero direct members in Day 18**, after package revocation and Access Review scenarios |
| `SG-APP-InternalPortal` | Application Proxy access | Day 14 assigned pilot; Anna allowed, Peter unassigned and denied |
| `SG-APP-Provisioning-Pilot` | SCIM application provisioning scope | Day 14 scoped update and deprovisioning tests |
| `SG-GSA-Pilot` | GSA and MDCA session-control pilot | Anna is the sole direct member in the Day 15 capture |
| `SG-Graph-Automation-Lab` | Graph provisioning and membership lab | `graph.operator` is a direct member in Day 17 |

The original group design used Security groups with Assigned membership and `Role assignable: No`. Day 18 does not independently recheck that property or group owners. Protection of `SG-Emergency-Access` membership against less-privileged administrators is an open [validation task](../tests/day-18.md#residual-findings--not-fully-assessed).

The Day 10 Access Package also delivered an application resource role directly alongside group membership. Group-based assignment is the baseline design, not a claim that every lab entitlement used only a group. The auditor's `Expense.Submitter` role was a lab simplification, not a production read-only audit role.

Sources: [Day 05](day-05.md), [Day 10](day-10.md), [Day 11](day-11.md), [Day 14](day-14.md), [Day 15](day-15.md), [Day 17](day-17.md).

## Conditional Access Inventory

The states below come from the final ten-policy review in [Day 18 screenshot 06](../evidence/day-18/06-break-glass-assessment.png). Scope and controls refer to the relevant lab's documented configuration; that summary output does not independently revalidate every policy setting.

| Policy | Documented scope / control | Final reviewed state |
| --- | --- | --- |
| `CA001-ExpensePortal-Require-MFA` | Expense Portal pilot; require MFA | On |
| `CA002-ExpensePortal-HighSignInRisk` | High-risk Expense Portal sign-ins; evaluate Block access | Report-only |
| `CA003-ExpensePortal-Phishing-resistant-MFA-Pilot` | Authentication-hardening pilot; phishing-resistant MFA | On |
| `CA008-Expense Portal - Block Non-Hybrid Devices` | Hybrid Finance / Expense Portal; block except `ServerAD` devices | On |
| `CA009-PIM-Validation` | Policy created to demonstrate privileged administration | Off |
| `CA010-Block-Legacy-Authentication` | Legacy-authentication policy name shown; detailed assignments and runtime block not published | On |
| `CA-External-Auditor-ToU` | Contractor group / Expense Portal; Terms of Use | On |
| `CA-BFL-InternalPortal-Require-MFA` | Internal Portal pilot / Application Proxy; MFA | On |
| `CA-GSA-Web-Filtering` | GSA pilot / Internet resources; security profile `SP-GSA-Web` | On |
| `CA-MDCA-Session-Control` | GSA pilot / SharePoint; custom Conditional Access App Control | On |

Both emergency accounts are effectively excluded through the emergency group in the final review. An On state alone is not evidence that a policy applied to every user or sign-in. CA001 and CA003 are corroborated by actual sign-in and KQL results in Day 18.

## Application and Workload Permissions

| Identity / application | Permission | Evidence and boundary |
| --- | --- | --- |
| Expense Portal | Microsoft Graph `User.Read`, Delegated, admin consent | Day 18 configured and granted permissions; business App Roles remain separate |
| Expense Portal | No Application `User.Read.All` grant shown | Temporary Day 12 app-only experiment removed; final consent reviewed in Day 18 |
| `aa-bfl-identity-lab` | `Storage Blob Data Reader` at Storage Account scope | Day 13 runtime read/deny tests; Day 18 IAM review |
| `mi-bfl-shared-reader` | `Storage Blob Data Reader` at Storage Account scope | Day 13 explicit user-assigned identity read; Day 18 IAM review |
| `aa-bfl-identity-lab` System-assigned MI | `Key Vault Secrets User` at `kv-bfl-identity-ks01` vault scope | 2026-10-07 [IAM assignment](../evidence/day-13/21-key-vault-secrets-user-role.png) and [completed secret-read job](../evidence/day-13/20-key-vault-read-allowed-job.png); masked IDs limit exact principal correlation; write denial and all effective permissions were not tested |

The Key Vault role belongs to the Automation identity and is available to runbooks using that identity; it is not restricted to one Runbook. The filtered IAM capture also reports two users with elevated tenant access, without identifying them. Their assignments require a separate review; this evidence does not establish remediation. No Key Vault role or test is claimed for `mi-bfl-shared-reader` or Expense Portal.

The zero-credential App Registration capture does not by itself validate the Easy Auth credential path or Graph token renewal. See the [Day 18 application assessment](day-18.md#application-permissions-and-easy-auth-credentials) for the later credential-reference evidence and remaining runtime checks. Deployed application source is still absent from this repository.
