minikube start
#if u don't have it > kubectl create namespace quakewatch
docker login
docker compose up -d
kubectl apply -f k8s/ -n quakewatch # reapply all .yaml files from /k8s
docker push alexsay23/quakewatch:1.0 # push image to docker hub
kubectl rollout status deployment/quakewatch-deployment -n quakewatch # check rollout

#Confirm Deployments:
kubectl get pods -n quakewatch
kubectl get svc -n quakewatch
kubectl get hpa -n quakewatch
kubectl get cronjob -n quakewatch


# Use minikube context
kubectl config use-context minikube
kubectl get nodes

# Login GHCR
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
echo "$GHCR_TOKEN" | helm registry login ghcr.io -u "$GHCR_USERNAME" --password-stdin

#Helm Re-Deploy
helm upgrade --install quakewatch oci://ghcr.io/xaiven/helm-charts/quakewatch \
  --version 0.1.0 \
  --namespace quakewatch --create-namespace \
  --set image.repository=ghcr.io/xaiven/quakewatch \
  --set image.tag=0.1.0

  # Check
kubectl get pods -n quakewatch

# namespace for ArgoCD and monitoring
kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -

# install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deploy/argocd-server -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# open: https://localhost:8080

# Initial PASSWORD # user = admin
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo

kubectl apply -f gitops/argocd-app-quakewatch.yaml

# Prometheus & Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
kubectl get pods -n monitoring

kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
# Username: admin
# Password: kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090

###### AFTER REBOOT:::
# 1. Start Docker Desktop (manually)
# 2. Start WSL (in Ubuntu terminal)
k3d cluster start qw
kubectl get nodes   # just to confirm cluster is running
# 3. Run your automation script
./start_quakewatch.sh # To start QuakeWatch, Grafana, Prometheus, ArgoCD ...





