# Padrões de Código

## 📏 Convenções Gerais

### Formatação
- **Indentação**: 4 espaços (não tabs)
- **Linha máxima**: 88 caracteres (Black formatter)
- **Encoding**: UTF-8
- **Line endings**: LF (Unix style)

### Naming Conventions

#### Python
```python
# Classes: PascalCase
class DataProcessor:
    pass

# Funções e variáveis: snake_case
def process_user_data():
    user_name = "exemplo"
    
# Constantes: UPPER_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 3
DATABASE_URL = "postgresql://..."

# Métodos privados: _leading_underscore
def _internal_method(self):
    pass

# Arquivos e módulos: snake_case
# user_service.py
# data_models.py
```

#### JavaScript/TypeScript
```javascript
// Classes: PascalCase
class UserService {
    
    // Métodos e variáveis: camelCase
    getUserData() {
        const userName = 'exemplo';
    }
    
    // Constantes: UPPER_SNAKE_CASE
    static MAX_RETRIES = 3;
    
    // Métodos privados: #private ou _protected
    #processData() {}
    _helperMethod() {}
}

// Arquivos: kebab-case
// user-service.ts
// data-models.ts
```

## 🐍 Python Standards

### Imports
```python
# Ordem dos imports:
# 1. Standard library
import os
import sys
from datetime import datetime

# 2. Third party
import requests
from fastapi import FastAPI

# 3. Local imports
from .models import User
from .services import UserService
```

### Docstrings
```python
def calculate_statistics(data: List[Dict]) -> Dict[str, float]:
    """
    Calcula estatísticas básicas de um dataset.
    
    Args:
        data: Lista de dicionários contendo os dados para análise.
              Cada dicionário deve conter chaves numéricas.
    
    Returns:
        Dicionário contendo as estatísticas calculadas:
        - mean: Média dos valores
        - median: Mediana dos valores
        - std: Desvio padrão
    
    Raises:
        ValueError: Se data estiver vazio ou contiver valores inválidos.
        TypeError: Se data não for uma lista de dicionários.
    
    Example:
        >>> data = [{'value': 1}, {'value': 2}, {'value': 3}]
        >>> stats = calculate_statistics(data)
        >>> print(stats['mean'])
        2.0
    """
    if not data:
        raise ValueError("Data cannot be empty")
    
    # Implementation here...
```

### Type Hints
```python
from typing import List, Dict, Optional, Union

def process_user_data(
    user_id: int,
    data: Dict[str, Union[str, int]],
    options: Optional[Dict[str, bool]] = None
) -> List[str]:
    """Process user data and return results."""
    options = options or {}
    # Implementation...
```

### Error Handling
```python
# Use specific exceptions
try:
    result = risky_operation()
except ValidationError as e:
    logger.error(f"Validation failed: {e}")
    raise HTTPException(status_code=400, detail=str(e))
except DatabaseError as e:
    logger.error(f"Database error: {e}")
    raise HTTPException(status_code=500, detail="Internal server error")

# Custom exceptions
class DataProcessingError(Exception):
    """Raised when data processing fails."""
    
    def __init__(self, message: str, error_code: str = None):
        super().__init__(message)
        self.error_code = error_code
```

## 🗄️ Database Patterns

### SQLAlchemy Models
```python
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(120), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    datasets = relationship("Dataset", back_populates="owner")
    
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"
```

### Repository Pattern
```python
from abc import ABC, abstractmethod
from typing import List, Optional

class UserRepository(ABC):
    @abstractmethod
    def create(self, user: User) -> User:
        pass
    
    @abstractmethod
    def get_by_id(self, user_id: int) -> Optional[User]:
        pass
    
    @abstractmethod
    def get_all(self) -> List[User]:
        pass

class SQLUserRepository(UserRepository):
    def __init__(self, session: Session):
        self.session = session
    
    def create(self, user: User) -> User:
        self.session.add(user)
        self.session.commit()
        return user
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.session.query(User).filter_by(id=user_id).first()
```

## 🔧 Configuration Management

### Environment Variables
```python
import os
from dataclasses import dataclass
from typing import Optional

@dataclass
class Settings:
    database_url: str = os.getenv("DATABASE_URL", "sqlite:///app.db")
    secret_key: str = os.getenv("SECRET_KEY", "dev-key")
    debug: bool = os.getenv("DEBUG", "False").lower() == "true"
    max_connections: int = int(os.getenv("MAX_CONNECTIONS", "10"))
    
    def __post_init__(self):
        if self.secret_key == "dev-key" and not self.debug:
            raise ValueError("Must set SECRET_KEY in production")

settings = Settings()
```

## 📝 Logging Standards

### Structured Logging
```python
import structlog
import logging

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger(__name__)

# Usage
logger.info(
    "User login",
    user_id=user.id,
    ip_address=request.remote_addr,
    user_agent=request.headers.get("User-Agent")
)
```

## 🧪 Testing Standards

### Unit Tests
```python
import pytest
from unittest.mock import Mock, patch

class TestUserService:
    @pytest.fixture
    def user_service(self):
        return UserService(repository=Mock())
    
    @pytest.fixture
    def sample_user(self):
        return User(id=1, username="test", email="test@example.com")
    
    def test_create_user_success(self, user_service, sample_user):
        # Arrange
        user_service.repository.create.return_value = sample_user
        
        # Act
        result = user_service.create_user(
            username="test",
            email="test@example.com"
        )
        
        # Assert
        assert result.username == "test"
        user_service.repository.create.assert_called_once()
    
    def test_create_user_duplicate_email_raises_error(self, user_service):
        # Arrange
        user_service.repository.create.side_effect = IntegrityError("", "", "")
        
        # Act & Assert
        with pytest.raises(ValidationError, match="Email already exists"):
            user_service.create_user("test", "existing@example.com")
```

### Integration Tests
```python
@pytest.mark.integration
class TestUserAPI:
    def test_create_user_endpoint(self, client, db_session):
        # Arrange
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "securepass123"
        }
        
        # Act
        response = client.post("/api/users", json=user_data)
        
        # Assert
        assert response.status_code == 201
        assert response.json()["username"] == "testuser"
        
        # Verify in database
        user = db_session.query(User).filter_by(username="testuser").first()
        assert user is not None
```

## 🔒 Security Standards

### Input Validation
```python
from pydantic import BaseModel, validator, EmailStr

class UserCreateRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    
    @validator('username')
    def validate_username(cls, v):
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        if not v.isalnum():
            raise ValueError('Username must be alphanumeric')
        return v
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v
```

### SQL Injection Prevention
```python
# ✅ Good - Using parameterized queries
def get_user_by_id(db: Session, user_id: int) -> User:
    return db.query(User).filter(User.id == user_id).first()

# ✅ Good - Using SQLAlchemy ORM
def search_users(db: Session, query: str) -> List[User]:
    return db.query(User).filter(
        User.username.ilike(f"%{query}%")
    ).all()

# ❌ Bad - String concatenation (vulnerable to SQL injection)
def bad_search_users(db: Session, query: str) -> List[User]:
    sql = f"SELECT * FROM users WHERE username LIKE '%{query}%'"
    return db.execute(sql).fetchall()
```

## 📊 Performance Guidelines

### Database Queries
```python
# ✅ Good - Eager loading for known relationships
users = db.query(User).options(
    joinedload(User.datasets)
).all()

# ✅ Good - Using indexes and filters
users = db.query(User).filter(
    User.created_at >= start_date,
    User.is_active == True
).limit(100)

# ❌ Bad - N+1 query problem
users = db.query(User).all()
for user in users:
    print(user.datasets)  # This will trigger one query per user
```

### Caching
```python
from functools import lru_cache
import redis

# Simple in-memory cache
@lru_cache(maxsize=128)
def get_user_permissions(user_id: int) -> List[str]:
    # Expensive operation
    return calculate_permissions(user_id)

# Redis cache with TTL
def get_cached_data(key: str) -> Optional[Dict]:
    try:
        data = redis_client.get(key)
        return json.loads(data) if data else None
    except Exception as e:
        logger.error(f"Cache error: {e}")
        return None

def set_cached_data(key: str, data: Dict, ttl: int = 3600):
    try:
        redis_client.setex(key, ttl, json.dumps(data))
    except Exception as e:
        logger.error(f"Cache error: {e}")
```

## 🔍 Code Quality Tools

### Formatters
```bash
# Black - Code formatter
black src/ tests/

# isort - Import sorter
isort src/ tests/
```

### Linters
```bash
# pylint - Static analysis
pylint src/

# flake8 - Style guide enforcement
flake8 src/

# mypy - Type checking
mypy src/
```

### Pre-commit Configuration
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 22.3.0
    hooks:
      - id: black
  
  - repo: https://github.com/pycqa/isort
    rev: 5.10.1
    hooks:
      - id: isort
  
  - repo: https://github.com/pycqa/flake8
    rev: 4.0.1
    hooks:
      - id: flake8
```

---

*Estes padrões são fundamentais para manter a qualidade e consistência do código. Para mais detalhes sobre o processo de desenvolvimento, consulte o [Guia de Contribuição](guia-contribuicao.md).*