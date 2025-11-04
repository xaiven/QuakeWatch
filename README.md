
![QuakeWatch](static/experts-logo.svg)

# 🌍 QuakeWatch — Full DevOps Pipeline Project

**QuakeWatch** is a Python Flask application that monitors real‑time and historical earthquake data using the public USGS API — and is fully deployed and automated using modern DevOps tooling.

This repository demonstrates real‑world DevOps practices including:

✅ Docker containerization  
✅ Kubernetes deployment (Minikube)  
✅ Helm chart packaging  
✅ Git branching workflows & Pull Requests  
✅ CI/CD with GitHub Actions  
✅ Image publishing to Docker Hub  
✅ GitOps with ArgoCD  
✅ Prometheus & Grafana observability  
✅ Alerts & dashboards  
✅ CronJob for scheduled tasks  
✅ HPA for auto‑scaling

This project simulates a **production‑grade cloud‑native microservice** pipeline.

---

## 📁 Project Structure

```
QuakeWatch/
├── app.py
├── requirements.txt
├── charts/quakewatch/        # Helm chart for Kubernetes deployment
├── scripts/fetch_quakes.py   # CronJob script for periodic data fetch
├── .github/workflows/        # CI/CD pipeline
├── docs/GITOPS_MONITORING.md
└── kube/                     # (if present) manifests used before Helm
```

---

## 🚀 Features

| Category | Details |
|---|---|
Earthquake monitoring | Real‑time & historical USGS data |
Visualization | Interactive web dashboard |
Containerization | Docker + Docker Hub publishing |
Orchestration | Kubernetes Deployment + Service |
Scaling | Kubernetes HPA (CPU autoscaling) |
Scheduling | CronJob fetches quakes hourly |
GitOps | Automatic sync via ArgoCD |
Observability | Prometheus metrics + Grafana dashboards |
CI/CD | GitHub Actions: build → lint → push → deploy |
Alerts | Prometheus alert rules for failures |
Port‑forward automation | start script to restore system after reboot |

---

## 🐳 Docker Usage

```bash
docker build -t quakewatch:latest .
docker run -d -p 5000:5000 quakewatch:latest
```

Docker Hub Image: `docker.io/<your-user>/quakewatch`

---

## ☸️ Kubernetes Deployment via Helm

```bash
helm upgrade --install quakewatch charts/quakewatch \
  --namespace quakewatch --create-namespace
```

### Check App
```bash
kubectl get pods -n quakewatch
kubectl port-forward -n quakewatch deployment/quakewatch 8080:5000
```

Open: http://localhost:8080

---

## 🤖 CI/CD (GitHub Actions)

Pipeline stages:

| Stage | Description |
|---|---|
✅ Lint Python code (pylint) |
✅ Matrix test (3.10, 3.11, 3.12) |
✅ Build Docker image |
✅ Push to Docker Hub |
✅ Helm deploy (via ArgoCD auto‑sync) |

---

## 🔁 GitOps with ArgoCD

| Feature | Status |
|---|---|
Auto‑sync | ✅
Self‑heal | ✅
Pruning | ✅
Helm automation | ✅

Access UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## 📊 Monitoring

### Prometheus
Scrapes `/metrics` endpoint powered by `prometheus_flask_exporter`.

### Grafana Dashboard Panels
| Metric | Source |
|---|---|
HTTP request rate | `flask_http_request_total` |
Latency P95 | histogram metrics |
Error rate | `flask_http_request_exceptions_total` |
CPU usage | K8s metrics |
Memory usage | K8s metrics |
Pod restarts | node exporter |
CronJob failures | kube-state-metrics |

---

## 🚨 Alerts

Example alert:
```
alert: HighErrorRate
expr: rate(flask_http_request_exceptions_total[5m]) > 0.1
for: 2m
```
Triggers if app error rate is high — signaling a possible outage.

---

## 🏁 Auto‑Start Script After Reboot

Run this after reboot:

```
./start_quakewatch.sh
```

Restores:
✅ Minikube  
✅ ArgoCD  
✅ QuakeWatch  
✅ Prometheus  
✅ Grafana  

---

## 🎯 End‑to‑End Architecture

```
Developer → GitHub → CI/CD → Docker Hub → ArgoCD → K8s → Prometheus → Grafana
```

---

## 👏 Credits

Built by **@xaiven** as a full DevOps practice project.  
Demonstrates real‑world pipeline skills, GitOps, monitoring and automation.

---

