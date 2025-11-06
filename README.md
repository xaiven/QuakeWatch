# 🌍 QuakeWatch – Complete DevOps Implementation

**QuakeWatch** is a full end-to-end DevOps project that demonstrates cloud-native deployment, automation, and observability practices.  
The application visualizes real-time and historical earthquake data from the USGS API using a Flask web server and Matplotlib-based charts.  

This project integrates **Terraform**, **Kubernetes (K3s)**, **Helm**, **CI/CD automation**, and **monitoring** tools like Prometheus and Grafana, all deployed in AWS.

---

## 🚀 Project Overview

The goal of QuakeWatch is to simulate a production-grade DevOps environment:
1. Infrastructure as Code with **Terraform**
2. Lightweight **Kubernetes (K3s)** cluster on AWS EC2
3. Application deployment using **Helm charts**
4. Continuous Delivery with **GitHub Actions**
5. Observability through **Prometheus & Grafana**
6. GitOps automation with **Argo CD**

---

## 🧱 Phase Summary

### **Phase 1 – Containerization**
- Built a Python Flask app (`app.py`) and containerized it using **Docker**.
- Added `docker-compose.yaml` for local multi-container testing.
- Published Docker image to Docker Hub (`alexsay23/quakewatch`).

---

### **Phase 2 – Kubernetes (K3s) on AWS**
- Deployed a **lightweight K3s cluster** across two EC2 instances (server + agent).
- Configured **PersistentVolumes**, **ConfigMaps**, and **Liveness/Readiness Probes**.
- Added a **CronJob** for periodic earthquake data refresh.
- Implemented **Horizontal Pod Autoscaler (HPA)**.

---

### **Phase 3 – Helm & CI/CD**
- Created Helm charts under `/charts/quakewatch`.
- Configured GitHub Actions for CI/CD pipeline:
  - Linting
  - Build & Test (matrix across Python versions)
  - Auto-deploy on successful merges
- Packaged Helm chart and published to GHCR.

---

### **Phase 4 – GitOps (Argo CD)**
- Installed **Argo CD** in-cluster.
- Synced Helm chart directly from GitHub repository.
- Managed continuous deployment and rollback via Argo CD UI.

---

### **Phase 5 – Observability**
- Installed **Prometheus** and **Grafana** in the cluster.
- Created dashboards showing:
  - Pod CPU/memory usage
  - Pod restart trends
  - Application HTTP requests per second
  - Cluster health overview

---

## 🧾 Deliverables

| Category | Deliverable |
|-----------|--------------|
| **Infrastructure as Code** | Terraform configuration files (e.g., `vpc.tf`, `instances.tf`) for AWS infrastructure provisioning. |
| **Documentation** | Step-by-step documentation detailing AWS VPC, EC2 instance setup, SSH key automation, and K3s installation. |
| **Kubernetes Deployment** | Kubernetes manifests and Helm charts (`charts/quakewatch/`) for deploying the QuakeWatch application. |
| **Monitoring** | Prometheus & Grafana setup with ready-made dashboards. |
| **GitOps** | Argo CD configurations and application manifests. |
| **CI/CD** | GitHub Actions workflows under `.github/workflows`. |

---

## 🧭 Architecture Diagram

```
Terraform → AWS EC2 → K3s Cluster → Helm → Traefik → QuakeWatch Pods
                                               │
                                     ┌─────────┴─────────┐
                                     │                   │
                              Argo CD (GitOps)    Prometheus + Grafana
```

---

## ⚙️ Deployment Flow

### **1. Provision AWS Infrastructure**
```bash
cd tf-k3s-quakewatch
terraform init
terraform apply -auto-approve
```

### **2. Access the K3s Server**
```bash
ssh -i ~/.ssh/quakewatch-k3s.pem ubuntu@<server_public_ip>
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes -o wide
```

### **3. Deploy the Application with Helm**
```bash
cd ~/charts
helm install quakewatch ./quakewatch -n quakewatch --create-namespace
kubectl -n quakewatch get pods,svc
```

### **4. Access the App**
```
http://<EC2-PUBLIC-IP>/
```

---

## 🧹 Cleanup (to avoid AWS charges)

After testing, run:
```bash
cd tf-k3s-quakewatch
chmod +x cleanup.sh
./cleanup.sh
```

This will:
- Destroy Terraform resources  
- Terminate any stray EC2 instances  
- Delete AWS key pairs and orphaned EBS volumes  

---

## 👨‍💻 Author

**Alex Sayenko**  
*DevOps Engineer*  
Technologies: Terraform • AWS • Kubernetes (K3s) • Helm • Argo CD • Grafana • GitHub Actions  

---

📘 *Final Deliverable includes Terraform IaC, Helm chart, and documentation for full infrastructure and deployment automation.*
