# Developer and Maintainer Guide

This guide is for developers and maintainers of the Kernel Module Management Helm Charts repository.

> **For end users:** See [QUICKSTART.md](QUICKSTART.md) for installation, or [default/README.md](default/README.md) for complete chart documentation.

## 📂 Repository Structure

```
.
├── sync_script.sh                 # Automated sync with upstream KMM
├── README.md                      # Repository landing page
├── QUICKSTART.md                  # End-user quick start guide
├── USAGE.md                       # This file (maintainer guide)
├── index.yaml                     # Helm repository index
├── default/                       # Helm chart for KMM operator
│   ├── Chart.yaml                 # Chart metadata
│   ├── values.yaml                # Default configuration values
│   ├── README.md                  # Chart documentation
│   ├── templates/                 # Kubernetes templates (split by kind)
│   │   ├── _helpers.tpl           # Helm template helpers
│   │   ├── clusterrole.yaml       # RBAC ClusterRole
│   │   ├── deployment.yaml        # Operator deployments
│   │   └── ...                    # Other resource types
│   └── crds/                      # CustomResourceDefinitions (5 CRDs)
└── .github/
    └── workflows/
        └── lint-test.yml          # CI/CD pipeline
```

## 🔄 Sync Script Workflow

The `sync_script.sh` automates synchronization with upstream KMM releases.

### Usage

```bash
./sync_script.sh <VERSION> [CHART_DIR]

# Example
./sync_script.sh v2.6.0 default
```

### Process

1. **Clone upstream** repository at specified tag
2. **Render manifests** using kustomize from `config/default/`
3. **Extract CRDs** to `crds/` directory (named by `metadata.name`)
4. **Split resources by kind** into separate template files
5. **Apply Helm templating** (namespace placeholders, conditionals)
6. **Update Chart.yaml** with new `appVersion`

### Prerequisites

```bash
# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Install yq v4+
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### Post-Sync Checklist

- [ ] Review changes: `git diff default/`
- [ ] Update `Chart.yaml` version if needed
- [ ] **Verify image tags** in `values.yaml` (check upstream Makefile for correct tags)
- [ ] Test: `helm lint default && helm template test default`
- [ ] Update documentation if configuration changed
- [ ] Commit changes

## 🏗️ Development Workflow

### Making Chart Changes

```bash
# 1. Edit files
vim default/values.yaml
vim default/templates/deployment.yaml

# 2. Validate
helm lint default

# 3. Test rendering
helm template test default --debug

# 4. Test in cluster
kind create cluster --name kmm-dev
helm install kmm default --namespace kmm-operator-system --create-namespace
kubectl get pods -n kmm-operator-system

# 5. Cleanup
helm uninstall kmm --namespace kmm-operator-system
kind delete cluster --name kmm-dev
```

### Testing Image Configurations

```bash
# Test global registry override
helm template test default \
  --set global.imageRegistry=my-registry.io | grep "image:"

# Verify all 5 images render correctly
helm template test default | grep -E "image: (gcr|quay)"
```

## 📦 Release Process

### 1. Update Chart Version

```yaml
# Edit default/Chart.yaml
version: 2.6.0
appVersion: "2.6.0"
```

### 2. Package Chart

```bash
helm package ./default
# Creates: kernel-module-management-2.6.0.tgz
```

### 3. Update Helm Repository Index

```bash
helm repo index . --url https://github.com/davtech/kernel-module-management-helm/releases/download/v2.6.0/
```

### 4. Commit and Create Release

```bash
# Commit
git add default/Chart.yaml index.yaml
git commit -m "chore: bump chart version to v2.6.0"
git push

# Create GitHub release
gh release create v2.6.0 \
  ./kernel-module-management-2.6.0.tgz \
  --title "v2.6.0 - KMM Helm Chart" \
  --notes-file release-notes.md \
  --latest
```

### 5. Verify GitHub Pages

```bash
curl -s https://davtech.github.io/kernel-module-management-helm/index.yaml | grep version
```

## 🧪 Testing

### Lint and Template Tests

```bash
# Lint chart
helm lint default

# Render all templates
helm template test default

# Render specific template
helm template test default --show-only templates/deployment.yaml

# With custom values
helm template test default -f test-values.yaml
```

### Real Cluster Testing

```bash
# Create test cluster
kind create cluster --name kmm-test

# Install chart
helm install kmm default --namespace kmm-operator-system --create-namespace

# Verify
kubectl get pods -n kmm-operator-system
kubectl logs -n kmm-operator-system -l control-plane=controller --tail=100

# Test with Module CR
kubectl apply -f - <<EOF
apiVersion: kmm.sigs.x-k8s.io/v1beta1
kind: Module
metadata:
  name: test-module
spec:
  moduleLoader:
    container:
      modprobe:
        moduleName: test
EOF

# Cleanup
helm uninstall kmm --namespace kmm-operator-system
kind delete cluster --name kmm-test
```

## 🔍 Troubleshooting

### Sync Script Issues

**kustomize build fails:**
```bash
# Verify config directory exists in upstream
git clone https://github.com/kubernetes-sigs/kernel-module-management.git
cd kernel-module-management && git checkout v2.6.0
ls -la config/default/
```

**Wrong image tags after sync:**
```bash
# Check upstream Makefile for correct image tags
curl -sL https://raw.githubusercontent.com/kubernetes-sigs/kernel-module-management/v2.5.0/Makefile | grep IMAGE_TAG
```

### Chart Validation Errors

```bash
# Check template syntax
helm template test default --debug 2>&1 | grep -i error

# Validate YAML
yamllint default/values.yaml
```

## 🤝 Contributing

1. Fork and clone repository
2. Create feature branch from `main`
3. Make changes following Helm best practices
4. Test thoroughly (lint, template, real cluster)
5. Update documentation
6. Submit PR with clear description

## 📚 Resources

- **Helm Best Practices**: https://helm.sh/docs/chart_best_practices/
- **KMM Upstream**: https://github.com/kubernetes-sigs/kernel-module-management
- **Kustomize Docs**: https://kustomize.io/
- **yq Documentation**: https://github.com/mikefarah/yq

## ✅ Version Update Checklist

- [ ] Run `./sync_script.sh vX.Y.Z default`
- [ ] Review changes
- [ ] Update `Chart.yaml` version
- [ ] **Verify image tags in values.yaml** (check upstream Makefile)
- [ ] Run `helm lint default`
- [ ] Test in real cluster
- [ ] Package: `helm package default`
- [ ] Update index: `helm repo index .`
- [ ] Commit and push
- [ ] Create GitHub release
- [ ] Verify GitHub Pages updates
# Kernel Module Management Helm Charts

This repository contains Helm charts for the [Kernel Module Management (KMM)](https://github.com/kubernetes-sigs/kernel-module-management) operator.

## Project Structure

```
.
├── sync_script.sh                 # Automated sync script for upstream updates
├── README.md                      # Project documentation
├── USAGE.md                       # This file - usage guide
├── default/                       # Default installation variant (Helm chart)
└── default-hub/                   # Hub installation variant (future Helm chart)
```

## Quick Start

### Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- (For sync script) kustomize, yq, git

### Install the Chart

```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace
```

### Customize Installation

Create a `custom-values.yaml` file:


```yaml
# custom-values.yaml
controllerManager:
  replicas: 2
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  logLevel: 3  # Increase log verbosity

kmodManager:
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
```

Install with custom values:

```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --create-namespace \
  -f custom-values.yaml
```

## Configuration Options

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controllerManager.replicas` | Number of operator replicas | `1` |
| `controllerManager.image.tag` | Operator image tag | `v2.5.0` |
| `controllerManager.resources` | Resource limits/requests | See values.yaml |
| `controllerManager.logLevel` | Log verbosity (0-5) | `2` |
| `kmodManager.image.tag` | Kmod worker image tag | `v2.5.0` |
| `webhook.enabled` | Enable admission webhooks | `true` |
| `global.imageRegistry` | Override image registry | `""` |

For a complete list of parameters, see the [chart README](default/README.md).

## Chart Variants

This repository supports multiple installation variants:

### default
Standard installation with the KMM operator managing kernel modules directly.

**Directory:** `default/`

### default-hub (planned)
Hub-based installation for multi-cluster management scenarios.

**Directory:** `default-hub/` (to be created)

## Upgrading

### Upgrade the Helm Release

```bash
helm upgrade kmm-operator ./default \
  --namespace kmm-operator-system
```

### Sync with Upstream Version

Use the automated sync script to update the chart with a new upstream version:

```bash
./sync_script.sh v2.6.0 default
```

**What the script does:**
1. ✅ Clones the upstream repository at the specified tag
2. ✅ Renders Kubernetes manifests using kustomize
3. ✅ Extracts CRDs to `crds/` directory (named by CRD name)
4. ✅ Splits Kubernetes resources by kind into separate template files
5. ✅ Applies Helm templating (namespaces, conditional rendering)
6. ✅ Updates `Chart.yaml` with new appVersion

**After syncing:**
1. Review changes: `git diff default/`
2. Test the chart: `helm lint` and `helm template`
3. Update chart `version` in `Chart.yaml` if needed
4. Commit changes

### Example: Syncing a New Version

```bash
# Sync default variant to v2.6.0
./sync_script.sh v2.6.0 default

# Review changes
git diff default/

# Test the chart
helm lint default
helm template test default

# Update Chart.yaml version manually
# Then commit
git add default/
git commit -m "Update default chart to upstream v2.6.0"
```

## Uninstallation

```bash
helm uninstall kmm-operator --namespace kmm-operator-system
```

**Note:** CRDs are not automatically removed by Helm. To remove them:


```bash
kubectl delete crd modules.kmm.sigs.x-k8s.io
kubectl delete crd modulebuildsignconfigs.kmm.sigs.x-k8s.io
kubectl delete crd moduleimagesconfigs.kmm.sigs.x-k8s.io
kubectl delete crd nodemodulesconfigs.kmm.sigs.x-k8s.io
kubectl delete crd preflightvalidations.kmm.sigs.x-k8s.io
```

## Development

### Prerequisites for Sync Script

The `sync_script.sh` requires the following tools:

- **git** - Clone upstream repository
- **kustomize** - Render Kubernetes manifests
- **yq** - Process YAML files
- **bash** - Shell script execution

Install required tools:

```bash
# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### Testing the Chart

**Lint the chart:**
```bash
helm lint default
```

**Dry-run installation:**
```bash
helm install kmm-operator ./default \
  --namespace kmm-operator-system \
  --dry-run --debug
```

**Template rendering:**
```bash
helm template test ./default > rendered.yaml
```

### Directory Structure Explained

- **`default/`** - Default installation variant (this IS the Helm chart)
  - **`Chart.yaml`** - Chart metadata (name, version, appVersion)
  - **`values.yaml`** - Default configuration values
  - **`templates/`** - Kubernetes resource templates (split by kind)
    - **`_helpers.tpl`** - Helm template helper functions
    - **`namespace.yaml`** - Namespace resources
    - **`serviceaccount.yaml`** - ServiceAccount resources
    - **`role.yaml`** / **`rolebinding.yaml`** - RBAC Role resources
    - **`clusterrole.yaml`** / **`clusterrolebinding.yaml`** - RBAC ClusterRole resources
    - **`service.yaml`** - Service resources
    - **`deployment.yaml`** - Deployment resources
    - **`certificate.yaml`** / **`issuer.yaml`** - cert-manager resources
    - **`validatingwebhookconfiguration.yaml`** - Webhook configuration
  - **`crds/`** - CustomResourceDefinitions (applied first, named by CRD name)
  - **`README.md`** - Chart-specific documentation

### Creating a New Variant

To add a new installation variant (e.g., `default-hub`):

1. **Create directory structure:**
   ```bash
   mkdir -p default-hub/{templates,crds}
   ```

2. **Copy base files:**
   ```bash
   cp default/{Chart.yaml,values.yaml,.helmignore,README.md} default-hub/
   cp default/templates/_helpers.tpl default-hub/templates/
   ```

3. **Modify Chart.yaml:**
   Update the name and description to reflect the variant.

4. **Run sync script:**
   ```bash
   ./sync_script.sh v2.5.0 default-hub
   ```

5. **Customize values.yaml:**
   Adjust default values for the specific variant needs.

## Troubleshooting

### Chart Validation Errors

If `helm lint` shows errors, check:
- YAML syntax in templates
- Required values in values.yaml
- Template function references in _helpers.tpl

### Sync Script Issues

**Problem:** Script fails to clone repository
```bash
# Solution: Check tag exists
git ls-remote --tags https://github.com/kubernetes-sigs/kernel-module-management.git | grep v2.5.0
```

**Problem:** kustomize build fails
```bash
# Solution: Verify config directory exists in upstream
# Check available variants at: https://github.com/kubernetes-sigs/kernel-module-management/tree/main/config
```

**Problem:** yq not found
```bash
# Solution: Ensure yq is installed and in PATH
which yq
yq --version
```

### Check Operator Logs

```bash
kubectl logs -n kmm-operator-system -l control-plane=controller-manager --tail=100
```

### Verify CRDs Installation

```bash
kubectl get crds | grep kmm
```

## Contributing

Contributions are welcome! Please:

1. Test changes with `helm lint` and `helm template`
2. Update documentation if configuration options change
3. Run sync script to verify automation still works
4. Follow Helm best practices

## Resources

- [KMM Documentation](https://kubernetes-sigs.github.io/kernel-module-management/)
- [KMM GitHub](https://github.com/kubernetes-sigs/kernel-module-management)
- [Helm Documentation](https://helm.sh/docs/)
- [Kustomize Documentation](https://kustomize.io/)

## License

This repository follows the same license as the upstream KMM project (Apache 2.0).


O chart foi validado com sucesso:

```bash
# Lint passou sem erros
helm lint ./default
# ✅ 1 chart(s) linted, 0 chart(s) failed

# Template renderiza corretamente
helm template test ./default
# ✅ Templates gerados com sucesso
```

## Próximos passos

1. **Testar em ambiente de desenvolvimento:**
   ```bash
   # Criar um cluster local (kind, minikube, etc)
   kind create cluster --name kmm-test
   
   # Instalar o chart
   helm install kmm-operator ./default
   
   # Verificar os recursos
   kubectl get all -n kube-system | grep kmm
   kubectl get crds | grep kmm
   ```

2. **Ajustar valores conforme necessário** no `values.yaml`

3. **Criar pipelines CI/CD** para automatizar testes e deployment

4. **Adicionar testes** (helm test) se necessário

## Recursos adicionais

- **Documentação oficial:** https://github.com/kubernetes-sigs/kernel-module-management
- **Helm docs:** https://helm.sh/docs/
- **Kustomize docs:** https://kustomize.io/

## Suporte

Para questões ou problemas:
- Abra uma issue no repositório
- Consulte a documentação do KMM upstream
- Verifique os logs do operator: `kubectl logs -n kube-system deployment/kmm-operator`
