# Kernel Module Management (KMM) Operator Helm Chart

This Helm chart deploys the Kernel Module Management (KMM) operator on a Kubernetes cluster.

## Overview

The Kernel Module Management (KMM) operator manages kernel modules in Kubernetes clusters. It automates the loading and unloading of kernel modules based on the node's kernel version and other conditions.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- Kustomize 4.0+ (for sync script)
- yq 4.0+ (for sync script)

## Installation

### Install from local chart

```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace
```

### Install with custom values

Create a `custom-values.yaml` file:

```yaml
controller:
  replicas: 2
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

Then install:

```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace \
  -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global image registry override (applies to all images) | `""` |
| `global.imagePullSecrets` | Global image pull secrets | `[]` |

### Controller Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controller.replicas` | Number of controller replicas | `1` |
| `controller.image.registry` | Controller image registry | `gcr.io` |
| `controller.image.repository` | Controller image repository | `k8s-staging-kmm/kernel-module-management-operator` |
| `controller.image.tag` | Controller image tag | `v20260415-v2.6.0` |
| `controller.resources.limits.cpu` | CPU limit | `500m` |
| `controller.resources.limits.memory` | Memory limit | `384Mi` |
| `controller.resources.requests.cpu` | CPU request | `10m` |
| `controller.resources.requests.memory` | Memory request | `64Mi` |

### Webhook Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `webhook.replicas` | Number of webhook replicas | `1` |
| `webhook.image.registry` | Webhook image registry | `gcr.io` |
| `webhook.image.repository` | Webhook image repository | `k8s-staging-kmm/kernel-module-management-webhook-server` |
| `webhook.image.tag` | Webhook image tag | `v20260415-v2.6.0` |
| `webhook.resources.limits.cpu` | CPU limit | `500m` |
| `webhook.resources.limits.memory` | Memory limit | `384Mi` |
| `webhook.resources.requests.cpu` | CPU request | `10m` |
| `webhook.resources.requests.memory` | Memory request | `64Mi` |

### Worker Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `worker.image.registry` | Worker image registry | `gcr.io` |
| `worker.image.repository` | Worker image repository | `k8s-staging-kmm/kernel-module-management-worker` |
| `worker.image.tag` | Worker image tag | `v20260415-v2.6.0` |

### Sign Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sign.image.registry` | Sign image registry | `gcr.io` |
| `sign.image.repository` | Sign image repository | `k8s-staging-kmm/kernel-module-management-signimage` |
| `sign.image.tag` | Sign image tag | `v20260415-v2.6.0` |

### Build Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `build.image.registry` | Build (Kaniko) image registry | `gcr.io` |
| `build.image.repository` | Build image repository | `kaniko-project/executor` |
| `build.image.tag` | Build image tag | `latest` |

## Uninstallation

```bash
helm uninstall kmm-operator --namespace kmm-operator-system
```

**Note:** By default, CRDs are not automatically removed. To remove them manually:

```bash
kubectl delete crd modules.kmm.sigs.x-k8s.io
kubectl delete crd modulebuildsignconfigs.kmm.sigs.x-k8s.io
kubectl delete crd moduleimagesconfigs.kmm.sigs.x-k8s.io
kubectl delete crd nodemodulesconfigs.kmm.sigs.x-k8s.io
kubectl delete crd preflightvalidations.kmm.sigs.x-k8s.io
```

## Upgrading

### Upgrade to a new chart version

```bash
helm upgrade kmm-operator ./default \
  --namespace kmm-operator-system
```

### Sync with upstream

Use the provided sync script to update the chart with a new upstream version:

```bash
./sync_script.sh v2.6.0 default
```

This will:
1. Clone the upstream repository
2. Render manifests using kustomize
3. Extract CRDs and resources
4. Apply Helm templating

After syncing, review and test the changes before deploying.

## Examples

### Installing in a different namespace

```bash
helm install kmm-operator ./default \
  --namespace my-namespace \
  --create-namespace
```

### Using a custom image registry

```yaml
# custom-values.yaml
global:
  imageRegistry: my-registry.example.com
```

### Changing image tags

```yaml
# custom-values.yaml
controller:
  image:
    tag: v2.6.0
webhook:
  image:
    tag: v2.6.0
worker:
  image:
    tag: v2.6.0
```

### Resource customization

```yaml
# custom-values.yaml
controller:
  resources:
    limits:
      cpu: 2000m
      memory: 1Gi
    requests:
      cpu: 200m
      memory: 256Mi
```

### Scaling replicas

```yaml
# custom-values.yaml
controller:
  replicas: 3
webhook:
  replicas: 2
```

## Troubleshooting

### Check operator logs

```bash
kubectl logs -n kmm-operator-system -l control-plane=controller
```

### Validate the chart

```bash
helm lint ./default
```

### Dry-run installation

```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --dry-run --debug
```

## License

This Helm chart is provided as-is. The Kernel Module Management operator is licensed under Apache License 2.0.

## Links

- [KMM Documentation](https://kubernetes-sigs.github.io/kernel-module-management/)
- [KMM GitHub Repository](https://github.com/k8s-staging-kmm/kernel-module-management)
- [KMM API Reference](https://kubernetes-sigs.github.io/kernel-module-management/documentation/api_reference/)
