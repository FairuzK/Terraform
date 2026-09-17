# Terraform Interview Q&A

## 1. What is Terraform and why is it used?

Terraform is an open-source **Infrastructure as Code (IaC)** tool created by HashiCorp. It lets you define cloud and on-prem infrastructure (servers, networks, databases, DNS, load balancers, etc.) in declarative configuration files (HCL — HashiCorp Configuration Language), and then creates, updates, or destroys that infrastructure to match the desired state.

Why it's used:
- **Consistency & repeatability** — same config produces the same infrastructure every time.
- **Version control** — infra changes go through Git, code review, and history like application code.
- **Multi-cloud support** — one tool/workflow for AWS, Azure, GCP, Kubernetes, on-prem, SaaS, etc.
- **Automation** — removes manual point-and-click console work, reducing human error.
- **Plan-before-apply** — you can preview changes before they happen.

## 2. What is the difference between Terraform and Ansible?

| Aspect | Terraform | Ansible |
|---|---|---|
| Primary purpose | Provisioning infrastructure (create/destroy resources) | Configuration management (install packages, configure servers) |
| Approach | Declarative, state-based | Primarily procedural/imperative (though tasks describe desired state) |
| State | Maintains a state file to track resources | Stateless — runs against current server state each time |
| Idempotency | Built-in via state comparison | Achieved via idempotent modules/tasks |
| Best at | Spinning up VMs, networks, cloud services | Installing software, managing configs on existing servers |
| Agent | Agentless, talks to provider APIs | Agentless, uses SSH/WinRM |

In practice, they're often used together: Terraform provisions the infrastructure, Ansible configures the software on it.

## 3. What is Terraform State and why is it important?

Terraform State (`terraform.tfstate`) is a JSON file that maps the resources defined in your configuration to the real-world objects Terraform created (e.g., an `aws_instance` block to an actual EC2 instance ID).

Why it matters:
- **Tracks reality** — lets Terraform know what already exists so it doesn't recreate resources.
- **Enables diffing** — `terraform plan` compares config, state, and real infrastructure to compute changes.
- **Stores metadata** — resource attributes, dependency graph info, and sometimes sensitive data (so it must be protected).
- **Performance** — avoids querying every resource from the provider API on every run.

Losing or corrupting state can cause Terraform to lose track of real resources, potentially leading to duplicate resources or accidental deletion — which is why remote, versioned, locked state storage is a best practice.

## 4. What is the difference between `terraform plan` and `terraform apply`?

- **`terraform plan`**: A dry run. It compares your configuration against the current state (and real infrastructure) and shows an execution plan — what will be added, changed, or destroyed — without making any changes.
- **`terraform apply`**: Executes the actions proposed in a plan (it runs its own plan internally if you don't pass a saved plan file), actually creating/updating/destroying resources, and then updates the state file.

Best practice: run `plan`, review it (often in a PR/CI pipeline), then `apply` — sometimes using a saved plan file (`terraform plan -out=tfplan` then `terraform apply tfplan`) to guarantee what's applied matches exactly what was reviewed.

## 5. What is a Terraform Provider?

A Provider is a plugin that lets Terraform interact with a specific API — a cloud platform (AWS, Azure, GCP), a SaaS service (GitHub, Datadog, Cloudflare), or other infrastructure (Kubernetes, VMware, vSphere). Providers translate Terraform's resource blocks into API calls.

Example:
```hcl
provider "aws" {
  region = "us-east-1"
}
```

Each provider exposes its own set of **resources** (things you create) and **data sources** (things you read/reference). Providers are versioned independently and declared in a `required_providers` block for reproducibility.

## 6. What are Terraform Modules and why should we use them?

A Module is a reusable, self-contained package of Terraform configuration (a directory of `.tf` files) that can be called with input variables and produces outputs. The "root module" is your main working directory; any module it calls is a "child module."

Why use them:
- **Reusability** — write a VPC or EKS cluster config once, reuse it across environments/projects.
- **Consistency** — enforce organizational standards (naming, tagging, security settings).
- **Abstraction** — hide complexity behind a simple interface (inputs/outputs).
- **Maintainability** — smaller, composable pieces are easier to test and reason about.
- **Versioning** — modules can be pulled from a registry or Git tag/version, enabling controlled upgrades.

## 7. What is the difference between `count` and `for_each`?

Both create multiple instances of a resource/module, but:

**`count`**
- Takes a number.
- Resources are indexed numerically (`resource.name[0]`, `[1]`, ...).
- If you remove an item from the middle of a list driving `count`, Terraform shifts indices, which can cause unrelated resources to be destroyed/recreated.

```hcl
resource "aws_instance" "web" {
  count = 3
  ...
}
```

**`for_each`**
- Takes a map or a set of strings.
- Resources are indexed by key (`resource.name["key"]`), not position.
- Removing one key only affects that specific resource — safer for changing collections.

```hcl
resource "aws_instance" "web" {
  for_each = toset(["app1", "app2", "app3"])
  ...
}
```

Rule of thumb: use `for_each` when items have distinct identities or the collection may change over time; `count` is fine for simple, fixed-size, homogeneous replication (or for conditionally creating 0/1 of a resource).

## 8. How does Terraform handle dependencies between resources?

Terraform builds a **resource dependency graph** and creates/updates/destroys resources in the correct order (and in parallel where possible).

Two ways dependencies are established:
1. **Implicit dependencies** — when one resource references another's attribute (e.g., `subnet_id = aws_subnet.main.id`), Terraform automatically knows the subnet must be created first.
2. **Explicit dependencies** — using `depends_on` when there's no direct attribute reference but an ordering requirement still exists (e.g., IAM policy propagation before an app starts).

Terraform then performs a topological sort of the graph to determine execution order, running independent resources concurrently for speed.

## 9. What is a Remote Backend?

A backend determines where Terraform's state file is stored and how operations (like locking) are executed. A **remote backend** stores the state file outside your local machine — e.g., AWS S3, Azure Blob Storage, Google Cloud Storage, Terraform Cloud/HCP Terraform, or Consul.

Benefits:
- **Team collaboration** — everyone works off the same state instead of local copies going out of sync.
- **Locking** — most remote backends support state locking to prevent concurrent modifications.
- **Security** — centralized access control and encryption at rest, instead of state sitting on laptops.
- **Durability** — versioning/backup instead of a single local file that could be lost.

Example (S3 + DynamoDB for locking):
```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/network.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-table"
    encrypt        = true
  }
}
```

## 10. How would you manage Terraform State in a team environment?

- Use a **remote backend** (S3+DynamoDB, Terraform Cloud/HCP Terraform, Azure Storage, GCS) instead of local state.
- Enable **state locking** to prevent concurrent applies from corrupting state.
- Enable **encryption at rest** and restrict access via IAM/RBAC — state can contain secrets.
- **Separate state per environment/component** (e.g., dev/staging/prod, or per service) using workspaces or separate backend configs, to limit blast radius.
- Run Terraform through **CI/CD pipelines** rather than individual laptops, so plan/apply is consistent and auditable.
- **Version/back up state** (most remote backends do this automatically).
- Use `terraform state` commands (`list`, `show`, `mv`, `rm`) carefully and deliberately, and avoid manual edits to the state file.
- Consider tools like Terraform Cloud, Atlantis, or Spacelift for policy checks, plan review, and locking as part of the workflow.

## 11. What is State Locking and why is it required?

State Locking prevents multiple people or processes from running `terraform apply` (or other state-modifying commands) against the same state file at the same time. When one process is running, it acquires a lock; others attempting to run will wait or fail until the lock is released.

Why it's required: without locking, two simultaneous applies could both read the same state, make conflicting changes, and write back — corrupting the state file or causing resources to be created/destroyed incorrectly (a classic race condition). Backends like S3 (with a DynamoDB table), Terraform Cloud, and Consul support locking natively.

## 12. What happens when a resource is manually changed outside Terraform?

This is called **configuration drift**. Terraform's state no longer matches real-world infrastructure. Terraform doesn't detect this automatically as it happens, but:

- On the next `terraform plan` or `terraform refresh` (or the implicit refresh plan does), Terraform reads the current real state from the provider API and compares it to what's recorded in state and in config.
- If drift is found, `plan` will show the difference and, by default, propose changing the resource **back** to match the configuration (since config is the source of truth) — this can overwrite the manual change.
- If the manual change should instead be kept, you'd update the Terraform configuration itself to reflect the new desired state, or use `terraform apply -refresh-only` to sync state without changing infrastructure.

Manual changes are generally discouraged for Terraform-managed resources precisely because they create this drift risk.

## 13. What is the purpose of `terraform import`?

`terraform import` brings existing infrastructure (created manually or by another tool) under Terraform management by mapping a real resource to a resource address in your state file, without recreating it.

Typical workflow:
1. Write a resource block in your `.tf` config matching the real resource's type/name (initially can be mostly empty).
2. Run `terraform import aws_instance.web i-0123456789abcdef0`.
3. Terraform fetches the resource's current attributes into state.
4. Run `terraform plan` and adjust your configuration until it matches the imported state with no diff (so future applies don't unintentionally change/destroy it).

Newer Terraform versions also support declarative import blocks (`import { to = ..., id = ... }`) so the import can be planned and reviewed like any other change, and some tools can auto-generate the matching config.

## 14. What are Terraform Variables, Locals and Outputs?

- **Variables (`variable`)**: Inputs to a module/configuration, parameterizing it so the same code can be reused with different values (e.g., environment, instance size, region). Can have types, defaults, descriptions, and validation rules. Set via `.tfvars` files, CLI flags, environment variables, or defaults.

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

- **Locals (`locals`)**: Named values computed within a module for convenience/DRY-ness — like local variables in programming. Not settable from outside; used to avoid repeating expressions.

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}
```

- **Outputs (`output`)**: Values a module exposes after apply — e.g., a resource's ID or IP address. Used to display useful info to the user, pass data between modules (parent reads a child module's outputs), or feed into other tools/pipelines.

```hcl
output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
```

## 15. How do you manage secrets securely in Terraform?

- **Never hardcode secrets** in `.tf` files or commit them to version control.
- Use a **secrets manager** (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, GCP Secret Manager) and reference secrets via data sources at runtime rather than storing the values in code.
- Mark sensitive variables/outputs with `sensitive = true` so Terraform redacts them from CLI output (note: this does **not** encrypt them in the state file).
- **Protect the state file itself** — it often contains secrets in plaintext (e.g., DB passwords set via a resource argument). Use a remote backend with encryption at rest and strict access controls.
- Inject secrets via environment variables or CI/CD secret stores rather than `.tfvars` files committed to Git; if `.tfvars` files hold secrets, keep them out of version control (`.gitignore`) and encrypt them (e.g., with SOPS or git-crypt) if they must be stored.
- Consider **short-lived credentials** (e.g., dynamic secrets from Vault, or cloud IAM roles/OIDC for CI) instead of long-lived static keys.
- Use policy-as-code tools (Sentinel, OPA) to catch accidental secret exposure in plans before apply.
