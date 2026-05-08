---
name: tempo
description: Lança horas no Jira Tempo varrendo TODOS os repositórios e boards cadastrados em ~/.claude/repos.json. Roda de qualquer pasta. Nunca lança sem confirmação.
allowed-tools: Bash(git log:*), Bash(git -C:*), Bash(git config:*), Bash(cat:*), Bash(python3:*), mcp__jira__*, mcp__tempo__*
argument-hint: [data — padrão: hoje | aceita: "ontem", "06/05/2026", "2026-05-06"]
---

# Lançar horas — agente multi-projeto

## Passo 0 — Calcular data e dia da semana CORRETAMENTE

**NUNCA assuma o dia da semana. Sempre calcule via bash.**

```bash
python3 -c "
from datetime import datetime, timedelta

arg = '$ARGUMENTS'.strip()

if arg in ('ontem', 'yesterday'):
    d = datetime.today() - timedelta(days=1)
elif arg == '' or arg.lower() == 'hoje':
    d = datetime.today()
else:
    for fmt in ('%d/%m/%Y', '%Y-%m-%d', '%d/%m'):
        try:
            d = datetime.strptime(arg, fmt)
            if fmt == '%d/%m':
                d = d.replace(year=datetime.today().year)
            break
        except:
            pass

dias = ['segunda-feira','terca-feira','quarta-feira','quinta-feira','sexta-feira','sabado','domingo']
print(dias[d.weekday()] + ', ' + d.strftime('%d/%m/%Y'))
print(d.strftime('%Y-%m-%d'))
"
```

- Linha 1 da saída = rótulo para exibir ao usuário (ex: `quarta-feira, 06/05/2026`)
- Linha 2 da saída = `DATA_ISO` no formato `YYYY-MM-DD` (ex: `2026-05-06`)

Use `DATA_ISO` em **todos** os filtros de git e Jira daqui para frente.
Nunca use "hoje", "ontem", `startOfDay()` ou datas relativas nos filtros — sempre a data absoluta calculada.

## Passo 1 — Ler lista de projetos

```bash
cat ~/.claude/repos.json
```

Se o arquivo estiver vazio ou não existir, informe:
> "Nenhum repositório cadastrado. Rode: ./setup.sh --add-repo"
e pare aqui.

## Passo 2 — Varrer commits de cada repo

Para CADA repo da lista, execute com `DATA_ISO`:

```bash
git -C <path_com_home_expandido> log --all \
  --after="<DATA_ISO>T00:00:00" \
  --before="<DATA_ISO>T23:59:59" \
  --format="%H|%s|%ai|%D" 2>/dev/null || echo "SEM_COMMITS"
```

- Expanda `~` para o valor real de `$HOME` antes de usar o caminho
- Use `--all` para pegar commits de qualquer branch, não só a atual
- Se o repo não existir no caminho, pule silenciosamente
- Colete todos os commits agrupados por repo

## Passo 3 — Varrer tickets Jira de cada board

Para CADA board (campo `jira` do repos.json), busque via MCP Jira com filtro de data **exato e absoluto**:

```
project = "<JIRA_KEY>"
AND assignee = currentUser()
AND updated >= "<DATA_ISO> 00:00"
AND updated <= "<DATA_ISO> 23:59"
ORDER BY updated DESC
```

**Regras críticas — leia com atenção:**

- Use sempre `DATA_ISO` no filtro, nunca `startOfDay()` ou expressões relativas
- **NUNCA reporte worklogs de outra data** — se a consulta retornar items de outros dias, ignore-os
- **NUNCA invente, estime ou suponha worklogs já existentes** — reporte apenas o que o MCP retornar literalmente para `DATA_ISO`
- Quando o usuário pede "ontem" e hoje é quinta, `DATA_ISO` é `2026-05-06` — os worklogs de hoje (`2026-05-07`) não existem para esse filtro
- Se a consulta retornar vazio: escreva explicitamente "Nenhum worklog encontrado no Jira para essa data"
- Se retornar worklogs reais: mostre-os como "já lançados" e pergunte se quer complementar

## Passo 4 — Cruzar e consolidar

Regras de agrupamento:
1. Se um commit referencia um ticket na mensagem (ex: `CONVERT-483`, `fix CONVERT-483`), agrupe-os
2. Se não há referência explícita, associe pelo repo + board correspondente
3. Estime duração **apenas para itens sem worklog já lançado**:
   - 1 commit pequeno (diff < 30 linhas): ~30m
   - 1 commit médio (30–150 linhas): ~1h
   - 1 commit grande (150+ linhas) ou múltiplos commits: ~2h–3h
   - Atividade só em ticket (sem commits): ~30m–1h
4. Cap diário: se o total passar de 8h, reduza proporcionalmente e mencione o ajuste

## Passo 5 — Redigir descrições automaticamente

Para CADA entrada, escreva a descrição seguindo estas regras:
- **NÃO copie** a mensagem de commit — reescreva em português claro
- Foque no **resultado de negócio**, não na implementação técnica
- Máximo 1 linha, ~80 caracteres
- Exemplos:
  - `quadro azul com o total de horas e total em reais` → `Implementação do painel de resumo financeiro com total de horas e valor`
  - `fix: juros compostos` → `Correção do cálculo de juros no módulo de simulação`
  - `chore: bump deps` → `Atualização de dependências de segurança`

## Passo 6 — Apresentar proposta unificada

```
Proposta de lançamento para <DIA_DA_SEMANA_CALCULADO>, <DATA>:

── Convert (CONVERT) ────────────────────────────────────
  CONVERT-483   Painel de resumo financeiro com total de horas   1h30m

─────────────────────────────────────────────────────────
Total: 1h30m   em 1 ticket

Confirma esse lançamento?
→ "ok" para confirmar tudo
→ Ou diga o que ajustar (ex: "CONVERT-483 foram 2h" ou "adiciona mais 30m")
```

**NÃO lance nada antes da resposta do usuário.**

## Passo 7 — Processar ajustes (se houver)

Se o usuário pedir mudança, ajuste e mostre a tabela novamente com as alterações destacadas.
Peça confirmação de novo.

## Passo 8 — Lançar no Tempo via MCP

Após confirmação, para cada item:
```
mcp__tempo__create_worklog:
  issue_key:   <chave do ticket>
  time_spent:  <ex: "1h 30m", "30m", "2h">
  description: <descrição do Passo 5>
  started:     <DATA_ISO>T09:00:00.000+0000
```

Para itens sem ticket: pergunte ao usuário qual ticket usar antes de lançar.

## Passo 9 — Confirmar resultado

```
Horas lançadas com sucesso!

✓ CONVERT-483  · 1h30m  · Painel de resumo financeiro

Total: 1h30m em 1 lançamento
```

Se algum lançamento falhar, mostre o erro e sugira tentar manualmente.
