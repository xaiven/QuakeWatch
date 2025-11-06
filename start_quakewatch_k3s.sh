#!/bin/bash
set -e

echo "🚀 Starting full QuakeWatch K3s deployment on AWS..."

# Navigate to Terraform project
cd "$(dirname "$0")/tf-k3s-quakewatch"

# Step 1: Terraform init & apply
echo "🧩 Initializing Terraform..."
terraform init -upgrade

echo "🌍 Applying Terraform configuration (this will take several minutes)..."
terraform apply -auto-approve

# Step 2: Extract K3s server IP
SERVER_IP=$(terraform output -raw server_public_ip)
echo "✅ K3s Server public IP: $SERVER_IP"

# Step 3: Wait for server to boot
echo "⏳ Waiting 90 seconds for K3s to initialize..."
sleep 90

# Step 4: Copy Helm charts to server
cd ..
if [ ! -d "charts" ]; then
  echo "❌ Helm charts directory not found!"
  exit 1
fi

echo "📦 Copying Helm charts to server..."
scp -i ~/.ssh/quakewatch-k3s.pem -r charts ubuntu@$SERVER_IP:~/

# Step 5: SSH into server and deploy
echo "🔐 Connecting to K3s server and deploying QuakeWatch..."
ssh -i ~/.ssh/quakewatch-k3s.pem ubuntu@$SERVER_IP << 'EOF'
  set -e
  echo "⚙️ Configuring K3s..."
  sudo chmod 644 /etc/rancher/k3s/k3s.yaml
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

  echo "📦 Installing Helm (if missing)..."
  if ! command -v helm &> /dev/null; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi

  echo "🚀 Deploying QuakeWatch Helm chart..."
  cd ~/charts
  helm upgrade --install quakewatch ./quakewatch -n quakewatch --create-namespace

  echo "🔍 Verifying deployment..."
  kubectl -n quakewatch get pods,svc
EOF

echo "✅ QuakeWatch deployed successfully!"
echo "🌐 Access it via: http://$SERVER_IP:<NodePort> (check with kubectl get svc)"
