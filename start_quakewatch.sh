#!/bin/bash

echo "🚀 Starting QuakeWatch DevOps Environment..."

echo "📦 Starting Minikube..."
minikube start --cpus=4 --memory=6g

echo "🔄 Setting kubectl context to minikube"
kubectl config use-context minikube

echo "📁 Ensuring required namespaces exist..."
for ns in argocd quakewatch monitoring; do
  kubectl get ns $ns >/dev/null 2>&1 || kubectl create namespace $ns
done

echo "✅ Checking ArgoCD status..."
kubectl get pods -n argocd 2>/dev/null | grep argocd-server >/dev/null
if [ $? -ne 0 ]; then
  echo "⚙️ Installing ArgoCD..."
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

echo "⌛ Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server -n argocd

echo "🔁 Refreshing ArgoCD sync..."
kubectl annotate application quakewatch -n argocd argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null

echo "🚀 Waiting for quakewatch pods..."
kubectl wait --for=condition=available deploy/quakewatch -n quakewatch --timeout=120s 2>/dev/null

echo "✅ Environment ready!"
echo ""
echo "🌐 ArgoCD UI: https://localhost:8080 (run port-forward below)"
echo "🌐 QuakeWatch App: http://localhost:8080 (after app port-forward)"
echo ""
echo "To access UIs run in separate terminals:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "kubectl port-forward \  $(kubectl get pods -n quakewatch -l app.kubernetes.io/name=quakewatch -o jsonpath='{.items[0].metadata.name}') \  -n quakewatch 8080:5000"
