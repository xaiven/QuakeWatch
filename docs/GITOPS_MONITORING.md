# Phase 4 — GitOps & Monitoring Documentation

## ✅ Overview

In Phase 4, we enhanced the QuakeWatch application deployment with:

- GitOps using **ArgoCD**
- Application metrics using **Prometheus**
- Dashboards and visualization in **Grafana**
- Alerts for failures and performance issues

---

## 🚀 GitOps with ArgoCD

### ArgoCD Application Manifest

**File:** `argocd-quakewatch-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: quakewatch
  namespace: argocd
spec:
  destination:
    namespace: quakewatch
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/xaiven/QuakeWatch.git
    targetRevision: main
    path: charts/quakewatch
    helm:
      parameters:
      - name: image.repository
        value: docker.io/alexsay23/quakewatch
      - name: image.tag
        value: "3.0"
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## 📡 Enable Metrics in Flask

**app.py excerpt:**

```python
from prometheus_flask_exporter import PrometheusMetrics
metrics = PrometheusMetrics(app)
```

Metrics available at `/metrics`

---

## 📊 Monitoring with Prometheus & Grafana

### Install Prometheus & Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Access UIs

| Tool | Command |
|------|--------|
Grafana | `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`
Prometheus | `kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090`

---

## 📈 Grafana Dashboard Queries

| Purpose | PromQL |
|--------|--------|
Request rate | `sum(rate(flask_http_request_total[5m]))`
95th percentile latency | `histogram_quantile(0.95, sum(rate(flask_http_request_duration_seconds_bucket[5m])) by (le))`
Errors per second | `sum(rate(flask_http_request_exceptions_total[5m]))`
CPU usage | `sum(rate(container_cpu_usage_seconds_total{namespace="quakewatch"}[5m]))`
Memory usage | `sum(container_memory_working_set_bytes{namespace="quakewatch"})`
Pod restarts | `increase(kube_pod_container_status_restarts_total{namespace="quakewatch"}[5m])`
CronJob failures | `increase(kube_job_failed{namespace="quakewatch"}[30m])`

---

## 🛰 ServiceMonitor

**File:** `monitoring/servicemonitor-quakewatch.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: quakewatch
  namespace: monitoring
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: quakewatch
  namespaceSelector:
    matchNames:
    - quakewatch
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

---

## 🚨 Prometheus Alert Rules

**File:** `monitoring/prometheus-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: quakewatch-rules
  namespace: monitoring
spec:
  groups:
  - name: quakewatch-alerts
    rules:
    - alert: HighErrorRate
      expr: rate(flask_http_request_exceptions_total[5m]) > 0.1
      for: 2m
      labels: { severity: warning }
      annotations:
        summary: "High error rate detected"
        description: "Errors greater than 0.1/s for 2m"
```

---

## ✅ Deliverables Checklist

| Deliverable | Status |
|------------|-------|
ArgoCD GitOps config | ✅ Done
Prometheus/Grafana installed | ✅ Done
Flask metrics enabled | ✅ Done
Custom dashboards created | ✅ Done
Alerts created | ✅ Done
Docs & screenshots stored in repo | ✅ Done

---

## 🎉 Conclusion

You now have:

✔ Automated GitOps deployment via ArgoCD  
✔ Cluster & app monitoring with Prometheus  
✔ Dashboards & alerts in Grafana  
✔ Production‑grade DevOps workflow 🔥

End of **Phase 4 — GitOps & Monitoring**.
