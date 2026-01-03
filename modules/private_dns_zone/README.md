# Private DNS Zone Terraform Module

## 📘 Overview

This Terraform module creates an **Azure Private DNS Zone** with Virtual Network link, enabling private endpoint hostname resolution within your VNet. Essential for private endpoint scenarios where Azure PaaS services need DNS resolution from public hostnames to private IP addresses.

---

## ✅ Features

- **Private DNS Zone Creation**: Custom or Azure service DNS zones
- **VNet Link**: Automatic DNS resolution within linked VNets
- **Private Endpoint Support**: Resolves privatelink.* hostnames to private IPs
- **Registration Disabled**: Prevents VM auto-registration
- **Multi-VNet Support**: Can link to multiple VNets
- **Tagging Support**: Consistent resource organization

---

## ⚠️ Requirements

- **Terraform**: >= 1.5.0
- **Azure Provider**: ~> 4.0
- **Virtual Network**: VNet must exist before linking

---

## 📦 Resources Created

- `azurerm_private_dns_zone`: Private DNS zone
- `azurerm_private_dns_zone_virtual_network_link`: VNet DNS link

---

## 🧩 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `zone_name` | Private DNS zone name (e.g., privatelink.documents.azure.com) | string | - | ✅ |
| `resource_group_name` | Resource group name | string | - | ✅ |
| `virtual_network_id` | Virtual Network ID to link | string | - | ✅ |
| `tags` | Resource tags | map(string) | `{}` | ❌ |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `private_dns_zone_id` | Private DNS zone resource ID |
| `private_dns_zone_name` | Private DNS zone name |
| `vnet_link_id` | VNet link resource ID |

---

## 🚀 Usage Example

### Cosmos DB Private Endpoint DNS

```hcl
module "cosmos_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.documents.azure.com"
  resource_group_name = "rg-employee-app-dev"
  virtual_network_id  = module.virtualnetwork.virtual_network_id
  
  tags = {
    Environment = "dev"
    Purpose     = "Private Endpoint DNS"
  }
}

# Use in Cosmos DB module
module "cosmos_db" {
  source = "./modules/cosmos_db"
  
  # ... other config ...
  private_dns_zone_id = module.cosmos_private_dns_zone.private_dns_zone_id
}
```

### Key Vault Private Endpoint DNS

```hcl
module "keyvault_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-employee-app-dev"
  virtual_network_id  = module.virtualnetwork.virtual_network_id
  
  tags = var.tags
}
```

### Storage Account Private Endpoint DNS

```hcl
# Blob endpoint
module "storage_blob_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-employee-app-dev"
  virtual_network_id  = module.virtualnetwork.virtual_network_id
  
  tags = var.tags
}

# File endpoint
module "storage_file_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.file.core.windows.net"
  resource_group_name = "rg-employee-app-dev"
  virtual_network_id  = module.virtualnetwork.virtual_network_id
  
  tags = var.tags
}
```

---

## 📂 Module Structure

```
private_dns_zone/
├── main.tf       # DNS zone and VNet link resources
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
└── README.md     # This file
```

---

## 🔍 How It Works

### Without Private DNS Zone

```
Function App tries to connect to:
cosmos-emp-dev.documents.azure.com
    ↓
Public DNS resolution
    ↓
Resolves to PUBLIC IP (e.g., 13.91.x.x)
    ↓
❌ Connection fails (public access disabled)
```

### With Private DNS Zone

```
Function App tries to connect to:
cosmos-emp-dev.documents.azure.com
    ↓
Azure DNS checks privatelink.documents.azure.com zone
    ↓
Finds A record: cosmos-emp-dev → 10.0.3.5 (private IP)
    ↓
Connection routed to private endpoint
    ↓
✅ Successful connection via VNet
```

---

## 🔧 Common Private DNS Zones

| Azure Service | Private DNS Zone |
|---------------|------------------|
| Cosmos DB (SQL) | `privatelink.documents.azure.com` |
| Cosmos DB (MongoDB) | `privatelink.mongo.cosmos.azure.com` |
| Key Vault | `privatelink.vaultcore.azure.net` |
| Storage Blob | `privatelink.blob.core.windows.net` |
| Storage File | `privatelink.file.core.windows.net` |
| Storage Queue | `privatelink.queue.core.windows.net` |
| Storage Table | `privatelink.table.core.windows.net` |
| Azure SQL | `privatelink.database.windows.net` |
| Azure Database for MySQL | `privatelink.mysql.database.azure.com` |
| Azure Database for PostgreSQL | `privatelink.postgres.database.azure.com` |
| Service Bus | `privatelink.servicebus.windows.net` |
| Event Hubs | `privatelink.servicebus.windows.net` |
| App Service | `privatelink.azurewebsites.net` |

---

## 🧪 Testing

```bash
# Deploy module
terraform apply

# Verify DNS zone
az network private-dns zone show \
  --name privatelink.documents.azure.com \
  --resource-group rg-employee-app-dev

# Check VNet link
az network private-dns link vnet list \
  --resource-group rg-employee-app-dev \
  --zone-name privatelink.documents.azure.com

# View DNS records
az network private-dns record-set a list \
  --resource-group rg-employee-app-dev \
  --zone-name privatelink.documents.azure.com

# Test DNS resolution (from VM in VNet)
nslookup cosmos-emp-dev.documents.azure.com
# Should return private IP (10.0.x.x)
```

---

## 🔧 Advanced Configuration

### Link to Multiple VNets

```hcl
# Create multiple VNet links
module "cosmos_private_dns_zone" {
  source = "./modules/private_dns_zone"

  zone_name           = "privatelink.documents.azure.com"
  resource_group_name = "rg-employee-app-dev"
  virtual_network_id  = module.virtualnetwork.virtual_network_id
  
  tags = var.tags
}

# Additional VNet link for peered network
resource "azurerm_private_dns_zone_virtual_network_link" "peered_vnet" {
  name                  = "vnet-link-peered"
  resource_group_name   = "rg-employee-app-dev"
  private_dns_zone_name = module.cosmos_private_dns_zone.private_dns_zone_name
  virtual_network_id    = data.azurerm_virtual_network.peered_vnet.id
  registration_enabled  = false
}
```

### Manual DNS Record Creation

```hcl
# Usually handled by private endpoint DNS zone group
# But can be created manually if needed
resource "azurerm_private_dns_a_record" "custom" {
  name                = "custom-endpoint"
  zone_name           = module.cosmos_private_dns_zone.private_dns_zone_name
  resource_group_name = "rg-employee-app-dev"
  ttl                 = 300
  records             = ["10.0.3.10"]
}
```

---

## 🐛 Troubleshooting

**Issue**: DNS not resolving to private IP  
**Solution**: Verify VNet link is active and private endpoint has DNS zone group configured

```bash
# Check VNet link status
az network private-dns link vnet show \
  --name <link-name> \
  --resource-group <rg-name> \
  --zone-name privatelink.documents.azure.com

# Should show: "registrationEnabled": false, "virtualNetworkLinkState": "Completed"
```

**Issue**: Still resolving to public IP  
**Solution**: Check DNS cache and private endpoint DNS integration

```bash
# Clear DNS cache (Windows)
ipconfig /flushdns

# Verify A record exists
az network private-dns record-set a list \
  --zone-name privatelink.documents.azure.com \
  --resource-group <rg-name>
```

**Issue**: Multiple A records for same hostname  
**Solution**: Ensure only one private endpoint per service or use traffic manager

**Issue**: Cross-VNet DNS resolution fails  
**Solution**: Link DNS zone to all VNets or use VNet peering with DNS forwarding

---

## 💰 Cost

Private DNS Zone pricing:
- **Hosted zone**: $0.50 per zone per month
- **DNS queries**: $0.40 per million queries

**Monthly cost estimate**: $0.50-$2.00 per zone

---

## 📊 Monitoring

### Diagnostic Queries

```bash
# View all A records in zone
az network private-dns record-set a list \
  --zone-name privatelink.documents.azure.com \
  --resource-group rg-employee-app-dev \
  --output table

# Check VNet link status
az network private-dns link vnet show \
  --name <link-name> \
  --zone-name privatelink.documents.azure.com \
  --resource-group rg-employee-app-dev \
  --query "{Status:virtualNetworkLinkState, Registration:registrationEnabled}"
```

---

## 🔒 Security Considerations

✅ **Registration Disabled**: `registration_enabled = false` prevents VM auto-registration  
✅ **VNet Scoped**: DNS resolution only works within linked VNets  
✅ **No Public Access**: Private DNS zones are not accessible from internet  
⚠️ **Zone Name Accuracy**: Use correct Azure service zone names (case-sensitive)

---

## 📘 References

- [Azure Private DNS Documentation](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)
- [Terraform azurerm_private_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone)
- [Private Endpoint DNS Integration](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Private DNS Zone Names for Azure Services](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration)

---

## 👤 Maintainer

This module is part of the DTE Employee Management application infrastructure.  
Maintained by: DTE DevOps Team
