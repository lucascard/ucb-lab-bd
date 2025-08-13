# Configuração para Deploy

## 🚀 Visão Geral

Este guia aborda as configurações necessárias para fazer deploy do UBC Lab BD em diferentes ambientes, desde desenvolvimento até produção.

## 🔧 Variáveis de Ambiente

### Configurações Essenciais

```bash
# .env.production
# Database
DATABASE_URL=postgresql://user:password@host:port/database
DATABASE_POOL_SIZE=20
DATABASE_POOL_MAX_OVERFLOW=30

# Security
SECRET_KEY=sua_chave_secreta_super_forte_aqui
JWT_SECRET_KEY=chave_jwt_diferente_e_segura
ENCRYPTION_KEY=chave_de_criptografia_32_bytes

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
DEBUG=false

# Cache
REDIS_URL=redis://user:password@host:port/db
CACHE_TTL=3600

# Storage
S3_BUCKET=ubclab-storage
S3_ACCESS_KEY=AKIA...
S3_SECRET_KEY=...
S3_REGION=us-east-1

# Monitoring
SENTRY_DSN=https://...@sentry.io/project
LOG_LEVEL=INFO
METRICS_ENABLED=true

# External Services
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@ubclab.com
SMTP_PASSWORD=app_password
```

### Configurações por Ambiente

#### Desenvolvimento
```bash
# .env.development
DEBUG=true
LOG_LEVEL=DEBUG
DATABASE_URL=postgresql://dev:dev@localhost:5432/ubclab_dev
REDIS_URL=redis://localhost:6379/0
API_WORKERS=1
```

#### Staging
```bash
# .env.staging
DEBUG=false
LOG_LEVEL=INFO
DATABASE_URL=postgresql://staging_user:pass@staging-db:5432/ubclab_staging
REDIS_URL=redis://staging-redis:6379/0
API_WORKERS=2
```

#### Produção
```bash
# .env.production
DEBUG=false
LOG_LEVEL=WARNING
DATABASE_URL=postgresql://prod_user:secure_pass@prod-db:5432/ubclab_prod
REDIS_URL=redis://prod-redis:6379/0
API_WORKERS=8
```

## 🗄️ Configuração de Banco de Dados

### PostgreSQL

#### Configuração Básica
```sql
-- Criar banco e usuário
CREATE USER ubclab_user WITH PASSWORD 'secure_password';
CREATE DATABASE ubclab_prod WITH OWNER ubclab_user;

-- Extensões necessárias
\c ubclab_prod
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Configurações de performance
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '1GB';
ALTER SYSTEM SET effective_cache_size = '3GB';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '256MB';
```

#### postgresql.conf Otimizado
```ini
# Conexões
max_connections = 200
superuser_reserved_connections = 3

# Memória
shared_buffers = 1GB                    # 25% da RAM
effective_cache_size = 3GB              # 75% da RAM
work_mem = 16MB
maintenance_work_mem = 256MB
dynamic_shared_memory_type = posix

# WAL
wal_buffers = 16MB
checkpoint_completion_target = 0.9
wal_compression = on
max_wal_size = 2GB
min_wal_size = 1GB

# Query Planner
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
```

### Migrations

```python
# migrations/001_initial_schema.py
from alembic import op
import sqlalchemy as sa

def upgrade():
    # Usuários
    op.create_table(
        'users',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('username', sa.String(50), unique=True, nullable=False),
        sa.Column('email', sa.String(120), unique=True, nullable=False),
        sa.Column('password_hash', sa.String(255), nullable=False),
        sa.Column('is_active', sa.Boolean, default=True),
        sa.Column('created_at', sa.DateTime, default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, default=sa.func.now(), onupdate=sa.func.now())
    )
    
    # Índices
    op.create_index('idx_users_username', 'users', ['username'])
    op.create_index('idx_users_email', 'users', ['email'])
    op.create_index('idx_users_created_at', 'users', ['created_at'])

def downgrade():
    op.drop_table('users')
```

## 🐳 Docker Configuration

### Dockerfile

```dockerfile
# Multi-stage build
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production image
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application
COPY . .

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:app"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://ubclab:password@db:5432/ubclab
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: ubclab
      POSTGRES_USER: ubclab
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    restart: unless-stopped
    
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass redis_password
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

## ⚙️ Configuração do Servidor Web

### NGINX

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream app {
        server app:8000;
    }
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    server {
        listen 80;
        server_name ubclab.example.com;
        return 301 https://$server_name$request_uri;
    }
    
    server {
        listen 443 ssl http2;
        server_name ubclab.example.com;
        
        # SSL configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        
        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        
        # API routes
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            # File upload
            client_max_body_size 100M;
        }
        
        # Static files
        location /static/ {
            alias /app/static/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Health check
        location /health {
            proxy_pass http://app;
            access_log off;
        }
    }
}
```

## 🔒 Configurações de Segurança

### SSL/TLS

```bash
# Gerar certificados SSL (desenvolvimento)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Let's Encrypt (produção)
certbot --nginx -d ubclab.example.com
```

### Firewall

```bash
# UFW configuration
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80
ufw allow 443
ufw enable
```

### Secrets Management

```yaml
# kubernetes-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ubclab-secrets
type: Opaque
data:
  database-url: cG9zdGdyZXNxbC0uLi4=  # base64 encoded
  jwt-secret: and0LXNlY3JldC0uLi4=    # base64 encoded
  s3-access-key: czMtYWNjZXNzLWtleQ==  # base64 encoded
```

## 📊 Monitoramento

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ubclab'
    static_configs:
      - targets: ['app:8000']
    metrics_path: '/metrics'
    scrape_interval: 10s
    
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

### Application Metrics

```python
# metrics.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest

# Métricas customizadas
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
ACTIVE_USERS = Gauge('active_users_total', 'Number of active users')
DATABASE_CONNECTIONS = Gauge('database_connections_active', 'Active database connections')

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': 'text/plain; charset=utf-8'}
```

## ☁️ Configuração Cloud

### AWS

```yaml
# cloudformation-template.yaml
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      
  RDSInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceClass: db.t3.medium
      Engine: postgres
      EngineVersion: '15.4'
      MasterUsername: ubclab
      MasterUserPassword: !Ref DBPassword
      AllocatedStorage: 100
      StorageType: gp2
      
  ElastiCacheCluster:
    Type: AWS::ElastiCache::CacheCluster
    Properties:
      CacheNodeType: cache.t3.micro
      Engine: redis
      NumCacheNodes: 1
```

### Kubernetes

```yaml
# k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ubclab-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ubclab
  template:
    metadata:
      labels:
        app: ubclab
    spec:
      containers:
      - name: app
        image: ubclab/app:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: ubclab-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: ubclab-service
spec:
  selector:
    app: ubclab
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
```

## 🔄 Backup e Disaster Recovery

### Database Backup

```bash
#!/bin/bash
# backup-database.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="ubclab_backup_${DATE}.sql"

# Backup
pg_dump $DATABASE_URL > $BACKUP_FILE

# Comprimir
gzip $BACKUP_FILE

# Upload para S3
aws s3 cp ${BACKUP_FILE}.gz s3://ubclab-backups/database/

# Limpeza local (manter apenas 7 dias)
find . -name "ubclab_backup_*.sql.gz" -mtime +7 -delete
```

### Application Backup

```bash
#!/bin/bash
# backup-files.sh

# Backup de arquivos uploaded
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz /app/uploads/

# Upload para S3
aws s3 cp uploads_backup_$(date +%Y%m%d).tar.gz s3://ubclab-backups/files/
```

---

*Para o processo completo de deploy, consulte o [Guia de Deploy](guia-deploy.md).*