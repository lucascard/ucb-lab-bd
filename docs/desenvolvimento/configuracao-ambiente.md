# Configuração do Ambiente de Desenvolvimento

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter os seguintes softwares instalados:

### Obrigatórios
- **Python 3.8+**: Linguagem principal do projeto
- **Git**: Para controle de versão
- **Docker**: Para containerização (opcional, mas recomendado)

### Recomendados
- **Visual Studio Code**: Editor de código recomendado
- **PostgreSQL**: Banco de dados para desenvolvimento local
- **Node.js 16+**: Para ferramentas de front-end

## 🚀 Configuração Inicial

### 1. Clone do Repositório

```bash
git clone https://github.com/lucascard/ubc-lab-bd.git
cd ubc-lab-bd
```

### 2. Configuração do Python

#### Criação do Ambiente Virtual
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/macOS
python3 -m venv venv
source venv/bin/activate
```

#### Instalação das Dependências
```bash
pip install -r requirements.txt
```

### 3. Configuração do Banco de Dados

#### Usando Docker (Recomendado)
```bash
docker-compose up -d postgres
```

#### Instalação Local
1. Instale o PostgreSQL
2. Crie um banco de dados para o projeto:
```sql
CREATE DATABASE ubc_lab_bd;
CREATE USER ubc_user WITH PASSWORD 'senha_segura';
GRANT ALL PRIVILEGES ON DATABASE ubc_lab_bd TO ubc_user;
```

### 4. Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
# Database
DATABASE_URL=postgresql://ubc_user:senha_segura@localhost/ubc_lab_bd

# Development
DEBUG=True
SECRET_KEY=sua_chave_secreta_aqui

# API Keys (se necessário)
API_KEY=sua_api_key_aqui
```

## 🛠️ Ferramentas de Desenvolvimento

### Editor de Código
Configuração recomendada para VS Code:

1. Instale as seguintes extensões:
   - Python
   - GitLens
   - Docker
   - PostgreSQL

2. Configure o arquivo `.vscode/settings.json`:
```json
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black"
}
```

### Linting e Formatação
```bash
# Instalar ferramentas de qualidade de código
pip install black pylint pytest

# Configurar pre-commit hooks
pre-commit install
```

## 🧪 Execução dos Testes

### Testes Unitários
```bash
pytest tests/
```

### Testes de Integração
```bash
pytest tests/integration/
```

### Cobertura de Código
```bash
pytest --cov=src tests/
```

## 🏃‍♂️ Executando o Projeto

### Desenvolvimento
```bash
# Backend
python manage.py runserver

# Frontend (se aplicável)
npm run dev
```

### Usando Docker
```bash
docker-compose up
```

## 🐛 Resolução de Problemas Comuns

### Erro de Conexão com Banco de Dados
- Verifique se o PostgreSQL está rodando
- Confirme as credenciais no arquivo `.env`
- Teste a conexão manualmente

### Problemas com Dependências
```bash
# Limpar cache do pip
pip cache purge

# Reinstalar dependências
pip uninstall -r requirements.txt -y
pip install -r requirements.txt
```

### Problemas com Docker
```bash
# Limpar containers e volumes
docker-compose down -v
docker-compose up --build
```

## 📚 Recursos Adicionais

- [Documentação do Python](https://docs.python.org/)
- [Guia do PostgreSQL](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

*Após configurar o ambiente, consulte o [Guia de Contribuição](guia-contribuicao.md) para entender o workflow de desenvolvimento.*