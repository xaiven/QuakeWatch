
# 🌍 QuakeWatch — Full DevOps Project (All 5 Phases)

**QuakeWatch** is a Flask‑based web application that visualizes real‑time and historical earthquake data using the USGS API.  
This documentation covers the complete DevOps lifecycle from **containerization to GitOps**.

---

## 🧩 Phase 1 — Docker Foundation

### Objective
Containerize the QuakeWatch application and push it to Docker Hub.

### Steps
```bash
# Clone source code
git clone https://github.com/EduardUsatchev/QuakeWatch.git
cd QuakeWatch

# Create Docker image
docker build -t alexsay23/quakewatch:latest .

# Run locally
docker run -d -p 5000:5000 alexsay23/quakewatch:latest

# Push to Docker Hub
docker login
docker push alexsay23/quakewatch:latest
```

---

## ☸️ Phase 2 — Kubernetes Deployment

### Objective
Deploy QuakeWatch to Kubernetes (Minikube or K3s) with full manifests.

### Key Components
- **Deployment** with liveness & readiness probes  
- **Service** (ClusterIP / NodePort)
- **ConfigMap** for environment variables
- **PersistentVolume / PersistentVolumeClaim**
- **CronJob** for periodic updates
- **HorizontalPodAutoscaler** for scaling

### Commands
```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pv.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/cronjob.yaml
kubectl apply -f k8s/hpa.yaml

kubectl get pods,svc,cm,pvc,hpa -n quakewatch
kubectl port-forward svc/quakewatch-service 5000:5000
```

---

## ⚙️ Phase 3 — Automation & CI/CD

### Objective
Automate packaging, testing, and deployment.

### Steps

#### 1. Helm Packaging
```bash
cd charts/quakewatch
helm package .
helm push quakewatch-0.1.0.tgz oci://ghcr.io/alexsay23/helm-charts
```

#### 2. Git Version Control
- Create feature branches (`feature/api-endpoint`, `feature/ui`)
- Merge using PRs and resolve conflicts
- Tag releases (e.g., `v1.0.0`)

#### 3. GitHub Actions CI/CD
Typical `.github/workflows/ci.yml` stages:
```yaml
name: CI/CD
on: [push, pull_request]

jobs:
  build-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.9, 3.10]
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Lint
        run: pylint app.py
      - name: Build Docker image
        run: docker build -t alexsay23/quakewatch:${{ github.sha }} .
```

---

## 📊 Phase 4 — Observability

### Objective
Add metrics and dashboards.

### Steps
1. Install **Prometheus** and **Grafana** in cluster:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add grafana https://grafana.github.io/helm-charts
   helm install prometheus prometheus-community/kube-prometheus-stack
   helm install grafana grafana/grafana
   ```

2. Access Grafana:
   ```bash
   kubectl port-forward svc/grafana 3000:80 -n default
   ```

3. Create panels:
   - Pod restarts:
     ```
     increase(kube_pod_container_status_restarts_total{pod=~"quakewatch-.*"}[5m])
     ```
   - CPU usage:
     ```
     sum by (pod) (rate(container_cpu_usage_seconds_total{pod=~"quakewatch-.*"}[5m]))
     ```

---

## 🚀 Phase 5 — Infrastructure as Code & GitOps

### Objective
Provision AWS resources and automate deployments with ArgoCD.

### AWS Infrastructure
- Region: `us-east-1`
- Instance: `t3.micro` with swap enabled
- VPC + Subnets + Security Groups
- EC2 running **K3s server**

### Terraform (high-level steps)
```bash
cd tf-k3s-quakewatch
terraform init
terraform apply -auto-approve
```

### K3s Cluster Setup
After EC2 is ready, connect via SSH:
```bash
ssh -i quakewatch-key.pem ubuntu@<ec2-public-ip>
sudo systemctl status k3s
kubectl get nodes
```

### ArgoCD GitOps
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Sync the **Helm chart** repo and watch deployments roll out automatically.

---

## ✅ Final Verification

```bash
kubectl get pods,svc -A
kubectl get hpa
kubectl logs -l app=quakewatch
```

Access the app via:
```
http://<EC2-public-IP>:5000
```

---

**Author:** Alex Sayenko  
**Repository:** https://github.com/xaiven/QuakeWatch  
**Helm Chart:** ghcr.io/alexsay23/helm-charts/quakewatch:0.1.0
