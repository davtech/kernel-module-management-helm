#!/bin/bash
# Sync script for Kernel Module Management Helm Charts
# Usage: ./sync_script.sh [TAG] [VARIANT]
# Examples:
#   ./sync_script.sh v2.5.0 default
#   ./sync_script.sh v2.6.0 default-hub

set -uo pipefail

# Note: Not using 'set -e' to allow graceful error handling in CRD extraction

# Configuration
UPSTREAM_REPO="https://github.com/kubernetes-sigs/kernel-module-management.git"
UPSTREAM_TAG="${1:-v2.5.0}"
VARIANT="${2:-default}"
WORK_DIR=$(mktemp -d)
CHART_DIR="${VARIANT}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
        log_info "Cleaned up temporary directory"
    fi
}

trap cleanup EXIT

# Validate variant
if [ ! -d "${VARIANT}" ] && [ ! -f "config/${VARIANT}.yaml" ]; then
    log_error "Variant '${VARIANT}' not found. Available variants: default, default-hub"
    exit 1
fi

log_info "Starting sync for variant: ${VARIANT}, tag: ${UPSTREAM_TAG}"

# Limpar arquivos antigos
log_info "Cleaning old templates and CRDs..."
rm -f "$CHART_DIR/templates"/*.yaml
rm -f "$CHART_DIR/crds"/*.yaml

# 1. Clone upstream repository at target tag
log_info "Cloning upstream repository..."
if ! git clone --depth 1 --branch "$UPSTREAM_TAG" "$UPSTREAM_REPO" "$WORK_DIR/kmm" 2>/dev/null; then
    log_error "Failed to clone repository. Check if tag ${UPSTREAM_TAG} exists."
    exit 1
fi

# 2. Render kustomize manifests
log_info "Rendering kustomize manifests from config/${VARIANT}..."
if [ ! -d "$WORK_DIR/kmm/config/${VARIANT}" ]; then
    log_error "Config directory 'config/${VARIANT}' not found in upstream repository"
    exit 1
fi

kustomize build "$WORK_DIR/kmm/config/${VARIANT}" > "$WORK_DIR/all.yaml"

# 3. Prepare chart directories
log_info "Preparing chart directory structure..."
mkdir -p "$CHART_DIR/templates" "$CHART_DIR/crds"

# 4. Extract CRDs separately (they go in crds/ not templates/)
log_info "Extracting CustomResourceDefinitions..."
CRD_COUNT=0

# Extract each CRD to a temporary file first
yq eval-all 'select(.kind == "CustomResourceDefinition")' "$WORK_DIR/all.yaml" > "$WORK_DIR/crds.yaml"

if [ -s "$WORK_DIR/crds.yaml" ]; then
    # Split into individual files using csplit
    ORIGINAL_DIR=$(pwd)
    cd "$CHART_DIR/crds" || exit 1
    csplit --quiet --prefix="crd-" --suffix-format='%02d.yaml' "$WORK_DIR/crds.yaml" '/^---$/' '{*}' 2>/dev/null || true
    
    # Rename each CRD file based on its metadata.name
    for crd_file in crd-*.yaml; do
        if [ -f "$crd_file" ] && [ -s "$crd_file" ]; then
            # Remove leading --- if present
            sed -i '/^---$/d' "$crd_file" 2>/dev/null || true
            
            CRD_NAME=$(yq eval '.metadata.name' "$crd_file" 2>/dev/null | tr -d '\n')
            if [ "$CRD_NAME" != "null" ] && [ -n "$CRD_NAME" ]; then
                mv "$crd_file" "${CRD_NAME}.yaml"
                ((CRD_COUNT++))
                log_info "  Extracted CRD: ${CRD_NAME}"
            else
                rm -f "$crd_file"
            fi
        fi
    done
    cd "$ORIGINAL_DIR" || exit 1
fi

log_info "Extracted ${CRD_COUNT} CRDs"

# 5. Extract non-CRD resources to templates, split by kind
log_info "Extracting Kubernetes resources to templates..."

# Resources to exclude (Helm manages these)
EXCLUDED_KINDS="Namespace"

# First extract all non-CRD resources, excluding Namespace
yq eval-all 'select(.kind != "CustomResourceDefinition" and .kind != "Namespace")' "$WORK_DIR/all.yaml" \
  > "$WORK_DIR/resources.yaml"

log_info "Excluding resource kinds: ${EXCLUDED_KINDS}"

# Split resources by kind
log_info "Splitting resources by kind..."
RESOURCE_COUNT=0

# Get list of unique kinds
KINDS=$(yq eval '.kind' "$WORK_DIR/resources.yaml" | sort -u | grep -v "^null$" | grep -v "^---$")

for kind in $KINDS; do
    if [ -n "$kind" ]; then
        # Convert kind to lowercase for filename
        kind_lower=$(echo "$kind" | tr '[:upper:]' '[:lower:]')
        output_file="$CHART_DIR/templates/${kind_lower}.yaml"
        
        # Extract all resources of this kind
        yq eval-all "select(.kind == \"$kind\")" "$WORK_DIR/resources.yaml" > "$output_file"
        
        if [ -s "$output_file" ]; then
            # Count resources in this file
            count=$(grep -c "^kind: $kind" "$output_file" || echo "1")
            ((RESOURCE_COUNT+=count))
            log_info "  Created ${kind_lower}.yaml (${count} resource(s))"
        else
            rm -f "$output_file"
        fi
    fi
done

log_info "Extracted ${RESOURCE_COUNT} Kubernetes resources"

# 6. Apply Helm templating to all resource files
log_info "Applying Helm templating..."
for resource_file in "$CHART_DIR/templates"/*.yaml; do
    if [ -f "$resource_file" ] && [ "$(basename "$resource_file")" != "_helpers.tpl" ]; then
        # Replace hardcoded namespace with Helm template
        sed -i 's/namespace: kmm-operator-system/namespace: {{ .Release.Namespace }}/g' "$resource_file"
        
        log_info "  Templated $(basename "$resource_file")"
    fi
done

# 7. Update Chart.yaml version info
if [ -f "$CHART_DIR/Chart.yaml" ]; then
    log_info "Updating Chart.yaml with new appVersion..."
    # Remove 'v' prefix from tag for appVersion
    APP_VERSION="${UPSTREAM_TAG#v}"
    sed -i "s/^appVersion: .*/appVersion: \"${APP_VERSION}\"/" "$CHART_DIR/Chart.yaml"
fi

log_info "Sync completed successfully!"
log_info ""
log_info "Summary:"
log_info "  - ${CRD_COUNT} CRDs extracted to crds/"
log_info "  - ${RESOURCE_COUNT} resources extracted to templates/"
log_info "  - Excluded kinds: ${EXCLUDED_KINDS} (managed by Helm)"
log_info ""
log_info "Next steps:"
log_info "  1. Review changes: git diff ${CHART_DIR}"
log_info "  2. Test the chart: helm lint ${CHART_DIR}"
log_info "  3. Verify templates render: helm template test ${CHART_DIR}"
log_info "  4. Update version in Chart.yaml if needed"
log_info "  5. Commit changes: git add ${CHART_DIR} && git commit -m 'Update ${VARIANT} chart to ${UPSTREAM_TAG}'"
