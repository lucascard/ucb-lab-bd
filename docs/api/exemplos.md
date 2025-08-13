# Exemplos de Uso da API

## 🚀 Começando

### 1. Autenticação e Primeiro Acesso

```python
import requests
import json

# Configuração base
BASE_URL = "https://api.ubclab.example.com/v1"

# Login
login_data = {
    "username": "seu_usuario",
    "password": "sua_senha"
}

response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
auth_data = response.json()

# Token para próximas requisições
token = auth_data["access_token"]
headers = {"Authorization": f"Bearer {token}"}

print(f"Logado com sucesso! Token válido por {auth_data['expires_in']} segundos")
```

### 2. Verificar Status da API

```python
# Verificar se a API está funcionando
response = requests.get(f"{BASE_URL}/health")
status = response.json()

print(f"Status da API: {status['status']}")
print(f"Versão: {status['version']}")
```

## 📊 Trabalhando com Datasets

### Exemplo Completo: Upload e Análise de Dados de Vendas

```python
import pandas as pd
import requests
import json
from io import StringIO

# Headers com autenticação
headers = {"Authorization": f"Bearer {token}"}

# 1. Criar um novo dataset
dataset_config = {
    "name": "Vendas 2024",
    "description": "Dados de vendas do ano de 2024",
    "schema": {
        "columns": [
            {"name": "data_venda", "type": "datetime", "required": True},
            {"name": "produto", "type": "string", "required": True},
            {"name": "categoria", "type": "string", "required": True},
            {"name": "preco", "type": "decimal", "required": True},
            {"name": "quantidade", "type": "integer", "required": True},
            {"name": "vendedor", "type": "string", "required": True}
        ]
    },
    "tags": ["vendas", "2024", "comercial"]
}

response = requests.post(
    f"{BASE_URL}/datasets",
    json=dataset_config,
    headers=headers
)

dataset = response.json()
dataset_id = dataset["id"]
print(f"Dataset criado com ID: {dataset_id}")

# 2. Preparar dados de exemplo
dados_vendas = [
    {"data_venda": "2024-01-15", "produto": "Laptop", "categoria": "Eletrônicos", 
     "preco": 2500.00, "quantidade": 2, "vendedor": "João"},
    {"data_venda": "2024-01-16", "produto": "Mouse", "categoria": "Eletrônicos", 
     "preco": 50.00, "quantidade": 5, "vendedor": "Maria"},
    {"data_venda": "2024-01-17", "produto": "Cadeira", "categoria": "Móveis", 
     "preco": 300.00, "quantidade": 1, "vendedor": "João"},
    {"data_venda": "2024-01-18", "produto": "Mesa", "categoria": "Móveis", 
     "preco": 450.00, "quantidade": 1, "vendedor": "Ana"},
]

# Converter para CSV
df = pd.DataFrame(dados_vendas)
csv_data = df.to_csv(index=False)

# 3. Upload dos dados
files = {'file': ('vendas.csv', StringIO(csv_data), 'text/csv')}
data = {
    'format': 'csv',
    'delimiter': ',',
    'has_header': 'true'
}

response = requests.post(
    f"{BASE_URL}/datasets/{dataset_id}/data",
    files=files,
    data=data,
    headers=headers
)

print(f"Upload concluído: {response.json()}")
```

### Consultando Dados

```python
# Consultar todos os dados
response = requests.get(
    f"{BASE_URL}/datasets/{dataset_id}/data",
    headers=headers
)
dados = response.json()
print(f"Total de registros: {len(dados['items'])}")

# Consultar com filtros
params = {
    "filter": "preco > 100",
    "sort": "data_venda desc",
    "limit": 10
}

response = requests.get(
    f"{BASE_URL}/datasets/{dataset_id}/data",
    params=params,
    headers=headers
)

dados_filtrados = response.json()
print("Vendas acima de R$ 100:")
for item in dados_filtrados['items']:
    print(f"- {item['produto']}: R$ {item['preco']}")
```

## 📈 Análises de Dados

### Estatísticas Básicas

```python
# Executar análise estatística
analise_config = {
    "dataset_id": dataset_id,
    "analysis_type": "statistics",
    "parameters": {
        "columns": ["preco", "quantidade"],
        "group_by": ["categoria"],
        "functions": ["mean", "sum", "count", "max", "min"]
    }
}

response = requests.post(
    f"{BASE_URL}/analytics/execute",
    json=analise_config,
    headers=headers
)

resultados = response.json()

print("Estatísticas por categoria:")
for categoria, stats in resultados["results"].items():
    print(f"\n{categoria}:")
    print(f"  Preço médio: R$ {stats['preco_mean']:.2f}")
    print(f"  Total vendido: R$ {stats['preco_sum']:.2f}")
    print(f"  Quantidade total: {stats['quantidade_sum']}")
    print(f"  Número de vendas: {stats['count']}")
```

### Análise de Tendências

```python
# Análise de vendas por período
analise_periodo = {
    "dataset_id": dataset_id,
    "analysis_type": "time_series",
    "parameters": {
        "date_column": "data_venda",
        "value_column": "preco",
        "aggregation": "sum",
        "period": "daily",
        "date_range": {
            "start": "2024-01-01",
            "end": "2024-12-31"
        }
    }
}

response = requests.post(
    f"{BASE_URL}/analytics/execute",
    json=analise_periodo,
    headers=headers
)

tendencia = response.json()
print("Vendas por dia:", tendencia["results"])
```

## 📋 Gerando Relatórios

### Relatório de Vendas em PDF

```python
# Configurar relatório
relatorio_config = {
    "name": "Relatório Mensal de Vendas",
    "dataset_id": dataset_id,
    "template": "sales_summary",
    "parameters": {
        "date_range": {
            "start": "2024-01-01",
            "end": "2024-01-31"
        },
        "group_by": ["categoria", "vendedor"],
        "format": "pdf",
        "include_charts": True,
        "charts": ["bar", "pie"]
    }
}

# Gerar relatório
response = requests.post(
    f"{BASE_URL}/reports",
    json=relatorio_config,
    headers=headers
)

relatorio = response.json()
report_id = relatorio["id"]

print(f"Relatório gerado com ID: {report_id}")

# Aguardar processamento (em produção, usar webhooks)
import time
while True:
    response = requests.get(
        f"{BASE_URL}/reports/{report_id}",
        headers=headers
    )
    status = response.json()["status"]
    
    if status == "completed":
        break
    elif status == "failed":
        print("Erro na geração do relatório")
        break
    
    print(f"Status: {status}")
    time.sleep(2)

# Download do relatório
response = requests.get(
    f"{BASE_URL}/reports/{report_id}/download",
    headers=headers
)

with open("relatorio_vendas.pdf", "wb") as f:
    f.write(response.content)

print("Relatório baixado: relatorio_vendas.pdf")
```

## 🔍 Busca e Descoberta

### Buscar Datasets

```python
# Buscar datasets por termo
response = requests.get(
    f"{BASE_URL}/search",
    params={"q": "vendas", "type": "datasets"},
    headers=headers
)

resultados = response.json()

print("Datasets encontrados:")
for dataset in resultados["items"]:
    print(f"- {dataset['name']}: {dataset['description']}")
```

## 🤖 Automação com Workflows

### Script de ETL Completo

```python
class UBCLabETL:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {"Authorization": f"Bearer {token}"}
    
    def create_dataset(self, config):
        """Criar dataset"""
        response = requests.post(
            f"{self.base_url}/datasets",
            json=config,
            headers=self.headers
        )
        return response.json()
    
    def upload_data(self, dataset_id, file_path):
        """Upload de arquivo"""
        with open(file_path, 'rb') as f:
            files = {'file': f}
            data = {
                'format': 'csv',
                'delimiter': ',',
                'has_header': 'true'
            }
            
            response = requests.post(
                f"{self.base_url}/datasets/{dataset_id}/data",
                files=files,
                data=data,
                headers=self.headers
            )
        return response.json()
    
    def run_analysis(self, dataset_id, analysis_config):
        """Executar análise"""
        config = {
            "dataset_id": dataset_id,
            **analysis_config
        }
        
        response = requests.post(
            f"{self.base_url}/analytics/execute",
            json=config,
            headers=self.headers
        )
        return response.json()
    
    def generate_report(self, dataset_id, report_config):
        """Gerar relatório"""
        config = {
            "dataset_id": dataset_id,
            **report_config
        }
        
        response = requests.post(
            f"{self.base_url}/reports",
            json=config,
            headers=self.headers
        )
        return response.json()

# Uso do ETL
etl = UBCLabETL(BASE_URL, token)

# Processo completo
dataset = etl.create_dataset({
    "name": "Dados de Produção",
    "description": "Dados automatizados de produção"
})

upload_result = etl.upload_data(dataset["id"], "dados_producao.csv")

analysis_result = etl.run_analysis(dataset["id"], {
    "analysis_type": "statistics",
    "parameters": {"columns": ["eficiencia", "tempo_producao"]}
})

report = etl.generate_report(dataset["id"], {
    "name": "Relatório de Produção Automatizado",
    "template": "production_summary",
    "format": "pdf"
})

print("Pipeline ETL executado com sucesso!")
```

## 🌐 Integração com JavaScript

### Frontend React

```javascript
// hooks/useUBCLabAPI.js
import { useState, useEffect } from 'react';

const API_BASE = 'https://api.ubclab.example.com/v1';

export function useUBCLabAPI(token) {
    const [datasets, setDatasets] = useState([]);
    const [loading, setLoading] = useState(false);
    
    const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
    };
    
    const fetchDatasets = async () => {
        setLoading(true);
        try {
            const response = await fetch(`${API_BASE}/datasets`, { headers });
            const data = await response.json();
            setDatasets(data.items);
        } catch (error) {
            console.error('Erro ao buscar datasets:', error);
        } finally {
            setLoading(false);
        }
    };
    
    const createDataset = async (config) => {
        const response = await fetch(`${API_BASE}/datasets`, {
            method: 'POST',
            headers,
            body: JSON.stringify(config)
        });
        return response.json();
    };
    
    return {
        datasets,
        loading,
        fetchDatasets,
        createDataset
    };
}

// components/DatasetList.jsx
function DatasetList({ token }) {
    const { datasets, loading, fetchDatasets } = useUBCLabAPI(token);
    
    useEffect(() => {
        fetchDatasets();
    }, []);
    
    if (loading) return <div>Carregando...</div>;
    
    return (
        <div>
            <h2>Meus Datasets</h2>
            {datasets.map(dataset => (
                <div key={dataset.id} className="dataset-card">
                    <h3>{dataset.name}</h3>
                    <p>{dataset.description}</p>
                    <span>Criado em: {new Date(dataset.created_at).toLocaleDateString()}</span>
                </div>
            ))}
        </div>
    );
}
```

## 🔄 Tratamento de Erros

### Retry e Error Handling

```python
import time
from typing import Optional

class UBCLabAPIClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url
        self.headers = {"Authorization": f"Bearer {token}"}
        
    def _make_request(self, method: str, endpoint: str, 
                     max_retries: int = 3, **kwargs) -> Optional[dict]:
        """Fazer requisição com retry automático"""
        
        for attempt in range(max_retries):
            try:
                response = requests.request(
                    method, 
                    f"{self.base_url}{endpoint}",
                    headers=self.headers,
                    **kwargs
                )
                
                if response.status_code == 429:  # Rate limit
                    retry_after = int(response.headers.get('Retry-After', 60))
                    print(f"Rate limit atingido. Aguardando {retry_after}s...")
                    time.sleep(retry_after)
                    continue
                
                response.raise_for_status()
                return response.json()
                
            except requests.exceptions.RequestException as e:
                if attempt == max_retries - 1:
                    print(f"Erro após {max_retries} tentativas: {e}")
                    raise
                
                wait_time = 2 ** attempt  # Backoff exponencial
                print(f"Tentativa {attempt + 1} falhou. Tentando novamente em {wait_time}s...")
                time.sleep(wait_time)
        
        return None
    
    def get_dataset(self, dataset_id: int) -> Optional[dict]:
        return self._make_request("GET", f"/datasets/{dataset_id}")

# Uso com tratamento de erro
client = UBCLabAPIClient(BASE_URL, token)

try:
    dataset = client.get_dataset(123)
    if dataset:
        print(f"Dataset: {dataset['name']}")
    else:
        print("Dataset não encontrado")
except Exception as e:
    print(f"Erro ao buscar dataset: {e}")
```

---

*Para referência completa da API, consulte a [Documentação da API](documentacao.md).*