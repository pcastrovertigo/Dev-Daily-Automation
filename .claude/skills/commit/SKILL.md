---
name: commit
description: Gera uma mensagem de commit semântica (Conventional Commits) a partir das mudanças staged. Faz o commit automaticamente após confirmação.
allowed-tools: Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
argument-hint: [mensagem opcional — substitui a gerada automaticamente]
---

# Gerar e fazer commit

## Passo 1 — Ver o que está staged

```bash
git diff --cached --stat
git diff --cached
```

Se não houver nada staged, avise o usuário e sugira `git add -p` para selecionar.

## Passo 2 — Gerar a mensagem

Se `$ARGUMENTS` foi fornecido, use como mensagem (apenas formate no padrão abaixo).
Caso contrário, analise o diff e crie a mensagem.

**Formato obrigatório — Conventional Commits:**
```
tipo(escopo): descrição curta em português (máx 72 chars)

[corpo opcional — explique o porquê se não for óbvio]

[rodapé opcional — Closes EX-42]
```

**Tipos válidos:**
- `feat` — nova funcionalidade
- `fix` — correção de bug
- `refactor` — refatoração sem mudança de comportamento
- `chore` — tarefa técnica (deps, config, CI)
- `docs` — documentação
- `test` — testes
- `perf` — melhoria de performance

**Escopo:** nome do módulo/feature afetado (ex: `auth`, `billing`, `api`)

## Passo 3 — Confirmar e commitar

Mostre a mensagem gerada e pergunte:
`Confirma esse commit? (s/n)`

Após confirmação, execute:
```bash
git commit -m "[mensagem gerada]"
```

Mostre o hash do commit criado.
