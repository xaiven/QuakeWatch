#!/bin/bash
#THIS IS FOR LOCAL TEST RUN ONLY
set -e

echo "✅ Starting Docker Desktop & k3d cluster"
k3d cluster start qw || k3d cluster create qw --agents 1 --servers 1

echo "✅ Switching kubectl context to k3d"
kubectl config use-context k3d-qw

echo "✅ Ensuring namespace exists"
kubectl create ns quakewatch --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Deploying QuakeWatch via Helm"
helm upgrade --install quakewatch ./charts/quakewatch \
  --namespace quakewatch --create-namespace \
  --set image.repository=ghcr.io/xaiven/quakewatch \
  --set image.tag=0.1.0 \
  --wait

echo "✅ Installing ArgoCD (if not installed)"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "✅ Waiting for ArgoCD server..."
kubectl rollout status deploy/argocd-server -n argocd

echo "🎟 ArgoCD admin password:"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo

echo "✅ Deploying ArgoCD App of Apps (QuakeWatch)"
kubectl apply -f gitops/argocd-app-quakewatch.yaml

echo "✅ Installing monitoring stack"
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --wait

echo ""
echo "🎉 All services started successfully!"
echo "----------------------------------------"
echo "🌍 QuakeWatch App: use kubectl port-forward or LoadBalancer"
echo "🎛 ArgoCD UI: run   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "📊 Grafana UI: run   kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "----------------------------------------"
