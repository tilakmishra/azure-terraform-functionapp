# DTE Infrastructure Wiki

Welcome to the DTE Web Application infrastructure documentation.

## Pages

| Document | Description |
|----------|-------------|
| [README](../README.md) | Quick start guide, prerequisites, deployment instructions |
| [Network Architecture](network-architecture.md) | VNet design, subnets, NSGs, private endpoints |
| [Module Reference](module-reference.md) | Detailed module inputs, outputs, and configuration |
| [Architecture Diagram](architecture-diagram.md) | Visual representation of the solution |

## Solution Summary

### What We're Building

A secure, enterprise-grade web application on Azure with:

- **Frontend**: Static Web App (React/Angular/Vue)
- **Backend**: Python Function App (REST API)
- **Database**: Cosmos DB (NoSQL)
- **Secrets**: Key Vault
- **Monitoring**: Application Insights + Log Analytics

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Private Endpoints for all PaaS | Zero-trust network model, data never traverses public internet |
| VNet Integration for Function App | Outbound traffic secured, can access private endpoints |
| RBAC on Key Vault | Modern access control, no access policies to manage |
| Modular Terraform structure | Reusable components, easier testing, clear separation |
| Environment-specific tfvars | Same code, different configurations per environment |

### Security Posture

| Control | Status |
|---------|--------|
| Public network access | Disabled on all PaaS services |
| Encryption in transit | TLS 1.2 minimum |
| Encryption at rest | Azure-managed keys |
| Network segmentation | 4 subnets with NSGs |
| Private connectivity | 5+ Private Endpoints |
| Identity | Managed Identity for Function App |
| Secrets management | Key Vault with RBAC |
| Logging | Centralized in Log Analytics |

### Resource Count

| Environment | Resources | Estimated Monthly Cost |
|-------------|-----------|------------------------|
| Development | 43 | ~$225 |
| Production | 43 | ~$365 |

## Quick Reference

### Deploy Development

```bash
terraform init
terraform plan -var-file="dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan
```

### Deploy Production

```bash
terraform plan -var-file="prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

### Destroy Environment

```bash
terraform destroy -var-file="dev.tfvars"
```

### Format and Validate

```bash
terraform fmt -recursive
terraform validate
```

## File Structure

```
terraform/
├── *.tf                    # Root module configuration
├── dev.tfvars              # Dev environment variables
├── prod.tfvars             # Prod environment variables
├── modules/                # Reusable modules
│   ├── resource_group/
│   ├── virtualnetwork/
│   ├── virtualsubnet/
│   ├── securitygroup/
│   ├── key_vault/
│   ├── cosmos_db/
│   ├── function_app/
│   ├── static_web_app/
│   ├── log_analytics/
│   └── app_insights/
└── docs/                   # Documentation
    ├── DOCUMENTATION-SUMMARY.md
    ├── network-architecture.md
    ├── module-reference.md
    └── architecture-diagram.md
```

## Contact

For questions about this infrastructure, contact the platform team.
