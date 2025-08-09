# Terraform Infrastructure as Code

This directory is reserved for Terraform configurations for cloud infrastructure deployment.

## Future Implementation

- GKE cluster configuration
- Cloud SQL setup
- Redis Memorystore
- Load balancers and networking
- Monitoring infrastructure

## Planned Structure

```
terraform/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── gke/
│   ├── database/
│   └── monitoring/
└── main.tf
```

## Usage

```bash
cd deploy/terraform/
terraform init
terraform plan
terraform apply
```

## Related Commands

- `make deploy-k8s` - Deploy application to existing cluster
- `make deploy-helm` - Deploy using Helm charts