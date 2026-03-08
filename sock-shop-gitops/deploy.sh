#!/usr/bin/env bash
# ============================================================
# Sock Shop GitOps - Deployment Helper Script
# ============================================================
set -euo pipefail

NAMESPACE="sock-shop"
ARGOCD_NAMESPACE="argocd"
CHART_DIR="$(cd "$(dirname "$0")/charts" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

SERVICES=(
  front-end
  catalogue
  catalogue-db
  carts
  carts-db
  orders
  orders-db
  shipping
  payment
  user
  user-db
  queue-master
  rabbitmq
  session-db
)

# ── Helm only (no ArgoCD) ──────────────────────────────────
helm_install_all() {
  info "Creating namespace: ${NAMESPACE}"
  kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

  for svc in "${SERVICES[@]}"; do
    chart="${CHART_DIR}/${svc}"
    if [ -d "$chart" ]; then
      info "Installing: ${svc}"
      helm upgrade --install "${svc}" "${chart}" \
        --namespace "${NAMESPACE}" \
        --wait --timeout 3m \
        --atomic
    else
      warn "Chart not found, skipping: ${svc}"
    fi
  done
  info "All services deployed!"
}

# ── ArgoCD bootstrap ──────────────────────────────────────
argocd_bootstrap() {
  info "Applying ArgoCD namespace and project..."
  kubectl apply -f argocd/namespace.yaml
  kubectl apply -f argocd/appproject.yaml

  info "Deploying App of Apps..."
  kubectl apply -f argocd/app-of-apps.yaml

  info "Waiting for ArgoCD to sync..."
  sleep 5

  if command -v argocd &>/dev/null; then
    argocd app wait sock-shop-apps --timeout 300 || warn "Timeout waiting - check ArgoCD UI"
  else
    warn "argocd CLI not found. Monitor sync via ArgoCD UI."
  fi
}

# ── Status check ──────────────────────────────────────────
status() {
  info "Pods in ${NAMESPACE}:"
  kubectl get pods -n "${NAMESPACE}" -o wide

  echo ""
  info "Services:"
  kubectl get svc -n "${NAMESPACE}"

  if command -v argocd &>/dev/null; then
    echo ""
    info "ArgoCD App status:"
    argocd app list -p sock-shop 2>/dev/null || true
  fi
}

# ── Teardown ──────────────────────────────────────────────
teardown() {
  warn "Removing all Helm releases from ${NAMESPACE}..."
  for svc in "${SERVICES[@]}"; do
    helm uninstall "${svc}" -n "${NAMESPACE}" 2>/dev/null && info "Removed: ${svc}" || true
  done

  warn "Deleting namespace ${NAMESPACE}..."
  kubectl delete namespace "${NAMESPACE}" --ignore-not-found

  warn "Removing ArgoCD apps..."
  kubectl delete -f argocd/app-of-apps.yaml --ignore-not-found
  kubectl delete -f argocd/appproject.yaml --ignore-not-found
}

# ── Lint all charts ───────────────────────────────────────
lint_all() {
  info "Linting all charts..."
  for svc in "${SERVICES[@]}"; do
    chart="${CHART_DIR}/${svc}"
    if [ -d "$chart" ]; then
      helm lint "${chart}" && info "  ✓ ${svc}" || error "  ✗ ${svc}"
    fi
  done
}

# ── Template dry-run ─────────────────────────────────────
template_all() {
  local out_dir="${1:-/tmp/sock-shop-rendered}"
  mkdir -p "${out_dir}"
  info "Rendering all charts to ${out_dir}..."
  for svc in "${SERVICES[@]}"; do
    chart="${CHART_DIR}/${svc}"
    if [ -d "$chart" ]; then
      helm template "${svc}" "${chart}" \
        --namespace "${NAMESPACE}" \
        > "${out_dir}/${svc}.yaml"
      info "  rendered: ${svc}.yaml"
    fi
  done
}

# ── Main ─────────────────────────────────────────────────
usage() {
  echo "Usage: $0 {helm-install|argocd-bootstrap|status|teardown|lint|template}"
  echo ""
  echo "  helm-install      - Install all services directly via Helm (no ArgoCD)"
  echo "  argocd-bootstrap  - Bootstrap ArgoCD App-of-Apps"
  echo "  status            - Show current deployment status"
  echo "  teardown          - Remove all releases and namespace"
  echo "  lint              - Lint all Helm charts"
  echo "  template          - Render all templates (dry-run)"
}

case "${1:-help}" in
  helm-install)      helm_install_all ;;
  argocd-bootstrap)  argocd_bootstrap ;;
  status)            status ;;
  teardown)          teardown ;;
  lint)              lint_all ;;
  template)          template_all "${2:-}" ;;
  *)                 usage; exit 1 ;;
esac
