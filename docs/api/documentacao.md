# Documentação da API

## 🚀 Visão Geral

A API do UBC Lab BD fornece acesso programático a todas as funcionalidades do sistema, permitindo integração com outros sistemas e desenvolvimento de aplicações customizadas.

## 🔗 Base URL

```
# Desenvolvimento
https://api-dev.ubclab.example.com/v1

# Produção
https://api.ubclab.example.com/v1
```

## 🔐 Autenticação

### JWT Bearer Token
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Obter Token
```http
POST /auth/login
Content-Type: application/json

{
    "username": "seu_usuario",
    "password": "sua_senha"
}
```

**Resposta:**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 3600
}
```

## 👤 Usuários

### Criar Usuário
```http
POST /users
Content-Type: application/json
Authorization: Bearer {token}

{
    "username": "novousuario",
    "email": "usuario@example.com",
    "password": "senha_segura_123",
    "full_name": "Nome Completo"
}
```

**Resposta (201 Created):**
```json
{
    "id": 123,
    "username": "novousuario",
    "email": "usuario@example.com",
    "full_name": "Nome Completo",
    "is_active": true,
    "created_at": "2024-12-08T22:53:00Z",
    "last_login": null
}
```

### Listar Usuários
```http
GET /users?page=1&size=20&search=termo
Authorization: Bearer {token}
```

**Parâmetros de Query:**
- `page` (int, opcional): Página (padrão: 1)
- `size` (int, opcional): Itens por página (padrão: 20, máx: 100)
- `search` (string, opcional): Busca por username ou email

**Resposta (200 OK):**
```json
{
    "items": [
        {
            "id": 123,
            "username": "usuario1",
            "email": "usuario1@example.com",
            "full_name": "Usuário Um",
            "is_active": true,
            "created_at": "2024-12-08T22:53:00Z"
        }
    ],
    "total": 1,
    "page": 1,
    "size": 20,
    "pages": 1
}
```

### Obter Usuário por ID
```http
GET /users/{user_id}
Authorization: Bearer {token}
```

### Atualizar Usuário
```http
PUT /users/{user_id}
Content-Type: application/json
Authorization: Bearer {token}

{
    "full_name": "Nome Atualizado",
    "email": "novo_email@example.com"
}
```

### Deletar Usuário
```http
DELETE /users/{user_id}
Authorization: Bearer {token}
```

## 📊 Datasets

### Criar Dataset
```http
POST /datasets
Content-Type: application/json
Authorization: Bearer {token}

{
    "name": "Vendas Q4 2024",
    "description": "Dados de vendas do quarto trimestre",
    "schema": {
        "columns": [
            {
                "name": "data_venda",
                "type": "datetime",
                "required": true
            },
            {
                "name": "produto",
                "type": "string",
                "required": true
            },
            {
                "name": "valor",
                "type": "decimal",
                "required": true
            }
        ]
    },
    "tags": ["vendas", "q4", "2024"]
}
```

### Upload de Dados
```http
POST /datasets/{dataset_id}/data
Content-Type: multipart/form-data
Authorization: Bearer {token}

file: (binary data)
format: csv
delimiter: ,
has_header: true
```

### Consultar Dados
```http
GET /datasets/{dataset_id}/data?limit=100&offset=0&filter=valor>1000
Authorization: Bearer {token}
```

**Parâmetros de Query:**
- `limit` (int): Número máximo de registros
- `offset` (int): Número de registros para pular
- `filter` (string): Filtro SQL-like (ex: "coluna>valor", "nome='João'")
- `sort` (string): Ordenação (ex: "data_venda desc")

## 📈 Analytics

### Executar Análise
```http
POST /analytics/execute
Content-Type: application/json
Authorization: Bearer {token}

{
    "dataset_id": 123,
    "analysis_type": "statistics",
    "parameters": {
        "columns": ["valor", "quantidade"],
        "group_by": ["produto"],
        "functions": ["mean", "sum", "count"]
    }
}
```

**Resposta (200 OK):**
```json
{
    "analysis_id": "abc123",
    "status": "completed",
    "results": {
        "produto_a": {
            "valor_mean": 150.75,
            "valor_sum": 15075.00,
            "quantidade_sum": 120,
            "count": 100
        },
        "produto_b": {
            "valor_mean": 230.50,
            "valor_sum": 23050.00,
            "quantidade_sum": 80,
            "count": 100
        }
    },
    "metadata": {
        "execution_time_ms": 245,
        "rows_processed": 200
    }
}
```

### Análises Disponíveis
```http
GET /analytics/types
Authorization: Bearer {token}
```

## 📋 Relatórios

### Gerar Relatório
```http
POST /reports
Content-Type: application/json
Authorization: Bearer {token}

{
    "name": "Relatório de Vendas",
    "dataset_id": 123,
    "template": "sales_summary",
    "parameters": {
        "date_range": {
            "start": "2024-10-01",
            "end": "2024-12-31"
        },
        "group_by": "produto",
        "format": "pdf"
    }
}
```

### Download de Relatório
```http
GET /reports/{report_id}/download
Authorization: Bearer {token}
```

## 🔍 Busca Global

### Buscar em Todo o Sistema
```http
GET /search?q=vendas&type=datasets&limit=10
Authorization: Bearer {token}
```

**Parâmetros:**
- `q` (string): Termo de busca
- `type` (string, opcional): Tipo de recurso (datasets, users, reports)
- `limit` (int, opcional): Limite de resultados

## 📊 Métricas e Status

### Status da API
```http
GET /health
```

**Resposta:**
```json
{
    "status": "healthy",
    "timestamp": "2024-12-08T22:53:00Z",
    "version": "1.2.3",
    "services": {
        "database": "healthy",
        "cache": "healthy",
        "storage": "healthy"
    }
}
```

### Métricas do Sistema
```http
GET /metrics
Authorization: Bearer {token}
```

## ❌ Códigos de Erro

### Estrutura de Erro
```json
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Dados de entrada inválidos",
        "details": {
            "field": "email",
            "reason": "formato inválido"
        },
        "timestamp": "2024-12-08T22:53:00Z",
        "request_id": "req_abc123"
    }
}
```

### Códigos HTTP Comuns
- **200 OK**: Sucesso
- **201 Created**: Recurso criado
- **400 Bad Request**: Dados inválidos
- **401 Unauthorized**: Não autenticado
- **403 Forbidden**: Sem permissão
- **404 Not Found**: Recurso não encontrado
- **422 Unprocessable Entity**: Erro de validação
- **429 Too Many Requests**: Rate limit excedido
- **500 Internal Server Error**: Erro interno

## 🔄 Rate Limiting

### Limites por Usuário
- **Requests por minuto**: 1000
- **Requests por hora**: 10000
- **Upload de dados**: 10 arquivos/hora

### Headers de Rate Limit
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## 🔄 Versionamento

### Estratégia
- Versionamento na URL: `/v1/`, `/v2/`
- Backward compatibility mantida por 12 meses
- Deprecation notices com 6 meses de antecedência

### Headers de Versão
```http
API-Version: 1.0
Deprecated-Version: false
Sunset-Date: 2025-12-01
```

## 📚 SDKs e Bibliotecas

### Python
```bash
pip install ubclab-client
```

```python
from ubclab import UBCLabClient

client = UBCLabClient(
    base_url="https://api.ubclab.example.com/v1",
    token="seu_token_aqui"
)

# Criar dataset
dataset = client.datasets.create({
    "name": "Meu Dataset",
    "description": "Descrição do dataset"
})

# Upload de dados
client.datasets.upload_data(dataset.id, "dados.csv")
```

### JavaScript/Node.js
```bash
npm install @ubclab/client
```

```javascript
import { UBCLabClient } from '@ubclab/client';

const client = new UBCLabClient({
    baseURL: 'https://api.ubclab.example.com/v1',
    token: 'seu_token_aqui'
});

// Listar datasets
const datasets = await client.datasets.list();
```

## 🧪 Ambiente de Testes

### Sandbox
```
https://api-sandbox.ubclab.example.com/v1
```

- Dados de teste pré-carregados
- Reset diário às 00:00 UTC
- Todas as funcionalidades disponíveis

---

*Para exemplos práticos de uso da API, consulte a seção [Exemplos](exemplos.md).*