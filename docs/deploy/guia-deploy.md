# Guia de Deploy

## 🚀 Visão Geral

Este guia fornece instruções passo a passo para fazer deploy do UBC Lab BD em diferentes ambientes, desde desenvolvimento local até produção em escala.

## 📋 Pré-requisitos

### Requisitos Mínimos

#### Desenvolvimento
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 10GB SSD
- **OS**: Linux, macOS, Windows

#### Produção
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 50GB+ SSD
- **OS**: Linux (Ubuntu 20.04+ ou CentOS 8+)

### Software Necessário
- Docker & Docker Compose
- Git
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- NGINX (produção)

## 🏠 Deploy Local (Desenvolvimento)

### 1. Clone e Configuração Inicial

```bash
# Clone do repositório
git clone https://github.com/lucascard/ubc-lab-bd.git
cd ubc-lab-bd

# Configurar ambiente
cp .env.example .env.development
```

### 2. Usando Docker Compose

```bash
# Build e start dos serviços
docker-compose -f docker-compose.development.yml up --build

# Verificar status
docker-compose ps

# Logs em tempo real
docker-compose logs -f app
```

### 3. Configuração Manual

```bash
# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate     # Windows

# Instalar dependências
pip install -r requirements.txt

# Configurar banco de dados
createdb ubclab_dev
python manage.py migrate

# Criar superusuário
python manage.py createsuperuser

# Iniciar servidor
python manage.py runserver
```

### 4. Verificação

```bash
# Verificar API
curl http://localhost:8000/health

# Verificar banco de dados
python manage.py dbshell
```

## 🧪 Deploy Staging

### 1. Configuração do Servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo pip3 install docker-compose

# Configurar firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### 2. Deploy da Aplicação

```bash
# Clone do código
git clone https://github.com/lucascard/ubc-lab-bd.git
cd ubc-lab-bd

# Checkout para branch de staging
git checkout staging

# Configurar variáveis
cp .env.example .env.staging
nano .env.staging

# Deploy
docker-compose -f docker-compose.staging.yml up -d

# Verificar status
docker-compose -f docker-compose.staging.yml ps
```

### 3. Configuração SSL

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado
sudo certbot --nginx -d staging.ubclab.example.com

# Renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🌍 Deploy Produção

### Opção 1: Servidor Único

#### 1. Preparação do Servidor

```bash
# Configuração inicial (como root)
adduser ubclab
usermod -aG sudo ubclab
su - ubclab

# Configuração de segurança
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
# PasswordAuthentication no
sudo systemctl restart ssh

# Firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

#### 2. Instalação de Dependências

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubclab

# NGINX
sudo apt install nginx

# Certbot
sudo apt install certbot python3-certbot-nginx

# Monitoring tools
sudo apt install htop iotop nethogs
```

#### 3. Deploy da Aplicação

```bash
# Clone e configuração
git clone https://github.com/lucascard/ubc-lab-bd.git
cd ubc-lab-bd
git checkout main

# Configuração de produção
cp .env.example .env.production
nano .env.production

# Secrets (NÃO versionar)
echo "SECRET_KEY=$(openssl rand -hex 32)" >> .env.production
echo "JWT_SECRET_KEY=$(openssl rand -hex 32)" >> .env.production

# Deploy
docker-compose -f docker-compose.production.yml up -d

# Migrations
docker-compose exec app python manage.py migrate

# Criar superusuário
docker-compose exec app python manage.py createsuperuser
```

#### 4. Configuração NGINX

```bash
# Configurar NGINX
sudo nano /etc/nginx/sites-available/ubclab

# Ativar site
sudo ln -s /etc/nginx/sites-available/ubclab /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# SSL
sudo certbot --nginx -d ubclab.example.com
```

### Opção 2: Kubernetes

#### 1. Preparação do Cluster

```bash
# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Configurar cluster (exemplo com minikube)
minikube start --driver=docker --memory=4096 --cpus=2
```

#### 2. Deploy no Kubernetes

```bash
# Criar namespace
kubectl create namespace ubclab

# Configurar secrets
kubectl create secret generic ubclab-secrets \
  --from-literal=database-url="postgresql://..." \
  --from-literal=jwt-secret="..." \
  --namespace=ubclab

# Deploy
kubectl apply -f k8s/ -n ubclab

# Verificar status
kubectl get pods -n ubclab
kubectl get services -n ubclab
```

#### 3. Configuração de Ingress

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ubclab-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - ubclab.example.com
    secretName: ubclab-tls
  rules:
  - host: ubclab.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ubclab-service
            port:
              number: 80
```

### Opção 3: Cloud (AWS)

#### 1. Usando AWS ECS

```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciais
aws configure

# Criar cluster ECS
aws ecs create-cluster --cluster-name ubclab-cluster

# Deploy usando CloudFormation
aws cloudformation deploy \
  --template-file cloudformation-template.yaml \
  --stack-name ubclab-stack \
  --parameter-overrides \
    DBPassword=secure_password \
    AppImage=ubclab/app:latest
```

#### 2. Usando AWS EKS

```bash
# Instalar eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Criar cluster
eksctl create cluster --name ubclab-cluster --region us-east-1

# Deploy
kubectl apply -f k8s-aws/
```

## 🔄 CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: 3.11
        
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov
        
    - name: Run tests
      run: pytest --cov=src tests/
      
    - name: Security scan
      run: |
        pip install bandit safety
        bandit -r src/
        safety check

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Build Docker image
      run: |
        docker build -t ubclab/app:${{ github.sha }} .
        docker tag ubclab/app:${{ github.sha }} ubclab/app:latest
        
    - name: Push to registry
      env:
        DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
        DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
      run: |
        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
        docker push ubclab/app:${{ github.sha }}
        docker push ubclab/app:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to production
      env:
        HOST: ${{ secrets.PRODUCTION_HOST }}
        USERNAME: ${{ secrets.PRODUCTION_USERNAME }}
        SSH_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
      run: |
        echo "$SSH_KEY" > private_key
        chmod 600 private_key
        ssh -i private_key -o StrictHostKeyChecking=no $USERNAME@$HOST '
          cd /opt/ubclab &&
          git pull origin main &&
          docker-compose pull &&
          docker-compose up -d &&
          docker system prune -f
        '
```

## 🔍 Verificação e Monitoramento

### Health Checks

```bash
# Verificar API
curl -f http://localhost:8000/health || exit 1

# Verificar banco de dados
docker-compose exec db pg_isready -U ubclab

# Verificar Redis
docker-compose exec redis redis-cli ping

# Verificar logs
docker-compose logs --tail=50 app
```

### Métricas de Sistema

```bash
# CPU e Memória
docker stats

# Espaço em disco
df -h

# Conexões de rede
netstat -tuln

# Logs do sistema
journalctl -u docker -f
```

### Alertas Básicos

```bash
# Script de monitoramento simples
#!/bin/bash
# monitor.sh

# Verificar se a aplicação está respondendo
if ! curl -sf http://localhost:8000/health > /dev/null; then
    echo "ALERT: Application is not responding" | mail -s "UBC Lab Alert" admin@ubclab.com
fi

# Verificar uso de disco
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "ALERT: Disk usage is ${DISK_USAGE}%" | mail -s "Disk Space Alert" admin@ubclab.com
fi

# Adicionar ao crontab
# */5 * * * * /home/ubclab/monitor.sh
```

## 🔄 Backup e Recovery

### Backup Automatizado

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)

# Backup do banco de dados
docker-compose exec -T db pg_dump -U ubclab ubclab > backup_db_${DATE}.sql

# Backup de arquivos
tar -czf backup_files_${DATE}.tar.gz /opt/ubclab/uploads/

# Upload para S3 (se configurado)
if [ ! -z "$AWS_S3_BUCKET" ]; then
    aws s3 cp backup_db_${DATE}.sql s3://$AWS_S3_BUCKET/backups/
    aws s3 cp backup_files_${DATE}.tar.gz s3://$AWS_S3_BUCKET/backups/
fi

# Limpeza local (manter 7 dias)
find . -name "backup_*" -mtime +7 -delete
```

### Recovery

```bash
# Restaurar banco de dados
docker-compose exec -T db psql -U ubclab ubclab < backup_db_20241208_120000.sql

# Restaurar arquivos
tar -xzf backup_files_20241208_120000.tar.gz -C /

# Reiniciar serviços
docker-compose restart
```

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Container não inicia
```bash
# Verificar logs
docker-compose logs app

# Verificar recursos
docker system df
docker system prune

# Reconstruir imagem
docker-compose build --no-cache app
```

#### 2. Banco de dados não conecta
```bash
# Verificar status
docker-compose exec db pg_isready

# Verificar configuração
docker-compose exec app env | grep DATABASE

# Resetar banco
docker-compose down
docker volume rm ubclab_postgres_data
docker-compose up -d
```

#### 3. Performance baixa
```bash
# Verificar recursos
htop
iotop
docker stats

# Verificar logs de slow queries
docker-compose exec db tail -f /var/log/postgresql/postgresql.log

# Otimizar banco
docker-compose exec db psql -U ubclab -c "VACUUM ANALYZE;"
```

## 📊 Scaling

### Horizontal Scaling

```yaml
# docker-compose.scale.yml
version: '3.8'
services:
  app:
    deploy:
      replicas: 3
    
  nginx:
    image: nginx:alpine
    depends_on:
      - app
    ports:
      - "80:80"
    volumes:
      - ./nginx-load-balancer.conf:/etc/nginx/nginx.conf
```

### Database Scaling

```yaml
# Adicionar read replicas
db-replica:
  image: postgres:15
  environment:
    POSTGRES_DB: ubclab
    POSTGRES_USER: ubclab
    POSTGRES_PASSWORD: password
    POSTGRES_MASTER_SERVICE: db
  command: |
    postgres
    -c wal_level=replica
    -c hot_standby=on
    -c max_wal_senders=3
    -c max_replication_slots=3
    -c hot_standby_feedback=on
```

---

*Para configurações detalhadas de cada ambiente, consulte a seção [Configuração](configuracao.md).*