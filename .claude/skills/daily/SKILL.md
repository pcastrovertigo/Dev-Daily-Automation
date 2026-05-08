---
name: daily
description: Monta o resumo do stand-up varrendo todos os repositórios e boards cadastrados. Roda de qualquer pasta.
allowed-tools: Bash(git log:*), Bash(cat:*), mcp__jira__*
---

# Gerar resumo de stand-up — multi-projeto

## Passo 1 — Ler projetos cadastrados

```bash
cat ~/.claude/repos.json
```

## Passo 2 — Varrer commits de ontem e hoje

Para CADA repo:
```bash
cd <path> && git log --since="yesterday 17:00" --until="now" \
  --author="$(git config user.email)" --oneline 2>/dev/null
```

## Passo 3 — Varrer tickets com movimento

Via MCP Jira, para cada board:
- Tickets movidos de coluna nas últimas 24h
- Tickets comentados ou atualizados por mim

## Passo 4 — Gerar resumo

Formato curto, pronto para colar no canal do time:

```
Ontem:
• [resultado, não tarefa — mencione o projeto entre parênteses se relevante]
• [segundo item se houver]

Hoje:
• [o que está planejado]

Impedimentos:
• Nenhum
```

Regras:
- Máximo 3 itens por seção
- Uma linha por item
- Sem jargão técnico
- Mencione o projeto só quando necessário para contexto
- Se não houver commits, baseie-se nos tickets e seja honesto sobre isso
