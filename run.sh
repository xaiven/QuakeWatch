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

#Git
git init # if not already a git repo
git remote add origin git@github.com:<you>/QuakeWatch.git
# Ensure main is up to date
git checkout -B main
git add .
git commit -m "Phase 3: add Helm chart"
git push -u origin main

# Create a feature branch
git checkout -b feat/helm-values-tuning
# Edit values
vim charts/quakewatch/values.yaml
# Commit
git add charts/quakewatch/values.yaml
git commit -m "tune resources and env"
# Push and open a PR
git push -u origin HEAD

# Intentional conflict demo::
# Terminal A (branch 1)
git checkout -b feat/a
sed -i 's/tag: ".*"/tag: "0.1.1"/' charts/quakewatch/values.yaml
git commit -am "bump tag to 0.1.1"
git push -u origin feat/a

# Terminal B (branch 2)
git checkout -b feat/b
gsed -i 's/tag: ".*"/tag: "0.1.2"/' charts/quakewatch/values.yaml || sed -i '' 's/tag: ".*"/tag: "0.1.2"/' charts/quakewatch/values.yaml
git commit -am "bump tag to 0.1.2"
git push -u origin feat/b



