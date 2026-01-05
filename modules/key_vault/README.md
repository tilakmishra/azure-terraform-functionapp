# Key Vault Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Key Vault** with enterprise security configuration including RBAC authorization, private endpoint, VNet integration, soft delete, and purge protection. Perfect for storing secrets, keys, and certificates in production environments.

---

## ✅ Features

- **RBAC Authorization**: Azure AD role-based access (no access policies)
- **Private Endpoint**: Secure access via VNet
- **Public Access Disabled**: Zero-trust network security
- **Soft Delete**: 90-day retention for deleted secrets
- **Purge Protection**: Prevents permanent deletion
- **VNet Service Endpoints**: Subnet-level access control
- **Diagnostic Settings**: Integration with Log Analytics
- **Tagging Support**: Consistent resource organization

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Azure AD Tenant**: Tenant ID required
- **VNet with Subnets**: Private endpoint subnet required

---

## 📦 Resources Created

- `azurerm_key_vault`: Key Vault with RBAC and network security
- `azurerm_private_endpoint`: Private endpoint for VNet access
- `azurerm_monitor_diagnostic_setting`: Diagnostic logs (optional)

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `name` | Key Vault name (globally unique, 3-24 chars) | string | - | ✅ |
| `location` | Azure region | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `tenant_id` | Azure AD tenant ID | string | - | ✅ |
| `private_endpoint_subnet_id` | Subnet ID for private endpoint | string | - | ✅ |
| `allowed_subnet_ids` | Subnet IDs for service endpoint access | list(string) | `[]` | ❌ |
| `enable_diagnostics` | Enable diagnostic settings | bool | `false` | ❌ |
| `log_analytics_workspace_id` | Log Analytics workspace ID | string | `null` | ❌ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `key_vault_id` | Key Vault resource ID |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI (https://<name>.vault.azure.net/) |
| `private_endpoint_id` | Private endpoint resource ID |

---

## 🚀 Usage Example

```hcl
# Get current Azure AD tenant
data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "./modules/key_vault"

  name                = "kv-emp-dev-abc123"
  location            = "eastus2"
  resource_group_name = "rg-employee-app-dev"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  # Networking
  private_endpoint_subnet_id = module.virtualsubnet.subnet_ids["private_endpoints"]
  allowed_subnet_ids = [
    module.virtualsubnet.subnet_ids["function_app"]
  ]
  
  # Monitoring
  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.workspace_id
  
  tags = {
    Environment = "dev"
    Project     = "EmployeeManagement"
  }
}

# Grant Function App access to secrets
resource "azurerm_role_assignment" "function_app_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.function_app_principal_id
}

# Store a secret (requires your own Key Vault Secrets Officer role)
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = "cosmos-connection-string"
  value        = "sensitive-value"
  key_vault_id = module.key_vault.key_vault_id
}
```

---

## 📂 Module Structure

```
key_vault/
├── main.tf       # Key Vault and private endpoint resources
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔐 Security Features

✅ **RBAC Authorization**: `rbac_authorization_enabled = true` (no access policies)  
✅ **Public Access Disabled**: `public_network_access_enabled = false`  
✅ **Private Endpoint**: All access via VNet  
✅ **Soft Delete**: 90-day retention, `soft_delete_retention_days = 90`  
✅ **Purge Protection**: `purge_protection_enabled = true` (cannot be disabled once enabled)  
✅ **Network ACLs**: Default deny with subnet allowlist  
✅ **Azure Services Bypass**: Allows trusted Azure services

### RBAC Roles

| Role | Permissions | Use Case |
|------|-------------|----------|
| `Key Vault Secrets User` | Read secrets | Function App, App Service |
| `Key Vault Secrets Officer` | Manage secrets | Admins, CI/CD pipelines |
| `Key Vault Administrator` | Full control | Platform admins |
| `Key Vault Crypto User` | Encrypt/decrypt | Applications using keys |

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Verify Key Vault
az keyvault show \
  --name kv-emp-dev-abc123 \
  --resource-group rg-employee-app-dev

# Check network settings
az keyvault network-rule list \
  --name kv-emp-dev-abc123 \
  --resource-group rg-employee-app-dev

# Test secret access (requires RBAC role)
az keyvault secret show \
  --vault-name kv-emp-dev-abc123 \
  --name test-secret

# Verify RBAC assignments
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-employee-app-dev/providers/Microsoft.KeyVault/vaults/kv-emp-dev-abc123
```

---

## 🔧 Advanced Configuration

### Managed Identity Access from Function App

```python
# In your Python Function App code
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Automatically uses managed identity
credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://kv-emp-dev-abc123.vault.azure.net/", credential=credential)

# Retrieve secret
secret = client.get_secret("cosmos-connection-string")
print(secret.value)
```

### Certificate Storage

```hcl
# Store TLS certificate
resource "azurerm_key_vault_certificate" "ssl_cert" {
  name         = "ssl-certificate"
  key_vault_id = module.key_vault.key_vault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}
```

### Encryption Keys

```hcl
resource "azurerm_key_vault_key" "encryption_key" {
  name         = "data-encryption-key"
  key_vault_id = module.key_vault.key_vault_id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}
```

---

## 🐛 Troubleshooting

**Issue**: "Access denied" when accessing secrets  
**Solution**: Verify RBAC role assignment (Key Vault Secrets User role required)

```bash
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee <principal-id> \
  --scope <key-vault-id>
```

**Issue**: Cannot connect to Key Vault from Function App  
**Solution**: Check private endpoint DNS resolution

```bash
# From within VNet:
nslookup kv-emp-dev-abc123.vault.azure.net
# Should resolve to 10.0.3.x (private IP)
```

**Issue**: "Purge protection cannot be disabled"  
**Solution**: This is by design. Once enabled, purge protection is permanent. Plan Key Vault lifecycle carefully.

**Issue**: "Network not allowed"  
**Solution**: Add subnet to allowed_subnet_ids or access via private endpoint

**Issue**: Cannot delete Key Vault  
**Solution**: Soft delete is enabled. Use purge command:

```bash
az keyvault purge --name kv-emp-dev-abc123
# Only works if purge protection is disabled
```

---

## 💰 Cost

Key Vault pricing:
- **Standard tier**: $0.03 per 10,000 transactions
- **Premium tier**: $1.00 per key (HSM-backed)

**This module uses Standard tier** (defined in `sku_name = "standard"`)

**Monthly cost estimate**: $5-$10 for typical usage

---

## 📊 Monitoring

### Diagnostic Logs

When `enable_diagnostics = true`, the following logs are collected:

- `AuditEvent`: All Key Vault operations
- `AllMetrics`: Performance metrics

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| Total Service API Hits | Track baseline | Monitor for unusual spikes |
| Service API Result | Errors > 1% | Investigate failures |
| Service API Latency | > 1s | Check network/performance |
| Vault Availability | < 99.9% | Check health status |

### Kusto Query Example

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| where OperationName == "SecretGet"
| summarize count() by identity_claim_http_schemas_xmlsoap_org_ws_2005_05_identity_claims_upn_s, bin(TimeGenerated, 1h)
```

---

## 🔒 Compliance

This module implements security controls for:

✅ **HIPAA**: Encryption at rest, access controls, audit logging  
✅ **PCI DSS**: Key management, access logging  
✅ **SOC 2**: Access controls, monitoring, soft delete  
✅ **GDPR**: Data encryption, access controls

---

## 📘 References

- [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Terraform azurerm_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)
- [Key Vault RBAC](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide)
- [Soft Delete and Purge Protection](https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
