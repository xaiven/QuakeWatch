
# ☁️ AWS Infrastructure & K3s Deployment Guide — QuakeWatch

This guide explains how to deploy **QuakeWatch** on an **AWS EC2 instance** running **K3s**, using a pre‑built Helm chart.

---

## 🧱 1. AWS Infrastructure Overview

- **Region:** `us-east-1`
- **Instance Type:** `t3.micro` (with swap enabled)
- **VPC:** Custom VPC with public subnet and internet gateway
- **Security Groups:** Allow inbound ports 22 (SSH), 80/443 (HTTP/HTTPS), and 5000 (QuakeWatch)
- **OS:** Ubuntu 24.04 LTS

---

## ⚙️ 2. EC2 Setup & Access

```bash
# Connect to EC2
ssh -i quakewatch-key.pem ubuntu@<ec2-public-ip>

# Update system
sudo apt update && sudo apt upgrade -y
sudo apt install curl -y
```

Enable swap if needed:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo bash -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
```

---

## ☸️ 3. Install K3s (Lightweight Kubernetes)

```bash
curl -sfL https://get.k3s.io | sh -
sudo systemctl enable k3s
sudo systemctl status k3s
```

Check cluster status:
```bash
sudo kubectl get nodes -o wide
sudo kubectl get pods -A
```

---

## 📦 4. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## 🧭 5. Deploy QuakeWatch via Helm (GHCR Chart)

```bash
helm install quakewatch oci://ghcr.io/alexsay23/helm-charts/quakewatch --version 0.1.0
```

Verify deployment:
```bash
kubectl get pods,svc -A
kubectl describe svc quakewatch
kubectl logs -l app=quakewatch
```

Expose app externally (if needed):
```bash
kubectl port-forward svc/quakewatch 5000:5000
```

Then visit:
```
http://<ec2-public-ip>:5000
```

---

## 🧩 6. Optional — Add ArgoCD for GitOps

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Login via browser:
```
https://localhost:8080
```

Add QuakeWatch Helm repo to ArgoCD → Sync → Enjoy automated updates.

---

## ✅ Verification

```bash
kubectl get all -A
kubectl get hpa
kubectl get events --sort-by=.metadata.creationTimestamp
```

Once pods are `Running`, QuakeWatch will be accessible publicly on port **5000**.

---

**Author:** Alex Sayenko  
**Helm Chart:** ghcr.io/alexsay23/helm-charts/quakewatch:0.1.0  
**Region:** us-east-1  
**Instance:** t3.micro with swap enabled
