# Dev Daily Automation

Agente global que varre todos os seus repositórios e projetos Jira de uma vez, reconstrói seu dia automaticamente e lança horas no Tempo — sem você escrever uma palavra.

Desenvolvido para o time da **Vertigo** com Claude Code.

---

## O que ele faz

Ao digitar `/tempo` no Claude Code, o agente:

1. Lê todos os repositórios que você cadastrou
2. Varre os commits do dia em cada um
3. Cruza com os tickets movimentados nos boards Jira
4. Estima duração de cada atividade
5. Reescreve as descrições em linguagem de negócio (não técnica)
6. Apresenta uma proposta unificada para você confirmar
7. Lança tudo no Jira Tempo via API

Você só confirma — ou ajusta o que precisar antes.

---

## Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- **Git** — [git-scm.com](https://git-scm.com)
- **Node.js** — [nodejs.org](https://nodejs.org) (necessário para o Claude Code)
- **Python 3** — já vem instalado no macOS e na maioria dos Linux

O **Claude Code** é instalado automaticamente pelo `setup.sh` se ainda não estiver presente.

---

## Instalação

O setup é feito **uma única vez** na sua máquina. Depois disso, todos os projetos que você cadastrar são automaticamente incluídos.

### 1. Baixar o projeto

```bash
git clone https://github.com/vertigo/dev-daily-automation
cd dev-daily-automation
chmod +x setup.sh
./setup.sh
```

O script vai conduzir você por **3 etapas** com passo a passo detalhado.

---

### Etapa 1 — Token do Jira

O token do Jira identifica você na API. O script abre o link automaticamente no seu navegador.

**Passo a passo:**

1. Acesse: [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Clique em **"Criar um token de API"**
3. Preencha:
   - **Nome:** `Dev Daily Automation`
   - **Expirar em:** 1 ano (ou o período que preferir)
4. Clique em **"Criar"**
5. Na janela que aparece, clique em **"Copiar"**

> ⚠️ **Importante:** você não consegue ver o token depois de fechar a janela. Copie antes de continuar.

6. Cole no terminal quando o setup pedir

---

### Etapa 2 — Token do Tempo

O token do Tempo fica dentro do próprio Jira da Vertigo. O caminho é diferente do token do Jira — siga com atenção.

**Passo a passo:**

1. Acesse: [https://vertigobr.atlassian.net](https://vertigobr.atlassian.net)

2. No menu lateral esquerdo, localize o ícone do **Tempo Planner**

3. Role até o final do menu lateral do Tempo e clique em **"Definições"** (ícone de engrenagem)

   > ⚠️ **Atenção:** use as **Definições do menu do Tempo** — não as do Jira.  
   > As do Jira ficam no canto superior direito da tela e são diferentes.

4. No menu lateral das Definições do Tempo, procure a seção **"Acesso aos Dados"** e clique em **"Integração API"**

5. Clique no botão **"+ Novo Token"** (canto superior direito)

6. Preencha:
   - **Nome:** `Dev Daily Automation`
   - **Fim:** data de expiração desejada
   - **Acesso:** selecione **"Acesso Total"**

7. Clique em **"Confirmar"**

8. O token aparece na lista. Clique nos **"..."** ao lado de *Dev Daily Automation* e escolha **"Copiar"**

   > ⚠️ **Guarde esse token** em local seguro — você vai precisar dele em reinstalações.

9. Cole no terminal quando o setup pedir

---

### Etapa 3 — Primeiro projeto

O setup pede 3 informações sobre o seu primeiro repositório:

**Nome do projeto** — nome legível, aparece na proposta de horas.  
Ex: `Plataforma Convert`

**Caminho da pasta** — onde o repositório está no seu computador.  
Dica: abra outro terminal, entre na pasta do projeto e rode `pwd` para ver o caminho.  
Ex: `~/Documentos/Vertigo/Projetos/Convert/convert-spa`

**Chave do board Jira** — o prefixo dos tickets daquele projeto.  
Ex: se o ticket é `CONVERT-42`, a chave é `CONVERT`

> Para descobrir a chave: abra qualquer ticket do projeto no Jira — as letras antes do traço são a chave.

---

## Adicionar mais projetos

Sempre que precisar incluir um novo repositório, rode de qualquer pasta:

```bash
~/dev-daily-automation/setup.sh --add-repo
```

O script pede as mesmas 3 informações (nome, caminho, chave Jira) e adiciona à lista. O `/tempo` já inclui o novo projeto na próxima vez que rodar.

---

## Gerenciar projetos cadastrados

```bash
# Ver todos os projetos cadastrados
./setup.sh --list-repos

# Remover um projeto da lista
./setup.sh --remove-repo
```

Você também pode editar diretamente o arquivo `~/.claude/repos.json`:

```json
[
  {
    "nome": "Plataforma Convert",
    "path": "~/Documentos/Vertigo/Projetos/Convert/convert-spa",
    "jira": "CONVERT"
  },
  {
    "nome": "App Mobile",
    "path": "~/Documentos/Vertigo/Projetos/mobile",
    "jira": "MOB"
  }
]
```

---

## Uso diário

Abra o Claude Code de **qualquer pasta** — não precisa estar dentro de nenhum projeto:

```bash
claude
```

### `/tempo` — Lançar horas

O comando principal. Varre todos os projetos e propõe o lançamento:

```
/tempo
```

Para lançar horas de um dia específico:

```
/tempo ontem
/tempo 06/05/2026
/tempo 2026-05-06
```

**Exemplo de proposta gerada:**

```
Proposta de lançamento para quarta-feira, 06/05/2026:

── Convert (CONVERT) ─────────────────────────────────────────
  CONVERT-483   Painel de resumo financeiro com total de horas   2h
  CONVERT-480   Correção de bug no cálculo de horas extras       1h

── App Mobile (MOB) ──────────────────────────────────────────
  MOB-11        Ajuste de layout na tela de onboarding           30m

──────────────────────────────────────────────────────────────
Total: 3h30   em 3 tickets

Confirma esse lançamento?
→ "ok" para confirmar tudo
→ Ou diga o que ajustar (ex: "CONVERT-483 foram 3h" ou "remove MOB-11")
```

O agente **nunca lança nada sem sua confirmação**. Você pode ajustar horas e descrições antes de aprovar.

---

### `/daily` — Resumo de stand-up

Gera o resumo do dia para colar no canal do time:

```
/daily
```

**Exemplo de saída:**

```
Ontem:
• Implementei o painel de resumo financeiro no Convert (CONVERT-483)
• Corrigi bug no cálculo de horas extras (CONVERT-480)

Hoje:
• Continuar CONVERT-483 — ajustes de responsividade
• Iniciar revisão do PR de autenticação

Impedimentos:
• Nenhum
```

---

### `/pr` — Descrição de Pull Request

Rode **dentro do repositório**. Lê o diff, cruza com o ticket Jira e gera título e descrição completa:

```bash
cd ~/Documentos/Vertigo/Projetos/Convert/convert-spa
claude
/pr
```

**Exemplo de saída:**

```markdown
feat(financeiro): adiciona painel de resumo com total de horas e valor

## O que foi feito
Implementado quadro de resumo financeiro na tela principal, exibindo
o total de horas trabalhadas e o valor correspondente em reais.

## Como testar
1. Acessar a tela de relatório financeiro
2. Verificar se o quadro azul aparece no topo com os totais corretos
3. Alterar o período e confirmar que os valores atualizam

## Checklist
- [x] Testes escritos
- [x] Sem console.log esquecido
- [ ] Migração de banco incluída (não necessário)

Closes CONVERT-483
```

---

### `/commit` — Mensagem de commit semântica

Rode **dentro do repositório** com arquivos staged:

```bash
git add -p   # selecione o que quer commitar
claude
/commit
```

Gera a mensagem no padrão Conventional Commits e faz o commit após confirmação:

```
feat(financeiro): adiciona quadro de totais de horas e valor em reais
```

---

## Como o agente reconstrói seu dia

O `/tempo` cruza três fontes para inferir o que foi feito e quanto tempo levou — sem você precisar lembrar de nada:

**Commits** — `git log` em cada repositório cadastrado. O diff e a mensagem indicam o que foi alterado.

**Tickets Jira** — via MCP, busca todos os tickets que você moveu de coluna, comentou ou teve atribuição na data solicitada, em todos os boards cadastrados.

**Estimativa de duração** — calculada pelo tamanho do diff:
- Commit pequeno (menos de 30 linhas): ~30 minutos
- Commit médio (30–150 linhas): ~1 hora
- Commit grande ou múltiplos commits: ~2 a 3 horas
- Atividade só em ticket (sem commits): ~30 minutos a 1 hora

As descrições são reescritas em linguagem de negócio — não técnica — para fazer sentido para quem lê no Tempo.

---

## Estrutura de arquivos

```
dev-daily-automation/         ← repositório que você clonou
  setup.sh                    ← script de instalação (macOS/Linux)
  setup.ps1                   ← script de instalação (Windows)
  README.md                   ← este arquivo
  .claude/
    skills/
      tempo/SKILL.md          ← lógica do /tempo
      daily/SKILL.md          ← lógica do /daily
      pr/SKILL.md             ← lógica do /pr
      commit/SKILL.md         ← lógica do /commit

~/.claude/                    ← instalado na sua máquina pelo setup
  skills/                     ← cópia das skills acima (global)
  settings.json               ← credenciais MCP (só na sua máquina)
  repos.json                  ← lista de projetos cadastrados
  tempo.log                   ← log do hook automático (se ativado)
```

> O `settings.json` com seus tokens **nunca vai para nenhum repositório** — fica apenas em `~/.claude/` na sua máquina.

---

## Hook automático às 17h (opcional)

Se ativado durante o setup, o agente propõe o lançamento de horas todo dia útil às 17h. O log fica em `~/.claude/tempo.log`.

Para desativar:

```bash
crontab -e
# Remova a linha que contém: claude --print '/tempo'
```

---

## Dúvidas frequentes

**O `/tempo` precisa estar dentro de um repo?**  
Não. Rode de qualquer pasta — inclusive do home (`cd ~` e depois `claude`).

**Trabalho em múltiplos projetos no mesmo dia. O `/tempo` pega tudo?**  
Sim. Ele varre todos os repositórios cadastrados em `~/.claude/repos.json` de uma vez e consolida numa proposta única.

**O agente pode lançar horas erradas?**  
Não sem a sua confirmação. Ele sempre apresenta a proposta primeiro. Você aprova, ajusta ou cancela antes de qualquer coisa ser enviada ao Tempo.

**Como mudar o caminho de um projeto?**  
Edite `~/.claude/repos.json` e atualize o campo `path` do projeto correspondente.

**Preciso rodar o setup de novo ao entrar num projeto novo?**  
Não. Só rode `./setup.sh --add-repo` para cadastrar o novo repositório.

**Os tokens ficam seguros?**  
Ficam em `~/.claude/settings.json` — arquivo local da sua máquina. Não é versionado, não vai para nenhum repositório, não é compartilhado.

**Como reinstalar depois de trocar de máquina?**  
Rode `./setup.sh` novamente na nova máquina. Você vai precisar dos tokens do Jira e do Tempo — por isso é recomendado guardá-los em local seguro (como um gerenciador de senhas).
