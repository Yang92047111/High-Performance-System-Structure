# Kind Local Kubernetes Deployment

This directory is reserved for Kind (Kubernetes in Docker) local deployment configurations.

## Future Implementation

- Kind cluster configuration
- Local Kubernetes manifests
- Development-specific overrides

## Usage

```bash
# Create local Kind cluster
kind create cluster --config kind-config.yaml

# Deploy to Kind
make deploy-k8s
```

## Related Commands

- `make deploy-k8s` - Deploy to Kubernetes (including Kind)
- `make deploy-helm` - Deploy using Helm charts