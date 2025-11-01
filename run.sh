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



