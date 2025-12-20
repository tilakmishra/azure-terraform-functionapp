# Network Architecture

This document describes the network security architecture implemented in this solution.

## Network Topology

The solution uses a hub-and-spoke inspired design within a single VNet, with dedicated subnets for different workload types.

### Address Space

| Environment | VNet CIDR | Available IPs |
|-------------|-----------|---------------|
| Development | 10.0.0.0/16 | 65,536 |
| Production | 10.1.0.0/16 | 65,536 |

### Subnet Layout

| Subnet | CIDR | Purpose | Delegation |
|--------|------|---------|------------|
| function_app | 10.x.1.0/24 | Function App VNet Integration | Microsoft.Web/serverFarms |
| app_service | 10.x.2.0/24 | App Service VNet Integration | Microsoft.Web/serverFarms |
| private_endpoints | 10.x.3.0/24 | Private Endpoints for PaaS | None |
| data | 10.x.4.0/24 | Data workloads | None |

## Traffic Flow

### Inbound Traffic

```
Internet
    │
    ▼
┌─────────────────┐
│ Static Web App  │  (Public - CDN backed)
│   (Frontend)    │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│ Function App    │  ◄── Private Endpoint (10.x.3.x)
│   (Backend)     │
└────────┬────────┘
         │
         ▼
    Private Network
```

### Outbound Traffic (Function App)

```
┌─────────────────┐
│ Function App    │
│ (10.x.1.0/24)   │
└────────┬────────┘
         │ VNet Integration
         │ (All traffic routed through VNet)
         ▼
┌─────────────────────────────────────────────┐
│              Virtual Network                 │
│                                             │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ Key Vault   │  │ Cosmos DB   │          │
│  │ (PE)        │  │ (PE)        │          │
│  │ 10.x.3.x    │  │ 10.x.3.x    │          │
│  └─────────────┘  └─────────────┘          │
│                                             │
│  ┌─────────────┐                           │
│  │ Storage     │                           │
│  │ (PE)        │                           │
│  │ 10.x.3.x    │                           │
│  └─────────────┘                           │
└─────────────────────────────────────────────┘
```

## Service Endpoints vs Private Endpoints

This solution uses both Service Endpoints and Private Endpoints for defense in depth:

### Service Endpoints
- Allow traffic from specific subnets to Azure PaaS services
- Traffic stays on Azure backbone network
- No additional cost
- Used for: allowing Function App subnet to access Cosmos DB, Key Vault

### Private Endpoints
- Create a private IP address for the PaaS service within your VNet
- DNS resolution required for proper routing
- Additional cost per endpoint (~$7/month)
- Used for: all PaaS services (Key Vault, Cosmos DB, Storage, Function App)

## Network Security Groups

### Function App Subnet NSG

| Priority | Direction | Action | Source | Destination | Port | Purpose |
|----------|-----------|--------|--------|-------------|------|---------|
| 100 | Inbound | Allow | AppService | VirtualNetwork | 443 | Allow SWA to call Function App |
| 100 | Outbound | Allow | VirtualNetwork | VirtualNetwork | 443 | Allow access to Private Endpoints |
| 1000 | Inbound | Deny | * | * | * | Deny all other inbound |
| 1000 | Outbound | Deny | * | * | * | Deny all other outbound |

### Private Endpoints Subnet NSG

| Priority | Direction | Action | Source | Destination | Port | Purpose |
|----------|-----------|--------|--------|-------------|------|---------|
| 200 | Inbound | Allow | VirtualNetwork | VirtualNetwork | 443 | Allow VNet traffic to PEs |
| 1000 | Inbound | Deny | * | * | * | Deny all other inbound |

## Key Vault Network Configuration

```hcl
network_acls {
  default_action             = "Deny"
  bypass                     = "AzureServices"
  virtual_network_subnet_ids = [
    subnet_function_app_id,
    subnet_app_service_id
  ]
}
```

- Public network access: Disabled
- Private endpoint: Enabled
- Allowed subnets: function_app, app_service (via Service Endpoints)

## Cosmos DB Network Configuration

```hcl
public_network_access_enabled     = false
is_virtual_network_filter_enabled = true

virtual_network_rule {
  id = subnet_function_app_id
}

virtual_network_rule {
  id = subnet_data_id
}
```

- Public network access: Disabled
- VNet filtering: Enabled
- Private endpoint: Enabled
- Allowed subnets: function_app, data (via Service Endpoints)

## Storage Account Network Configuration

```hcl
public_network_access_enabled = false

network_rules {
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = [subnet_function_app_id]
}
```

- Public network access: Disabled
- Private endpoints: Blob and File shares
- Allowed subnets: function_app (via Service Endpoints)

## DNS Considerations

Private Endpoints require DNS configuration for proper name resolution. Options:

1. **Azure Private DNS Zones** (Recommended for production)
   - Create private DNS zones for each service type
   - Link zones to VNet
   - Automatic A record registration

2. **Custom DNS Server**
   - Configure conditional forwarders
   - Forward Azure service domains to Azure DNS (168.63.129.16)

3. **Host File Entries** (Development only)
   - Manual entries for private endpoint IPs
   - Not scalable for production

### Required Private DNS Zones

| Service | Private DNS Zone |
|---------|------------------|
| Key Vault | privatelink.vaultcore.azure.net |
| Cosmos DB | privatelink.documents.azure.com |
| Storage (Blob) | privatelink.blob.core.windows.net |
| Storage (File) | privatelink.file.core.windows.net |
| Function App | privatelink.azurewebsites.net |

## Security Compliance

This architecture addresses the following security requirements:

| Requirement | Implementation |
|-------------|----------------|
| Data encryption in transit | TLS 1.2 minimum on all services |
| Data encryption at rest | Azure-managed keys (default) |
| Network isolation | VNet with subnets, NSGs |
| Private connectivity | Private Endpoints for all PaaS |
| Least privilege access | RBAC on Key Vault |
| Audit logging | Diagnostic settings to Log Analytics |
| DDoS protection | Azure DDoS Basic (included) |
