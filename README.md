# Kernel Module Management Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.23%2B-blue.svg)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.8%2B-blue.svg)](https://helm.sh/)

Helm chart for the [Kernel Module Management (KMM)](https://github.com/kubernetes-sigs/kernel-module-management) operator v2.6.0.

## ✨ Features

- 🎯 **5 Fully Parameterized Images**: Controller, Webhook, Worker, Sign and Build (Kaniko)
- 🌐 **Global Registry Support**: Centralized override via `global.imageRegistry`
- 📦 **5 CRDs Included**: Module, NodeModulesConfig, ManagedClusterModule, ModuleLoader, PreflightValidation
- 🔄 **Automated Sync Script**: Synchronization with upstream KMM releases
- 🤖 **CI/CD Ready**: GitHub Actions with helm lint and chart-testing

## 📥 Installation

### Via Helm Repository

```bash
helm repo add kmm-helm https://davtech.github.io/kernel-module-management-helm/
helm repo update
helm install kmm kmm-helm/kernel-module-management
```

### Via Local Clone

```bash
git clone https://github.com/davtech/kernel-module-management-helm.git
cd kernel-module-management-helm
helm install kmm ./default --create-namespace --namespace kmm-operator-system
```

### Via Release Package

```bash
wget https://github.com/davtech/kernel-module-management-helm/releases/download/v2.6.0/kernel-module-management-2.6.0.tgz
helm install kmm kernel-module-management-2.6.0.tgz
```

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** → Get started in 5 minutes
- **[default/README.md](default/README.md)** → Complete chart documentation and configuration
- **[USAGE.md](USAGE.md)** → For developers and maintainers
- **[Upstream KMM Docs](https://kubernetes-sigs.github.io/kernel-module-management/)** → Official operator documentation

## 🔧 Quick Configuration Example

```yaml
# Custom registry for all images
global:
  imageRegistry: my-private-registry.io

# Scale replicas
controller:
  replicas: 3
webhook:
  replicas: 2
```

See [default/README.md](default/README.md) for all configuration options.

## 🎯 Based on

- **KMM Upstream**: [v2.6.0](https://github.com/kubernetes-sigs/kernel-module-management/releases/tag/v2.6.0)
- **Kubernetes**: 1.23+
- **Helm**: 3.8+

## 🔄 Upgrading

```bash
# Upgrade Helm release
helm upgrade kmm kmm-helm/kernel-module-management

# Or sync with new upstream version (for maintainers)
./sync_script.sh v2.6.0
```

See [USAGE.md](USAGE.md) for detailed upgrade and sync instructions.

## 🙏 Contributing

Contributions are welcome! See [USAGE.md](USAGE.md) for development workflow and sync script usage.

## 📄 License

Apache License 2.0 - See [LICENSE](https://www.apache.org/licenses/LICENSE-2.0)

## 🔗 Links

- **Repository**: https://github.com/davtech/kernel-module-management-helm
- **Helm Repo**: https://davtech.github.io/kernel-module-management-helm/
- **Release**: https://github.com/davtech/kernel-module-management-helm/releases/tag/v2.6.0
- **Upstream KMM**: https://github.com/kubernetes-sigs/kernel-module-management
