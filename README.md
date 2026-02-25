# Infrastructure & Deployment

## Overview
This repository contains Terraform IaC and deployment scripts for provisioning and managing cloud infrastructure across two regions.

## Components

### Terraform (`/terraform`)
Provisions the required cloud resources across two regions, ensuring consistent infrastructure configuration and state management.

### Deploy Script (`deploy.sh`)
Automates service deployment into each provisioned region, handling the full deployment lifecycle per environment.

## Usage

### Infrastructure Provisioning
````terraform init
terraform plan
terraform apply```

### Service Deployment
```bash
./deploy.sh```

## Requirements
- Terraform >= 3.0
- AWS CLI (configured with appropriate credentials)
- Bash
```