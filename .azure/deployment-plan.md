# Deployment Plan

Status: Deployed

## 1. Objective

Deploy the NSP-Demo environment to the user-selected Azure subscription and keep the public GitHub repository subscription-neutral.

## 2. Target context

- Location: eastus
- Resource group: NSP-Demo-RG
- Deployment scope: subscription
- IaC: Bicep
- Repository: https://github.com/mcancillo/NSP-Demo

## 3. Planned resources

Network Security Perimeter, NSP profile and associations, Azure Virtual Network Manager, VNet and subnets, Storage account, RBAC-enabled Key Vault, and Log Analytics workspace.

## 4. Deployment command

```powershell
az deployment sub create --location eastus --template-file infra\main.bicep --parameters infra\main.bicepparam
```

The subscription is supplied by the operator's active Azure CLI context, not committed to source control.

## 5. Validation

- Bicep syntax validation passed with `az bicep build --file infra\main.bicep`.
- Subscription-scope what-if completed successfully with `az deployment sub what-if`.
- Azure CLI context confirmed for the user-selected subscription and East US.
- No RBAC role assignments are declared; the template relies on the deploying identity and Key Vault RBAC authorization.

## 6. Deployment risks

This deployment creates billable Azure resources and applies network security controls. The resource group and resources can affect access to associated PaaS endpoints. Review what-if output before deployment.

## 7. Validation Proof

Validated 2026-10-12:

```text
az account set --subscription <selected-subscription>
az account show
az bicep build --file infra\main.bicep
az deployment sub what-if --location eastus --template-file infra\main.bicep --parameters infra\main.bicepparam
```

Result: Bicep build passed and what-if reported 16 resources to create with no failures.

## 8. Deployment Result

Deployment succeeded after correcting Azure naming and rule constraints. The deployed resource group contains the NSP perimeter, profile, enforced Storage and Key Vault associations, AVNM, VNet, Storage, Key Vault, and Log Analytics resources.
