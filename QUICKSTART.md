# Quick Start Guide - Get Running in 5 Minutes ⚡

> **For detailed documentation:** See [default/README.md](default/README.md)  
> **For developers:** See [USAGE.md](USAGE.md)

## Prerequisites

- Kubernetes 1.23+ cluster
- Helm 3.8+ installed
- kubectl configured

```bash
# Quick check
helm version --short
kubectl cluster-info
```

## Install KMM Operator

### Option 1: Via Helm Repository (Recommended)

```bash
# Add repository
helm repo add kmm-helm https://davtech.github.io/kernel-module-management-helm/
helm repo update

# Install
helm install kmm kmm-helm/kernel-module-management \
  --create-namespace \
  --namespace kmm-operator-system
```

### Option 2: Via Local Clone

```bash
# Clone repository
git clone https://github.com/davtech/kernel-module-management-helm.git
cd kernel-module-management-helm

# Install
helm install kmm ./default \
  --create-namespace \
  --namespace kmm-operator-system
```

### Option 3: Via Release Package

```bash
# Download package
wget https://github.com/davtech/kernel-module-management-helm/releases/download/v2.5.0/kernel-module-management-2.5.0.tgz

# Install
helm install kmm kernel-module-management-2.5.0.tgz \
  --create-namespace \
  --namespace kmm-operator-system
```

## Verify Installation

```bash
# Check release
helm status kmm --namespace kmm-operator-system

# Check pods (may take 1-2 minutes)
kubectl get pods -n kmm-operator-system

# Expected output:
# NAME                                    READY   STATUS    RESTARTS
# kmm-controller-manager-xxxxx            2/2     Running   0
# kmm-webhook-server-xxxxx                1/1     Running   0
```

## Test with a Module

Create a test module (requires a node with matching kernel):

```yaml
# test-module.yaml
apiVersion: kmm.sigs.x-k8s.io/v1beta1
kind: Module
metadata:
  name: example-module
spec:
  moduleLoader:
    container:
      modprobe:
        moduleName: example
      kernelMappings:
        - regexp: '^.*$'
          containerImage: "example.com/example-module:latest"
  selector:
    node-role: worker
```

```bash
kubectl apply -f test-module.yaml
kubectl get modules
```

## Common Customizations

### Use Private Registry

```bash
helm install kmm ./default \
  --set global.imageRegistry=my-registry.io \
  --namespace kmm-operator-system \
  --create-namespace
```

### Scale Replicas

```bash
helm install kmm ./default \
  --set controller.replicas=3 \
  --set webhook.replicas=2 \
  --namespace kmm-operator-system \
  --create-namespace
```

### Custom Resources

```yaml
# custom-values.yaml
controller:
  replicas: 2
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
```

```bash
helm install kmm ./default \
  -f custom-values.yaml \
  --namespace kmm-operator-system \
  --create-namespace
```

## Upgrade

```bash
# Via repository
helm upgrade kmm kmm-helm/kernel-module-management

# Via local
helm upgrade kmm ./default --namespace kmm-operator-system
```

## Uninstall

```bash
# Remove operator
helm uninstall kmm --namespace kmm-operator-system

# Remove CRDs (optional)
kubectl delete crd modules.kmm.sigs.x-k8s.io \
  modulebuildsignconfigs.kmm.sigs.x-k8s.io \
  moduleimagesconfigs.kmm.sigs.x-k8s.io \
  nodemodulesconfigs.kmm.sigs.x-k8s.io \
  preflightvalidations.kmm.sigs.x-k8s.io
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod -n kmm-operator-system -l control-plane=controller

# Check logs
kubectl logs -n kmm-operator-system -l control-plane=controller --tail=50
```

### Chart validation fails

```bash
# Lint chart
helm lint ./default

# Dry-run
helm install test ./default --dry-run --debug
```

### Image pull errors

Check image tags are correct (KMM uses specific date-versioned tags):

```bash
helm template test ./default | grep "image:"
```

## Next Steps

- **Complete Documentation**: [default/README.md](default/README.md) - All configuration options
- **KMM Usage Guide**: [Upstream Docs](https://kubernetes-sigs.github.io/kernel-module-management/) - How to use the operator
- **Developer Guide**: [USAGE.md](USAGE.md) - For maintainers and contributors

## Need Help?

- 📖 [Complete Chart Documentation](default/README.md)
- 🐛 [Report Issues](https://github.com/davtech/kernel-module-management-helm/issues)
- 📚 [KMM Official Docs](https://kubernetes-sigs.github.io/kernel-module-management/)
# Quick Start Guide

## Prerequisites Check

```bash
# Check if required tools are installed
command -v helm >/dev/null 2>&1 || { echo "ERROR: helm is not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "ERROR: kubectl is not installed"; exit 1; }
command -v kustomize >/dev/null 2>&1 || { echo "WARNING: kustomize not installed (needed for sync)"; }
command -v yq >/dev/null 2>&1 || { echo "WARNING: yq not installed (needed for sync)"; }
echo "All basic tools are installed ✓"
```

## Step 1: Validate the Chart

```bash
# Lint the chart
helm lint ./default

# Test template rendering
helm template test-release ./default --namespace test-namespace > /tmp/rendered.yaml
echo "Template rendered successfully to /tmp/rendered.yaml"
```

## Step 2: Sync with Upstream (Optional)

If you have kustomize and yq installed:

```bash
# Sync with upstream v2.5.0
./sync_script.sh v2.5.0 default
```

## Step 3: Install the Chart

### Option A: Direct Installation

```bash
# Dry-run first (recommended)
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace \
  --dry-run --debug

# Install with default values
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace
```

### Option B: With Custom Values

Create `my-values.yaml`:

```yaml
controllerManager:
  replicas: 2
  logLevel: 3
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
```

Install:

```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace \
  -f my-values.yaml
```

## Step 4: Verify Installation

```bash
# Check release status
helm status kmm-operator --namespace kmm-operator-system

# Check pods
kubectl get pods -n kmm-operator-system

# Check logs
kubectl logs -n kmm-operator-system -l control-plane=controller-manager --tail=100 -f
```

## Step 5: Test the Operator

Create a test Module CR:

```yaml
apiVersion: kmm.sigs.x-k8s.io/v1beta1
kind: Module
metadata:
  name: example-module
spec:
  moduleLoader:
    container:
      modprobe:
        moduleName: example
      kernelMappings:
        - regexp: '^.*$'
          containerImage: "example.com/example-module:latest"
  selector:
    kubernetes.io/hostname: worker-node-1
```

Apply:

```bash
kubectl apply -f example-module.yaml
```

## Upgrade

```bash
helm upgrade kmm-operator ./default \
  --namespace kmm-operator-system
```

## Uninstall

```bash
helm uninstall kmm-operator --namespace kmm-operator-system

# Clean up CRDs (optional)
kubectl delete crd modules.kmm.sigs.x-k8s.io
kubectl delete crd modulebuildsignconfigs.kmm.sigs.x-k8s.io
kubectl delete crd moduleimagesconfigs.kmm.sigs.x-k8s.io
kubectl delete crd nodemodulesconfigs.kmm.sigs.x-k8s.io
kubectl delete crd preflightvalidations.kmm.sigs.x-k8s.io
```

## Troubleshooting

### Chart validation fails

```bash
# Check syntax
helm lint default

# Render templates
helm template test default
```

### Operator not starting

```bash
# Check pod status
kubectl get pods -n kmm-operator-system

# Check logs
kubectl logs -n kmm-operator-system -l control-plane=controller-manager

# Describe pod
kubectl describe pod -n kmm-operator-system -l control-plane=controller-manager
```

### CRDs not installed

```bash
# Check CRDs
kubectl get crds | grep kmm

# Manually install CRDs
kubectl apply -f default/crds/
```

## Next Steps

- Read the full [USAGE.md](USAGE.md) for detailed documentation
- Check [values.yaml](default/values.yaml) for all configuration options
- Visit [KMM Documentation](https://kubernetes-sigs.github.io/kernel-module-management/) for operator usage
