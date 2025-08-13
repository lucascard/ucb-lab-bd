# Guia de Contribuição

## 🤝 Como Contribuir

Agradecemos seu interesse em contribuir para o projeto UBC Lab BD! Este guia irá ajudá-lo a entender como participar do desenvolvimento.

## 📋 Tipos de Contribuição

### 🐛 Reportar Bugs
1. Verifique se o bug já foi reportado nas [Issues](https://github.com/lucascard/ubc-lab-bd/issues)
2. Se não encontrar, crie uma nova issue com:
   - Descrição clara do problema
   - Passos para reproduzir
   - Comportamento esperado vs atual
   - Screenshots (se aplicável)
   - Informações do ambiente

### 💡 Sugerir Melhorias
- Abra uma issue com o label "enhancement"
- Descreva claramente a funcionalidade proposta
- Explique por que seria útil para o projeto

### 🔧 Contribuir com Código
1. Faça um fork do repositório
2. Crie uma branch para sua feature/correção
3. Implemente suas mudanças
4. Escreva testes para suas mudanças
5. Execute os testes e certifique-se de que passam
6. Abra um Pull Request

## 🌿 Workflow de Desenvolvimento

### 1. Preparação
```bash
# Fork e clone do repositório
git clone https://github.com/SEU_USUARIO/ubc-lab-bd.git
cd ubc-lab-bd

# Adicione o repositório upstream
git remote add upstream https://github.com/lucascard/ubc-lab-bd.git

# Configure o ambiente (veja configuracao-ambiente.md)
```

### 2. Criação de Branch
```bash
# Atualize sua branch main
git checkout main
git pull upstream main

# Crie uma nova branch
git checkout -b feature/nome-da-feature
# ou
git checkout -b fix/nome-do-bug
```

### 3. Desenvolvimento
- Faça commits pequenos e com mensagens descritivas
- Siga os padrões de código estabelecidos
- Escreva testes para novas funcionalidades
- Atualize a documentação quando necessário

### 4. Testes
```bash
# Execute todos os testes
pytest

# Verifique a cobertura
pytest --cov=src

# Execute linting
pylint src/
black src/
```

### 5. Pull Request
1. Push sua branch para seu fork
2. Abra um PR no repositório principal
3. Preencha o template do PR
4. Aguarde o review

## 📝 Padrões de Código

### Convenções de Naming
- **Arquivos**: snake_case
- **Classes**: PascalCase
- **Funções/Variáveis**: snake_case
- **Constantes**: UPPER_SNAKE_CASE

### Estrutura de Commits
```
tipo(escopo): descrição breve

Descrição mais detalhada se necessário.

Resolve #123
```

**Tipos de commit:**
- `feat`: nova funcionalidade
- `fix`: correção de bug
- `docs`: documentação
- `style`: formatação
- `refactor`: refatoração
- `test`: testes
- `chore`: tarefas de manutenção

### Exemplo:
```
feat(api): adiciona endpoint para listar usuários

Implementa GET /api/users com paginação e filtros.
Inclui validação de parâmetros e testes unitários.

Resolve #45
```

## 🧪 Testes

### Tipos de Testes
- **Unitários**: Testam componentes isolados
- **Integração**: Testam interação entre componentes
- **End-to-End**: Testam fluxos completos

### Estrutura de Testes
```
tests/
├── unit/
│   ├── test_models.py
│   └── test_services.py
├── integration/
│   └── test_api.py
└── e2e/
    └── test_user_flow.py
```

### Padrões de Testes
```python
def test_funcao_deve_retornar_resultado_esperado():
    # Arrange
    input_data = {"key": "value"}
    expected_result = "expected"
    
    # Act
    result = funcao_testada(input_data)
    
    # Assert
    assert result == expected_result
```

## 📚 Documentação

### Docstrings
```python
def processar_dados(dados: List[Dict]) -> Dict:
    """
    Processa uma lista de dados e retorna estatísticas.
    
    Args:
        dados: Lista de dicionários com dados para processar
        
    Returns:
        Dicionário com estatísticas processadas
        
    Raises:
        ValueError: Se dados estiver vazio
    """
    pass
```

### Documentação de API
- Use docstrings para documentar endpoints
- Inclua exemplos de request/response
- Documente códigos de erro possíveis

## 🔍 Code Review

### Checklist do Revisor
- [ ] Código segue os padrões estabelecidos
- [ ] Testes adequados foram escritos
- [ ] Documentação foi atualizada
- [ ] Não há vazamentos de segurança
- [ ] Performance foi considerada

### Checklist do Autor
- [ ] Código foi testado localmente
- [ ] Testes passam
- [ ] Documentação está atualizada
- [ ] PR tem descrição clara
- [ ] Commits são bem organizados

## 🚀 Release Process

1. **Feature Freeze**: Não aceitar novas features
2. **Testing**: Testes extensivos em staging
3. **Documentation**: Atualizar changelog e docs
4. **Release**: Tag e deploy para produção

## 🆘 Precisa de Ajuda?

- **Dúvidas Gerais**: Abra uma issue com label "question"
- **Chat**: Entre em contato via [canal do projeto]
- **Email**: contato@ubclab.exemplo.com

## 📜 Código de Conduta

Este projeto segue o [Contributor Covenant](https://www.contributor-covenant.org/). Seja respeitoso e construtivo em todas as interações.

---

*Obrigado por contribuir para o UBC Lab BD! 🙏*