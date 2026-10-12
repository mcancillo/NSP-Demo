# NSP-Demo mini hackathon

## Event flow

Run the tracks in order. Track 4 is the capstone: it uses the environment built in Track 1, the evidence workflow from Track 2, and the threat model from Track 3.

| Track | Timebox | Outcome |
| --- | ---: | --- |
| Build | 30 min | Working NSP and AVNM baseline |
| Operate | 30 min | Repeatable evidence and rollback runbook |
| Security perspective | 20 min | Threat/control matrix |
| External PaaS exfiltration | 40 min | Proven Audit-to-Enforced network boundary |

## Track 1: Build

**Challenge:** deploy the baseline and prove the control plane is understandable.

1. Validate `infra/main.bicep` and inspect the subscription-scope what-if.
2. Deploy to `NSP-Demo-RG`.
3. Locate the NSP profile and its two resource associations.
4. Locate the AVNM network group, static VNet member, and security-admin rule.
5. Record the generated Storage and Key Vault names.

**Deliverable:** a one-page diagram and a short table mapping each resource to its security responsibility.

## Track 2: Operate

**Challenge:** operate the environment as a small platform team.

1. Query Activity Log for resource association and policy changes.
2. Capture a baseline Storage and Key Vault request from an allowed client.
3. Change one association from `Enforced` to `Audit` in a controlled branch or parameterized variant.
4. Re-run the request and compare observed behavior.
5. Explain how AVNM deployment status differs from NSP association state.
6. Add diagnostic settings to the Log Analytics workspace if the target service and subscription support them.

**Deliverable:** an incident runbook covering validation, evidence collection, rollback, and cleanup.

## Track 3: Security perspective

**Challenge:** explain what NSP mitigates and what it does not.

### NSP helps mitigate

- Accidental public exposure of supported PaaS resources.
- Unintended network paths from outside approved perimeter rules.
- Drift in resource-level public network access posture.
- Ambiguous ownership of which PaaS resources share a network security boundary.

### NSP does not replace

- Entra ID authentication or RBAC authorization.
- Key Vault secret permissions and separation of duties.
- Encryption at rest or TLS configuration.
- Application-layer authorization and input validation.
- AVNM/NSG/firewall controls for VNet traffic.
- DDoS protection, endpoint detection, or a complete SOC process.

**Deliverable:** a threat/control matrix with at least five threats, the control that helps, residual risk, and an evidence source.

## Track 4: External PaaS exfiltration

Run [the external PaaS exfiltration exercise](external-paas-exfiltration.md) as the capstone. Use a disposable Function App outside the perimeter as the client, a short-lived write-only SAS, and correlated NSP/Storage/Log Analytics evidence. Demonstrate the same request in Audit and Enforced modes and explain why a valid SAS is not sufficient to cross the enforced perimeter.

### Capstone handoff

Each team must hand the next team:

1. The target Storage account and test-container name.
2. The probe invocation timestamp and request ID.
3. The NSP association mode used for each run.
4. The Log Analytics query or portal screenshots used as evidence.
5. A statement of whether the blob was created.

The receiving team must reproduce the enforced run without changing the probe code or SAS permissions.

### Scoring

- 25%: baseline deployed and architecture explained.
- 25%: operational evidence is reproducible and includes cleanup.
- 20%: threat/control matrix distinguishes NSP from RBAC, encryption, and DLP.
- 30%: capstone proves the same external PaaS request succeeds in the baseline and is blocked in Enforced mode, with correlated logs and no test blob after enforcement.

## Stretch goals

- Add a second profile with a narrower outbound FQDN rule.
- Add a second VNet and use AVNM connectivity configuration to show centralized topology management.
- Compare NSP Audit, Learning, and Enforced modes using the same test matrix.
- Add policy-as-code checks for required tags and public network access settings.
