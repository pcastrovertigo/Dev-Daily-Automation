---
name: pr
description: Gera título e descrição completa para o Pull Request atual, seguindo o template do time e linkando o ticket Jira correspondente.
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git branch:*), mcp__jira__*
---

# Gerar descrição de Pull Request

## Passo 1 — Coletar contexto

```bash
git diff main...HEAD --stat
git log main...HEAD --oneline
git branch --show-current
```

Extraia o ticket Jira do nome da branch (padrão: `feat/EX-42-descricao` → ticket `EX-42`).
Busque via MCP Jira os detalhes do ticket: título, descrição, critérios de aceite.

## Passo 2 — Analisar o diff

```bash
git diff main...HEAD
```

Entenda **o que mudou e por quê** — não apenas o que foi alterado tecnicamente.

## Passo 3 — Gerar a descrição

Produza o texto completo no seguinte formato, em português:

```markdown
## O que foi feito

[2-3 frases explicando a mudança em linguagem que qualquer pessoa do time entenda.
Foco no problema resolvido, não na implementação técnica.]

## Por que foi feito assim

[Explique a decisão técnica principal, se houver trade-off relevante.]

## Como testar

1. [Passo concreto]
2. [Passo concreto]
3. [Resultado esperado]

## Checklist

- [ ] Testes escritos / atualizados
- [ ] Sem console.log ou debug esquecido
- [ ] Variáveis de ambiente documentadas (se necessário)
- [ ] Migração de banco incluída (se necessário)

## Ticket relacionado

Closes [TICKET-KEY]
```

## Passo 4 — Sugerir título

Sugira um título no formato Conventional Commits:
`tipo(escopo): descrição curta em português`

Exemplo: `feat(auth): adiciona autenticação OAuth com Google`

## Passo 5 — Apresentar resultado

Mostre o título sugerido e a descrição completa.
Pergunte se o usuário quer ajustar algo antes de copiar.
