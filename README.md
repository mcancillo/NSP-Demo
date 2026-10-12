# NSP-Demo

An Azure-native demo for **Network Security Perimeter (NSP)** and **Azure Virtual Network Manager (AVNM)**.

## What this deploys

- A dedicated `NSP-Demo-RG` resource group in East US.
- A small VNet and two subnets.
- AVNM with a static network group and a security-admin rule denying inbound TCP/3389.
- An NSP with a profile, outbound allow rules for monitoring, and enforced associations for Storage and Key Vault.
- A StorageV2 account, RBAC-enabled Key Vault, and 30-day Log Analytics workspace.

Names follow the `NSP-demo-<service-or-function>` convention where Azure naming constraints permit it. Globally unique names such as Storage and Key Vault use a deterministic suffix.

## Prerequisites

1. Azure CLI with the Bicep extension.
2. Access to subscription `6cbb5372-2516-4048-b672-a3e0a36fac8b`.
3. Registered providers for `Microsoft.Network`, `Microsoft.Storage`, `Microsoft.KeyVault`, and `Microsoft.OperationalInsights`.
4. Confirm that NSP and its supported resource associations are available in `eastus` for the subscription.

## Validate and deploy

```powershell
az account set --subscription 6cbb5372-2516-4048-b672-a3e0a36fac8b
az bicep build --file infra/main.bicep
az deployment sub what-if `
  --location eastus `
  --template-file infra/main.bicep `
  --parameters infra/main.bicepparam
az deployment sub create `
  --location eastus `
  --template-file infra/main.bicep `
  --parameters infra/main.bicepparam
```

Deployment is intentionally not run by this package. Review the what-if output and verify current NSP/AVNM feature availability first.

## Lab

See [docs/hackathon.md](docs/hackathon.md) for the Build, Operate, and Security challenge tracks.

## References

See [docs/references.md](docs/references.md) and [docs/architecture.md](docs/architecture.md).
