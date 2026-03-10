
<img width="763" height="263" alt="Screenshot 2026-03-10 at 9 50 44 AM" src="https://github.com/user-attachments/assets/4fc9641f-b1c5-4f58-9e7b-1f9d7e389317" />



modules/sql_mi/variables.tf
```hcl
variable "name" {
  type        = string
  description = "Name prefix for the SQL MI resources"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID dedicated to SQL MI"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Gen5"
}

variable "vcores" {
  type    = number
  default = 4
}

variable "storage_size_in_gb" {
  type    = number
  default = 32
}

variable "enable_failover" {
  type        = bool
  description = "When true, provisions a secondary SQL MI and a failover group"
  default     = false
}

variable "failover_location" {
  type        = string
  description = "Region for the secondary MI (required if enable_failover = true)"
  default     = ""
}

variable "failover_subnet_id" {
  type        = string
  description = "Subnet ID in the failover region (required if enable_failover = true)"
  default     = ""
}
```

modules/sql_mi/main.tf
```hcl
# ── Primary Managed Instance ──────────────────────────────────────────────────
resource "azurerm_mssql_managed_instance" "primary" {
  name                = "${var.name}-primary"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id

  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  sku_name           = var.sku_name
  vcores             = var.vcores
  storage_size_in_gb = var.storage_size_in_gb
}

# ── Secondary MI (only when enable_failover = true) ───────────────────────────
resource "azurerm_mssql_managed_instance" "secondary" {
  count = var.enable_failover ? 1 : 0

  name                = "${var.name}-secondary"
  resource_group_name = var.resource_group_name
  location            = var.failover_location
  subnet_id           = var.failover_subnet_id

  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  sku_name           = var.sku_name
  vcores             = var.vcores
  storage_size_in_gb = var.storage_size_in_gb
}

# ── Failover Group (only when enable_failover = true) ─────────────────────────
resource "azurerm_mssql_managed_instance_failover_group" "this" {
  count = var.enable_failover ? 1 : 0

  name                        = "${var.name}-fog"
  location                    = azurerm_mssql_managed_instance.primary.location
  managed_instance_id         = azurerm_mssql_managed_instance.primary.id
  partner_managed_instance_id = azurerm_mssql_managed_instance.secondary[0].id

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}
```

modules/sql_mi/outputs.tf
```hcl
output "primary_fqdn" {
  value = azurerm_mssql_managed_instance.primary.fqdn
}

output "secondary_fqdn" {
  value = var.enable_failover ? azurerm_mssql_managed_instance.secondary[0].fqdn : null
}

output "failover_group_id" {
  value = var.enable_failover ? azurerm_mssql_managed_instance_failover_group.this[0].id : null
}
```

Root main.tf
```hcl
provider "azurerm" {
  features {}
}

module "sql_mi" {
  source = "./modules/sql_mi"

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  enable_failover    = var.enable_failover
  failover_location  = var.failover_location
  failover_subnet_id = var.failover_subnet_id
}
```

Root variables.tf
```hcl
variable "name"                { type = string }
variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "subnet_id"           { type = string }
variable "admin_username"      { type = string }
variable "admin_password"      { type = string; sensitive = true }
variable "enable_failover"     { type = bool;   default = false }
variable "failover_location"   { type = string; default = "" }
variable "failover_subnet_id"  { type = string; default = "" }
```

terraform.tfvars — toggle this to observe plan diff:
```hcl
name                = "myapp-sqlmi"
resource_group_name = "rg-sql-prod"
location            = "eastus"
subnet_id           = "/subscriptions/.../subnets/sqlmi-primary"
admin_username      = "sqladmin"
admin_password      = "YourSecureP@ssword!"

# ── Flip this to true to see the secondary + failover group appear in the plan
enable_failover    = false
failover_location  = "westus"
failover_subnet_id = "/subscriptions/.../subnets/sqlmi-secondary"
```

terraform plan -out workflow:
```bash
# Initialize
terraform init

# Plan WITHOUT failover — observe only 1 resource (primary MI)
terraform plan -out=plan-no-failover.tfplan

# Inspect the saved plan
terraform show plan-no-failover.tfplan

# Now flip enable_failover = true in terraform.tfvars, then re-plan
terraform plan -out=plan-with-failover.tfplan

# Diff — you'll see +2 new resources: secondary MI + failover group
terraform show plan-with-failover.tfplan

# Apply whichever plan you want
terraform apply plan-with-failover.tfplan
```

module reused
<img width="772" height="439" alt="Screenshot 2026-03-10 at 10 01 24 AM" src="https://github.com/user-attachments/assets/9094706c-f298-479b-b4f3-76ce6a50beeb" />
