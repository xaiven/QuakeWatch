data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated.key_name
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Create 2G swap (prevents k3s OOM on t3.micro)
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    # Install k3s server
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--cluster-init" sh -

    # Allow agent node to join later (token in /var/lib/rancher/k3s/server/node-token)
  EOF



  tags = { Name = "${var.project_name}-server" }
}

resource "aws_instance" "agent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated.key_name
  subnet_id                   = aws_subnet.public_b.id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  associate_public_ip_address = true
  depends_on                  = [aws_instance.server]

  user_data = <<EOF
#!/bin/bash
set -e
apt-get update -y
apt-get install -y curl
curl -sfL https://get.k3s.io | K3S_URL="https://${aws_instance.server.private_ip}:6443" K3S_TOKEN="${var.cluster_token}" sh -
EOF

  tags = { Name = "${var.project_name}-agent" }
}

resource "null_resource" "deploy_quakewatch" {
  depends_on = [aws_instance.server, aws_instance.agent]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.server.public_ip
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      # wait a bit longer for k3s startup
      "echo 'Waiting for k3s server to become ready…'",
      "sleep 120",

      # loop until API responds
      "until sudo /usr/local/bin/kubectl get nodes >/dev/null 2>&1; do echo '⏳ waiting for kube-api…'; sleep 10; done",

      # prepare helm chart directory as root
      "sudo mkdir -p /opt/quakewatch-helm/templates",
      "sudo chown -R ubuntu:ubuntu /opt/quakewatch-helm",

      # now run everything as root in one script
      <<-EOT
        sudo bash -lc '
        set -e
        CHART_DIR=/opt/quakewatch-helm

        cat > $CHART_DIR/Chart.yaml <<\"YAML\"
        apiVersion: v2
        name: quakewatch
        version: 0.1.0
        appVersion: "1.0.0"
        type: application
        YAML

        cat > $CHART_DIR/values.yaml <<YAML
        image: "${var.quakewatch_image}"
        replicaCount: 2
        service:
          type: ClusterIP
          port: 8000
        ingress:
          enabled: true
          className: "traefik"
          path: "/"
        YAML

        cat > $CHART_DIR/templates/deployment.yaml <<\"YAML\"
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: quakewatch
        spec:
          replicas: {{ .Values.replicaCount }}
          selector:
            matchLabels:
              app: quakewatch
          template:
            metadata:
              labels:
                app: quakewatch
            spec:
              containers:
              - name: quakewatch
                image: {{ .Values.image }}
                ports:
                - containerPort: 8000
        YAML

        cat > $CHART_DIR/templates/service.yaml <<\"YAML\"
        apiVersion: v1
        kind: Service
        metadata:
          name: quakewatch
        spec:
          selector:
            app: quakewatch
          ports:
          - name: http
            port: {{ .Values.service.port }}
            targetPort: 8000
        YAML

        cat > $CHART_DIR/templates/ingress.yaml <<\"YAML\"
        {{- if .Values.ingress.enabled }}
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: quakewatch
          annotations:
            kubernetes.io/ingress.class: {{ .Values.ingress.className | quote }}
        spec:
          rules:
          - http:
              paths:
              - path: {{ .Values.ingress.path }}
                pathType: Prefix
                backend:
                  service:
                    name: quakewatch
                    port:
                      number: {{ .Values.service.port }}
        {{- end }}
        YAML

        /usr/local/bin/helm upgrade --install quakewatch $CHART_DIR -n quakewatch --create-namespace
        /usr/local/bin/kubectl -n quakewatch get all
        '
      EOT
    ]
  }

}
