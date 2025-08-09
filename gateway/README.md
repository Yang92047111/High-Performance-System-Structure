# API Gateway Configuration

This directory is reserved for API Gateway and service mesh configurations.

## Future Implementation

- Istio service mesh configuration
- API Gateway routing rules
- Rate limiting policies
- Authentication/authorization configs
- Traffic management

## Planned Structure

```
gateway/
├── istio/
│   ├── gateway.yaml
│   ├── virtual-service.yaml
│   └── destination-rule.yaml
├── nginx/
│   └── nginx.conf
└── envoy/
    └── envoy.yaml
```

## Current Implementation

API Gateway functionality is currently handled by:
- Backend middleware (rate limiting, auth)
- Docker Compose networking
- Kubernetes Ingress (in deploy/k8s/)

## Related Commands

- `make deploy-k8s` - Includes ingress configuration
- `make test-api` - Test API endpoints through gateway