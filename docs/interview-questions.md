# Interview Questions for Team Training

**Purpose:** Evaluate understanding of the employee management infrastructure project. Use these questions in 1-on-1 sessions, team meetings, or technical interviews.

---

## 📖 Quick Reference: Key Concepts

Before diving into questions, review:
- **Architecture:** Three-tier app (Presentation, Application, Data)
- **Security:** Zero-trust, Managed Identity, Private Endpoints, RBAC
- **Infrastructure:** Terraform, 6 modular components, OPA policies
- **Deployment:** Dev (low-cost) vs Prod (high-security)

---

## 🥉 LEVEL 1: Foundational (Entry-Level / New Hires)

### Q1.1: Three-Tier Architecture Explanation
**Question:** Explain the three layers of this application and what each one does.

**Expected Answer:**
- **Presentation Layer (Static Web App):** Frontend UI hosted globally via CDN, handles user interface
- **Application Layer (Function App):** Serverless backend API that processes requests, implements business logic
- **Data Layer (Cosmos DB):** NoSQL database storing employee information

**Key Points to Listen For:**
- ✓ Correct naming of Azure services
- ✓ Understanding of responsibility at each layer
- ✓ Data flows from presentation → application → data and back

**Follow-up:** "Why would you separate layers instead of putting everything in one component?"

---

### Q1.2: What is a Managed Identity?
**Question:** What is a Managed Identity and why do we use it instead of storing API keys in the code?

**Expected Answer:**
- Managed Identity is an Azure-native service that provides credentials for authentication
- Azure Entra ID automatically issues bearer tokens
- No secrets stored in code, configuration files, or environment variables
- Automatic credential rotation (Azure handles it)
- Every operation is audited with the identity

**Key Points to Listen For:**
- ✓ Understands it eliminates hardcoded secrets
- ✓ Knows it's managed by Azure (no manual rotation)
- ✓ Understands audit trail benefit
- ✗ NOT saying "it's just like a password" (it's not - it's cryptographic)

**Follow-up:** "How would a compromised application behave with Managed Identity vs hardcoded API keys?"

---

### Q1.3: Private Endpoints vs Public Access
**Question:** What are Private Endpoints and why do we use them for Cosmos DB instead of public access?

**Expected Answer:**
- Private Endpoints create private IP addresses (10.0.x.x) for Azure services inside the VNet
- Eliminates public internet exposure
- Data stays on Microsoft backbone network
- More secure (no DDoS vector, compliance-ready)
- In this project: Cosmos DB, Key Vault, Storage Account all use private endpoints

**Key Points to Listen For:**
- ✓ Understands "private IP inside VNet" concept
- ✓ Knows about elimination of public internet exposure
- ✓ Mentions compliance/security benefits
- ✗ NOT confusing it with VPN or site-to-site connectivity

**Follow-up:** "What happens if someone on the internet tries to connect to our Cosmos DB?"

---

### Q1.4: What Does Terraform Do?
**Question:** What is Terraform and what does it do in this project?

**Expected Answer:**
- Terraform is Infrastructure as Code (IaC) tool that provisions cloud resources
- Converts .tf files into Azure resources via Azure API
- Manages state (knows which resources exist)
- In this project: Creates VNet, subnets, NSGs, Function App, Cosmos DB, Key Vault, etc.
- Same code can deploy to dev or prod (using tfvars)

**Key Points to Listen For:**
- ✓ Understands it's declarative (you describe desired state)
- ✓ Knows about state management
- ✓ Can articulate the benefit of IaC
- ✓ Understands code reusability for multiple environments

**Follow-up:** "What would happen if you manually deleted a resource in Azure portal?"

---

### Q1.5: Module Organization
**Question:** Why do we split Terraform code into separate modules instead of one big main.tf?

**Expected Answer:**
- Modularity: Each module has single responsibility (networking, Key Vault, Cosmos DB, etc.)
- Reusability: Same module can be used in multiple projects
- Maintainability: Easier to understand and modify
- Team collaboration: Different teams can own different modules
- Testability: Can test each module independently

**Key Points to Listen For:**
- ✓ Mentions at least 2 benefits
- ✓ Understands "separation of concerns"
- ✓ Can name 2-3 actual modules in the project (networking, cosmos_db, key_vault)
- ✗ NOT saying "I dunno, it just seemed organized"

**Follow-up:** "If you wanted to reuse the Key Vault module in another project, what would you need to change?"

---

## 🥈 LEVEL 2: Intermediate (1-2 Years Experience)

### Q2.1: Authentication Flow
**Question:** Walk me through the authentication flow when the Function App tries to read a secret from Key Vault.

**Expected Answer:**
1. Function App has System-Assigned Managed Identity (service principal)
2. Function code requests bearer token from Azure Entra ID using MSI
3. Entra ID validates the identity and issues bearer token
4. Function includes token in Authorization header to Key Vault API
5. Key Vault validates token signature and checks RBAC role
6. Role assignment: "Key Vault Secrets User" for the Function App MSI
7. ✓ Authorized → Return secret value
8. Secret never stored in code or config files

**Key Points to Listen For:**
- ✓ Understands the role of Azure Entra ID as token issuer
- ✓ Knows about RBAC role validation (not just authentication)
- ✓ Can distinguish between authentication (who are you?) and authorization (what can you do?)
- ✓ Understands why this prevents secret exposure

**Expected Code Example:**
```python
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

# Credential obtained automatically from Azure Entra ID
credential = ManagedIdentityCredential()
client = SecretClient(vault_url="https://kv-xxx.vault.azure.net/", credential=credential)
secret = client.get_secret("cosmos-db-endpoint")
```

**Follow-up:** "What would happen if the RBAC role 'Key Vault Secrets User' was removed from the Function App MSI?"

---

### Q2.2: NSG Rule Design
**Question:** Explain the NSG rules for the function_app subnet and why we defined them that way.

**Expected Answer:**

**Inbound (Restrictive):**
- Allow HTTPS (443) from ANY source
- Why: Azure Functions runtime needs to receive HTTP requests from the platform

**Outbound (Least Privilege):**
- Allow 443 to "CosmosDB" service tag
- Allow 443 to "KeyVault" service tag
- Allow 443 to "Storage" service tag
- Implicit deny all others
- Why: Function only needs to reach these three services; any other outbound is blocked

**Key Points to Listen For:**
- ✓ Understands principle of "least privilege"
- ✓ Knows about service tags (dynamic Microsoft-managed IP ranges)
- ✓ Can explain WHY each rule exists (not just listing them)
- ✓ Understands implicit deny at the end

**Follow-up:** "What if the Function App needed to send data to an external API? How would you modify the rules?"

---

### Q2.3: Cosmos DB Partition Key Strategy
**Question:** We chose `/departmentId` as the partition key for the employees container. Why is this a good choice?

**Expected Answer:**
- Partition key determines how data is distributed across partitions
- Good partition key: High cardinality, evenly distributes data, commonly used in queries
- `/departmentId` works because:
  - Typical organization has 5-20 departments (reasonable cardinality)
  - Data distributed evenly across partitions
  - Most queries filter by department
  - Enables efficient range queries within a department

**What Would Be Bad:**
- `/id` - Every document is separate partition (too high cardinality)
- `/country` - May have very few values (too low cardinality)
- `/name` - Uneven distribution (some names more common)

**Key Points to Listen For:**
- ✓ Understands partition key affects performance and cost
- ✓ Can articulate "cardinality" concept
- ✓ Thinks about query patterns when choosing key
- ✓ Understands distribution implications

**Follow-up:** "If you added a new query 'all employees hired in 2024', would the current partition key still work efficiently?"

---

### Q2.4: Dev vs Prod Configuration
**Question:** Compare dev.tfvars and prod.tfvars. What are the key differences and why?

**Expected Answer:**

| Aspect | Dev | Prod |
|--------|-----|------|
| Private Endpoints | Disabled | Enabled |
| Cosmos Throughput | 400 RUs (fixed) | 1000 RUs + autoscale |
| Autoscale | Disabled | Enabled to 4000 RUs |
| Log Retention | 30 days | 90 days |
| Cost | ~$95/month | ~$284/month |
| SLA | No SLA | 99.99% SLA |

**Why:**
- Dev: Cost-optimized, faster deployment, for testing
- Prod: Security hardened, high availability, compliance-ready

**Key Points to Listen For:**
- ✓ Can identify 3+ differences
- ✓ Understands EACH difference has a reason
- ✓ Can articulate the use case for each environment
- ✓ Understands trade-offs (security vs cost, performance vs complexity)

**Follow-up:** "If you needed a staging environment that mirrors prod but costs less, what would you change?"

---

### Q2.5: Terraform State Management
**Question:** Explain Terraform state. What problems arise if state is lost or corrupted?

**Expected Answer:**
- State file tracks which resources exist in Azure
- Terraform reads state before planning: "Did I create this before?"
- State contains resource IDs, configurations, sensitive data
- Location: Local (dev) → Remote backend (prod, recommended)

**Problems if State is Lost:**
- Terraform thinks no resources exist
- Next `terraform apply` would try to create everything again
- Results in duplicate resources (Key Vault, Storage Account, etc.)
- Some duplicates may fail (names already exist)
- Manual cleanup required

**Best Practices:**
- Store in remote backend: Azure Storage Account (in prod)
- Enable versioning, backup, encryption
- Restrict access (RBAC)
- Never check tfstate into Git

**Key Points to Listen For:**
- ✓ Understands state is the "source of truth" for Azure resources
- ✓ Can articulate disaster scenarios
- ✓ Knows about remote backends (not just local)
- ✓ Thinks about security and backup

**Follow-up:** "Where would you store the remote state backend for this project?"

---

## 🥇 LEVEL 3: Advanced (3+ Years Experience / Senior Engineers)

### Q3.1: Disaster Recovery Design
**Question:** Design a disaster recovery strategy for this application. Include RTO, RPO, and implementation details.

**Expected Answer:**

**Current State:**
- Cosmos DB: Multi-region replication (geo-redundant)
- Static Web App: Global CDN (no single point of failure)
- Function App: Stateless (easy to recover)

**Proposed DR Strategy:**
1. **Failover Region:** West US 2 (secondary)
2. **RTO (Recovery Time Objective):** < 5 minutes
   - Cosmos DB failover: < 2 minutes (automatic)
   - Function App redeploy: < 3 minutes (Terraform in CI/CD)
3. **RPO (Recovery Point Objective):** < 1 minute
   - Cosmos DB with continuous backup: RPO = last write
   - Log Analytics with 90-day retention: Audit trail preserved

**Implementation:**
```hcl
# Terraform for secondary region
module "failover_infrastructure" {
  providers = { azurerm = azurerm.secondary }
  
  region = "westus2"
  # Same modules, different region
}

# Cosmos DB active-active replication
enable_automatic_failover = true
geo_locations = [
  {location = "eastus2", failover_priority = 0},
  {location = "westus2", failover_priority = 1}
]

# Traffic Manager for DNS failover
azure_traffic_manager_profile {
  routing_method = "Priority"
  endpoints = [
    {name = "primary", location = "eastus2"},
    {name = "secondary", location = "westus2"}
  ]
}
```

**Key Points to Listen For:**
- ✓ Understands RTO vs RPO difference
- ✓ Considers multi-region for compute AND data
- ✓ Thinks about traffic routing (DNS failover)
- ✓ Includes testing strategy ("test failover monthly")
- ✓ Knows limitations (cost, complexity trade-offs)

**Follow-up:** "What would be the monthly cost of the DR setup? Is it worth it?"

---

### Q3.2: OPA Policy Governance
**Question:** Explain how OPA policies work in this project. Design a new policy that prevents resources without cost center tags.

**Expected Answer:**

**How OPA Works:**
1. OPA (Open Policy Agent) evaluates infrastructure definitions against rules
2. Rules written in Rego language (declarative, logic-based)
3. `conftest test` runs policies against Terraform plan
4. Fail policies → block deployment (shift-left governance)
5. Benefits: Prevent non-compliant resources before creation, catch security issues early

**New Policy: Enforce Cost Center Tags**
```rego
package terraform

import data.terraform.resources

# Deny resources missing cost_center tag
deny[msg] {
  resource := resources[_]
  resource.type == "azurerm_resource_group"
  
  tags := resource.tags
  not tags.cost_center
  
  msg := sprintf("Resource %v must have 'cost_center' tag for cost allocation", [resource.name])
}

# Warn on invalid cost center format
warn[msg] {
  resource := resources[_]
  tags := resource.tags
  tags.cost_center
  
  # Validate format: CC-XXXX
  not regex.match(`^CC-\d{4}$`, tags.cost_center)
  
  msg := sprintf("Cost center tag '%v' should match format CC-XXXX", [tags.cost_center])
}
```

**Integration with CI/CD:**
```bash
# In GitHub Actions or Azure Pipeline:
terraform plan -out=tfplan
conftest test -p opa/ tfplan

if [ $? -ne 0 ]; then
  echo "Policy violations detected - blocking deployment"
  exit 1
fi

terraform apply tfplan
```

**Key Points to Listen For:**
- ✓ Understands OPA is for compliance/governance (not syntax checking)
- ✓ Can write basic Rego logic
- ✓ Thinks about automation (not manual reviews)
- ✓ Understands enforcement vs warnings
- ✓ Can articulate business value (cost allocation, compliance)

**Follow-up:** "What other policies should we enforce for this project?"

---

### Q3.3: Performance Optimization
**Question:** The application is experiencing 5-second response times on 10% of requests. Walk through your troubleshooting approach.

**Expected Answer:**

**Diagnostic Steps:**

1. **Application Insights Analysis:**
```kusto
// Query: Where are the slow requests?
requests
| where duration > 5000
| summarize count() by operation_Name, bin(timestamp, 5m)
// Identify if specific endpoints are slow
```

2. **Identify Bottleneck:**
   - Cold start? (First request after deployment takes 30+ seconds)
   - Cosmos DB slow? (Throttled, high RU consumption)
   - Key Vault latency? (First secret read slower)
   - Network latency? (PE DNS resolution, inter-subnet routing)

3. **Cosmos DB Diagnostics:**
```kusto
// Check RU consumption and throttling
CosmosDiagnostics
| where TimeGenerated > ago(1h)
| summarize avg(RequestChargeAmount), max(RequestChargeAmount), any(ThrottledCount)
```

4. **Resolution Based on Root Cause:**
   - Cold start: Enable "Always On" in Function App (costs more)
   - RU throttling: Increase provisioned throughput or enable autoscaling
   - Slow queries: Add indexes or optimize partition key usage
   - Network: Enable Application Gateway for connection pooling

**Key Points to Listen For:**
- ✓ Systematic troubleshooting (not guessing)
- ✓ Uses monitoring tools (Application Insights, Log Analytics)
- ✓ Knows common bottlenecks (cold starts, RU throttling)
- ✓ Can write KQL queries to investigate
- ✓ Considers trade-offs (cost vs performance)

**Follow-up:** "How would you set up alerts to proactively detect these slowdowns?"

---

### Q3.4: Security Posture Assessment
**Question:** Perform a security review of this architecture. Identify 3 potential risks and propose mitigations.

**Expected Answer:**

**Risk 1: Cosmos DB Backup Exposure**
- **Threat:** Backups stored in geo-redundant storage (backup accessible from multiple regions)
- **Impact:** If West US 2 storage account is compromised, backup access exposed
- **Mitigation:**
  - Enable backup encryption with customer-managed keys (CMK) in Key Vault
  - Restrict backup storage account access via private endpoints
  - Implement backup restore job auditing

**Risk 2: Function App Code Injection**
- **Threat:** Malicious code uploaded to Function App
- **Impact:** Could read secrets, exfiltrate data
- **Mitigation:**
  - Restrict Function App admin access (use Managed Identity, remove master keys)
  - Implement code scanning (GitHub Advanced Security, Snyk)
  - Use immutable infrastructure (deploy via CI/CD, no manual changes)
  - Enable Function App audit logging

**Risk 3: DDoS Attack on Static Web App**
- **Threat:** Public CDN endpoint could be DDoS target
- **Impact:** Service unavailability
- **Mitigation:**
  - Enable Azure Front Door WAF (Web Application Firewall)
  - Implement rate limiting on API endpoints
  - Use Azure DDoS Protection Standard
  - Implement circuit breaker pattern in Function App

**Key Points to Listen For:**
- ✓ Identifies realistic threats (not theoretical only)
- ✓ Understands attack vectors and impact
- ✓ Proposes concrete, implementable mitigations
- ✓ Considers defense in depth (multiple layers)
- ✓ Knows relevant Azure security tools

**Follow-up:** "If you had a $10k annual budget for security tools, which would you prioritize?"

---

### Q3.5: Cost Optimization
**Question:** The monthly Azure bill is $400/month. Identify cost optimization opportunities without sacrificing production requirements.

**Expected Answer:**

**Analysis:**

```
Current Breakdown:
• Function App (EP1):        $45  (over-provisioned for typical load?)
• Cosmos DB (1000 RUs):     $120  (could autoscale lower during off-hours)
• Static Web App (Standard):   $9  (appropriate)
• Storage Account (GRS):     $15  (redundancy needed?)
• Private Endpoints (3x):    $30  (cost per PE)
• Log Analytics (90 days):   $60  (retention necessary for compliance?)
• Total: ~$279

Optimization Opportunities:

1. Cosmos DB Autoscaling Adjustment ($30-50 savings):
   Current: 1000 RUs fixed, autoscale to 4000 RUs
   Optimize: Scale to 3000 RUs max (lower peak needs)
   Trade-off: Possible throttling during traffic spikes
   Estimated savings: $30-50/month

2. Reserved Capacity for Function App ($15-20 savings):
   Current: Pay-as-you-go EP1
   Optimize: 1-year reserved instance (15% discount)
   Trade-off: Commitment for 1 year
   Estimated savings: $15-20/month

3. Log Analytics Retention ($20-30 savings):
   Current: 90-day retention
   Optimize: 60-day (still meets audit requirements)
   Trade-off: Reduced historical data
   Estimated savings: $20/month

4. Storage Account Redundancy ($5-10 savings):
   Current: GRS (geo-redundant, $15/month)
   Analyze: Is disaster recovery needed for Function state?
   Optimize: Consider LRS (local-redundant) or RA-GRS
   Trade-off: Reduced redundancy
   Estimated savings: $5-10/month

5. Remove Private Endpoints for Storage ($30 savings):
   Current: Storage account has private endpoint ($30)
   Analyze: Function App stores non-sensitive state
   Optimize: Use public endpoint with RBAC (Managed Identity)
   Trade-off: Storage in public internet (but still requires Managed ID for access)
   Estimated savings: $30/month

Total Potential Savings: $100-150/month (~35-40% reduction)
New Estimated Cost: $130-180/month

Final Recommendation:
   Apply: Optimizations 1, 2, 3, 4
   Savings: $70-100/month
   Risk: Low (all reversible)
   
   Skip: Optimization 5 (PE for Storage protects state)
```

**Key Points to Listen For:**
- ✓ Analyzes cost breakdown line-by-line
- ✓ Understands Azure pricing models (RUs, reserved instances, retention)
- ✓ Considers trade-offs (cost vs. performance vs. security)
- ✓ Proposes low-risk optimizations
- ✓ Can quantify savings

**Follow-up:** "How would you monitor costs to prevent them from creeping back up?"

---

## 🎯 Assessment Rubric

### Junior Engineer (Level 1-2)
- **Pass Criteria:** Can answer 70%+ of Level 1 questions correctly
- **Key Skills:**
  - Understands basic architecture
  - Can explain Terraform basics
  - Knows what Managed Identity is
  - Comfortable with module organization

### Mid-Level Engineer (Level 2)
- **Pass Criteria:** Can answer 70%+ of Level 2 questions, 30%+ of Level 3
- **Key Skills:**
  - Can troubleshoot infrastructure issues
  - Understands security concepts deeply
  - Can design networking configurations
  - Can optimize configurations

### Senior Engineer (Level 3)
- **Pass Criteria:** Can answer 80%+ of Level 3 questions
- **Key Skills:**
  - Can design disaster recovery strategies
  - Understands policy governance
  - Can optimize costs and performance
  - Can conduct security assessments
  - Can mentor junior engineers

---

## 📝 Note for Interviewers

- Allow 45-60 minutes per interview
- Mix questions from different levels based on candidate level
- Look for depth (not just breadth) of understanding
- Ask follow-ups to clarify thinking
- Judge on problem-solving approach, not just final answers
- Encourage candidates to ask clarifying questions

---

**Last Updated:** December 2025
**Version:** 1.0
