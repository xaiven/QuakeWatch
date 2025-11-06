#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting QuakeWatch DevOps Environment..."

# -------- helpers --------
kill_on_port() {
  local PORT="$1"
  if command -v lsof >/dev/null 2>&1; then
    PIDS=$(lsof -ti :"$PORT" || true)
    if [ -n "${PIDS:-}" ]; then
      echo "🧹 Freeing port $PORT (killing: $PIDS)"
      kill -9 $PIDS || true
    fi
  else
    # Fallback if lsof isn't available
    pkill -f "kubectl port-forward.*:$PORT" 2>/dev/null || true
  fi
}

ns_ensure() {
  local NS="$1"
  kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"
}

wait_for_selector_ready() {
  local NS="$1"
  local SELECTOR="$2"
  local TIMEOUT="${3:-180s}"
  echo "⏳ Waiting for pods ($SELECTOR) in namespace '$NS' to be Ready..."
  kubectl wait --for=condition=Ready pod -l "$SELECTOR" -n "$NS" --timeout="$TIMEOUT" || true
}

# ---------- START KUBERNETES CLUSTER ----------
echo "📦 Starting Minikube..."
minikube start --driver=docker --memory=6000 --cpus=4

echo "⛓ Setting kubectl context to minikube"
kubectl config use-context minikube

# ---------- NAMESPACES HEALTH ----------
echo "📂 Ensuring namespaces exist..."
ns_ensure quakewatch
ns_ensure monitoring
# ArgoCD namespace only if you use ArgoCD
ns_ensure argocd

# ---------- OPTIONAL READINESS HINTS ----------
# Tweak these selectors if your labels differ
wait_for_selector_ready quakewatch "app.kubernetes.io/name=quakewatch" 180s
# If using kube-prometheus-stack (common service names below)
# These waits won't fail the script thanks to '|| true' in wait function
wait_for_selector_ready monitoring "app.kubernetes.io/name=grafana" 180s
wait_for_selector_ready monitoring "app.kubernetes.io/name=prometheus" 180s
wait_for_selector_ready argocd "app.kubernetes.io/name=argocd-server" 180s

# ---------- START ARGOCD PORT FORWARD ----------
# ArgoCD now on LOCAL 8081 to avoid clash with QuakeWatch (8080)
echo "🔄 Starting ArgoCD port-forward (local 8081 -> svc/argocd-server:443)"
kill_on_port 8081
if kubectl get svc argocd-server -n argocd >/dev/null 2>&1; then
  kubectl port-forward svc/argocd-server -n argocd 8081:443 >/dev/null 2>&1 &
else
  echo "⚠️  ArgoCD service not found in 'argocd' namespace. Skipping ArgoCD port-forward."
fi

# ---------- START QUAKEWATCH APP PORT-FORWARD ----------
# QuakeWatch stays on LOCAL 8080
echo "🌍 Starting QuakeWatch port-forward (local 8080 -> pod:5000)"
kill_on_port 8080
# Forward the first matching Ready pod (falls back gracefully if not found)
POD=$(kubectl get pods -n quakewatch -l app.kubernetes.io/name=quakewatch \
  -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || true)
if [ -n "${POD:-}" ]; then
  kubectl port-forward -n quakewatch "$POD" 8080:5000 >/dev/null 2>&1 &
else
  echo "⚠️  No QuakeWatch pod found in 'quakewatch'. Did the Deployment start?"
fi

# ---------- START PROMETHEUS PORT-FORWARD ----------
echo "📊 Starting Prometheus port-forward (local 9090 -> svc:9090)"
kill_on_port 9090
if kubectl get svc monitoring-kube-prometheus-prometheus -n monitoring >/dev/null 2>&1; then
  kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 &
else
  echo "⚠️  Prometheus service not found in 'monitoring'. Skipping Prometheus port-forward."
fi

# ---------- START GRAFANA PORT-FORWARD ----------
echo "📈 Starting Grafana port-forward (local 3000 -> svc:80)"
kill_on_port 3000
if kubectl get svc monitoring-grafana -n monitoring >/dev/null 2>&1; then
  kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 >/dev/null 2>&1 &
else
  echo "⚠️  Grafana service not found in 'monitoring'. Skipping Grafana port-forward."
fi

echo "✅ All services running (if installed):"
echo "🌐 QuakeWatch  -> http://localhost:8080"
echo "🛠 ArgoCD      -> http://localhost:8081 (UI login required)"
echo "📡 Prometheus  -> http://localhost:9090"
echo "🎛 Grafana     -> http://localhost:3000"
echo ""
echo "🔥 Environment ready!"
