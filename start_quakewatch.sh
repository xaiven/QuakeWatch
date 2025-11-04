#!/usr/bin/env bash

echo "🚀 Starting QuakeWatch DevOps Environment..."

# ---------- START KUBERNETES CLUSTER ----------
echo "📦 Starting Minikube..."
minikube start --driver=docker --memory=6000 --cpus=4

echo "⛓ Setting kubectl context to minikube"
kubectl config use-context minikube

# ---------- NAMESPACES HEALTH ----------
echo "📂 Ensuring quakewatch & monitoring namespaces exist..."
kubectl get ns quakewatch >/dev/null 2>&1 || kubectl create ns quakewatch
kubectl get ns monitoring >/dev/null 2>&1 || kubectl create ns monitoring

# ---------- START ARGOCD PORT FORWARD ----------
echo "🔄 Starting ArgoCD port-forward (port 8080)"

# Kill existing forward
fwd=$(lsof -ti :8080)
if [ ! -z "$fwd" ]; then kill -9 $fwd; fi

kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &

# ---------- START QUakeWATCH APP PORT-FORWARD ----------
echo "🌍 Starting QuakeWatch app port-forward (port 5000 -> 8080)"

fwd=$(lsof -ti :8080)
if [ ! -z "$fwd" ]; then kill -9 $fwd; fi

POD=$(kubectl get pods -n quakewatch -l app.kubernetes.io/name=quakewatch -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward -n quakewatch $POD 8080:5000 >/dev/null 2>&1 &

# ---------- START PROMETHEUS PORT-FORWARD ----------
echo "📊 Starting Prometheus port-forward (port 9090)"

fwd=$(lsof -ti :9090)
if [ ! -z "$fwd" ]; then kill -9 $fwd; fi

kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 &

# ---------- START GRAFANA PORT-FORWARD ----------
echo "📈 Starting Grafana port-forward (port 3000)"

fwd=$(lsof -ti :3000)
if [ ! -z "$fwd" ]; then kill -9 $fwd; fi

kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 >/dev/null 2>&1 &

echo "✅ All services running:"
echo "🌐 QuakeWatch -> http://localhost:8080"
echo "🎛 Grafana -> http://localhost:3000"
echo "📡 Prometheus -> http://localhost:9090"
echo "🛠 ArgoCD -> http://localhost:8080 (UI login required)"
echo ""
echo "🔥 Environment ready!"
