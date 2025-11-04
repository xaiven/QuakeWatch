# QuakeWatch — GitOps with ArgoCD

## Access
- Namespace: `argocd`
- UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- URL: https://localhost:8080  (user: `admin`, password: from `argocd-initial-admin-secret`)

## Application
- File: `gitops/argocd-app-quakewatch.yaml`
- Source: `https://github.com/xaiven/QuakeWatch.git`, path `charts/quakewatch`, branch `main`
- Auto-sync: enabled (`prune`, `selfHeal`)
- Sync waves:
  - `ConfigMap` → wave `"0"`
  - `Deployment` → wave `"1"`
- Image values (example):  
  `image.repository=docker.io/alexsay23/quakewatch`, `image.tag=2.0`

## Common operations
- Force sync: `kubectl annotate application quakewatch -n argocd argocd.argoproj.io/refresh=hard --overwrite`
- Pause auto-sync: set `.spec.syncPolicy` to manual in the Application YAML
- Debug:
  - `kubectl describe application quakewatch -n argocd`
  - If using SSH URL, add repo key under ArgoCD “Repositories” or switch to HTTPS.

## Secrets for private images
- Create once in target ns:
  ```bash
  kubectl create secret docker-registry dockerhub-secret \
    --docker-server=docker.io \
    --docker-username="alexsay23" \
    --docker-password="<DOCKERHUB_TOKEN>" \
    -n quakewatch
