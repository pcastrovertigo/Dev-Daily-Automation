#!/bin/bash

# =============================================================================
# Dev Daily Automation — Setup Global
# =============================================================================

set -e

VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
VERMELHO='\033[0;31m'
RESET='\033[0m'
NEGRITO='\033[1m'
DIM='\033[2m'

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
REPOS_FILE="$CLAUDE_DIR/repos.json"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# URL fixa — produto interno Vertigo
JIRA_URL="https://vertigobr.atlassian.net"

# Abre URL no navegador (macOS e Linux)
abrir_url() {
  if command -v xdg-open &> /dev/null; then
    xdg-open "$1" 2>/dev/null &
  elif command -v open &> /dev/null; then
    open "$1" 2>/dev/null &
  fi
}

aguardar() {
  echo -e "  ${DIM}Pressione Enter quando estiver pronto...${RESET}"
  read -r
}

separador() {
  echo -e "  ${DIM}─────────────────────────────────────────────────${RESET}"
}

# =============================================================================
# FLAG --add-repo
# =============================================================================
if [[ "$1" == "--add-repo" ]]; then
  echo ""
  echo -e "  ${AZUL}${NEGRITO}Adicionar novo repositório${RESET}"
  echo ""
  read -p "  Nome do projeto (ex: App Mobile) > " NOME
  read -p "  Caminho completo do repo (ex: ~/projetos/mobile) > " REPO_PATH
  echo ""
  echo -e "  ${DIM}A chave do board é o prefixo dos tickets.${RESET}"
  echo -e "  ${DIM}Ex: se o ticket é CONVERT-42, a chave é CONVERT${RESET}"
  read -p "  Chave do board Jira > " JIRA_KEY

  REPO_PATH_EXPANDED="${REPO_PATH/#\~/$HOME}"
  if [ ! -d "$REPO_PATH_EXPANDED" ]; then
    echo ""
    echo -e "  ${VERMELHO}⚠ Pasta não encontrada: $REPO_PATH_EXPANDED${RESET}"
    echo -e "  ${DIM}Verifique o caminho e tente novamente.${RESET}"
    exit 1
  fi

  [ ! -f "$REPOS_FILE" ] && echo "[]" > "$REPOS_FILE"

  python3 - <<PYEOF
import json
with open("$REPOS_FILE") as f:
    repos = json.load(f)
repos.append({"nome": "$NOME", "path": "$REPO_PATH", "jira": "$JIRA_KEY"})
with open("$REPOS_FILE", "w") as f:
    json.dump(repos, f, indent=2, ensure_ascii=False)
print(f"  Total cadastrado: {len(repos)} projeto(s)")
PYEOF

  echo ""
  echo -e "  ${VERDE}✓ Repositório adicionado!${RESET}"
  echo ""
  echo -e "  ${NEGRITO}Projetos cadastrados:${RESET}"
  python3 -c "
import json
with open('$REPOS_FILE') as f:
    repos = json.load(f)
for i, r in enumerate(repos, 1):
    print(f'    {i}. {r[\"nome\"]} ({r[\"jira\"]}) → {r[\"path\"]}')
"
  echo ""
  exit 0
fi

# =============================================================================
# FLAG --list-repos
# =============================================================================
if [[ "$1" == "--list-repos" ]]; then
  if [ ! -f "$REPOS_FILE" ]; then
    echo "  Nenhum repo cadastrado. Rode: ./setup.sh --add-repo"
    exit 0
  fi
  echo ""
  echo -e "  ${NEGRITO}Projetos cadastrados:${RESET}"
  python3 -c "
import json
with open('$REPOS_FILE') as f:
    repos = json.load(f)
for i, r in enumerate(repos, 1):
    print(f'    {i}. {r[\"nome\"]} ({r[\"jira\"]}) → {r[\"path\"]}')
"
  echo ""
  exit 0
fi

# =============================================================================
# FLAG --remove-repo
# =============================================================================
if [[ "$1" == "--remove-repo" ]]; then
  [ ! -f "$REPOS_FILE" ] && echo "  Nenhum repo cadastrado." && exit 0
  echo ""
  echo -e "  ${NEGRITO}Qual projeto remover?${RESET}"
  python3 -c "
import json
with open('$REPOS_FILE') as f:
    repos = json.load(f)
for i, r in enumerate(repos, 1):
    print(f'    {i}. {r[\"nome\"]} ({r[\"jira\"]})')
"
  read -p "  Número > " NUM
  python3 - <<PYEOF
import json
with open('$REPOS_FILE') as f:
    repos = json.load(f)
idx = int("$NUM") - 1
removed = repos.pop(idx)
with open('$REPOS_FILE', 'w') as f:
    json.dump(repos, f, indent=2, ensure_ascii=False)
print(f"  Removido: {removed['nome']}")
PYEOF
  exit 0
fi

# =============================================================================
# INSTALAÇÃO INICIAL
# =============================================================================

clear
echo ""
echo -e "  ${AZUL}${NEGRITO}╔══════════════════════════════════════════════╗${RESET}"
echo -e "  ${AZUL}${NEGRITO}║      Dev Daily Automation · Setup            ║${RESET}"
echo -e "  ${AZUL}${NEGRITO}║      Automação de horas e PRs com Claude     ║${RESET}"
echo -e "  ${AZUL}${NEGRITO}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Este script vai configurar tudo em ${NEGRITO}3 etapas${RESET}:"
echo -e "  ${CIANO}  1.${RESET} Token do Jira"
echo -e "  ${CIANO}  2.${RESET} Token do Tempo"
echo -e "  ${CIANO}  3.${RESET} Seu primeiro projeto"
echo ""
aguardar

# --------------------------------------------------
# Verificar dependências
# --------------------------------------------------
echo -e "  ${AMARELO}Verificando dependências...${RESET}"
echo ""

if ! command -v python3 &> /dev/null; then
  echo -e "  ${VERMELHO}❌ Python3 não encontrado.${RESET}"
  echo -e "  ${DIM}Instale em python.org e rode o setup novamente.${RESET}"
  exit 1
fi
echo -e "  ${VERDE}✓ Python3${RESET}"

if ! command -v git &> /dev/null; then
  echo -e "  ${VERMELHO}❌ Git não encontrado.${RESET}"
  echo -e "  ${DIM}Instale em git-scm.com e rode o setup novamente.${RESET}"
  exit 1
fi
echo -e "  ${VERDE}✓ Git${RESET}"

if ! command -v claude &> /dev/null; then
  echo -e "  ${AMARELO}  Claude Code não encontrado. Instalando...${RESET}"
  npm install -g @anthropic-ai/claude-code
fi
echo -e "  ${VERDE}✓ Claude Code${RESET}"

mkdir -p "$SKILLS_DIR"
echo ""
aguardar

# ==============================================================================
# ETAPA 1 — TOKEN DO JIRA
# ==============================================================================
clear
echo ""
echo -e "  ${CIANO}${NEGRITO}Etapa 1 de 3 — Token do Jira${RESET}"
separador
echo ""
echo -e "  O token do Jira é como uma senha de API que identifica"
echo -e "  você nas integrações. Siga o passo a passo:"
echo ""

echo -e "  ${NEGRITO}[ Passo 1 ]${RESET} Abrir a página de tokens do Atlassian"
echo ""
echo -e "  ${AZUL}  https://id.atlassian.com/manage-profile/security/api-tokens${RESET}"
echo ""
echo -e "  ${DIM}  Abrindo no seu navegador agora...${RESET}"
abrir_url "https://id.atlassian.com/manage-profile/security/api-tokens"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 2 ]${RESET} Criar o token"
echo ""
echo -e "  ${DIM}  → Clique em ${RESET}${NEGRITO}\"Criar um token de API\"${RESET}"
echo -e "  ${DIM}  → No campo ${RESET}${NEGRITO}Nome${RESET}${DIM}, digite: ${RESET}${NEGRITO}Dev Daily Automation${RESET}"
echo -e "  ${DIM}  → Em ${RESET}${NEGRITO}Expirar em${RESET}${DIM}, escolha ${RESET}${NEGRITO}1 ano${RESET}${DIM} (ou o período que preferir)${RESET}"
echo -e "  ${DIM}  → Clique em ${RESET}${NEGRITO}\"Criar\"${RESET}"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 3 ]${RESET} Copiar o token"
echo ""
echo -e "  ${DIM}  → Uma janela vai exibir o token gerado${RESET}"
echo -e "  ${DIM}  → Clique em ${RESET}${NEGRITO}\"Copiar\"${RESET}${DIM} antes de fechar${RESET}"
echo ""
echo -e "  ${VERMELHO}  ⚠ Importante: você não consegue ver esse token depois de fechar.${RESET}"
echo -e "  ${VERMELHO}    Copie agora antes de continuar.${RESET}"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 4 ]${RESET} Cole o token aqui"
echo ""
echo -e "  ${DIM}  O texto não vai aparecer na tela enquanto você digita — isso é normal.${RESET}"
echo ""
read -s -p "  Token do Jira > " JIRA_TOKEN
echo ""
echo ""

if [ -z "$JIRA_TOKEN" ]; then
  echo -e "  ${VERMELHO}❌ Token vazio. Rode o setup novamente.${RESET}"
  exit 1
fi
echo -e "  ${VERDE}✓ Token do Jira salvo${RESET}"
echo ""

echo -e "  ${NEGRITO}[ Passo 5 ]${RESET} Qual é o seu email cadastrado no Jira?"
echo ""
echo -e "  ${DIM}  (o mesmo que você usa para entrar em vertigobr.atlassian.net)${RESET}"
echo ""
read -p "  Email > " JIRA_EMAIL
echo ""

if [ -z "$JIRA_EMAIL" ]; then
  echo -e "  ${VERMELHO}❌ Email vazio. Rode o setup novamente.${RESET}"
  exit 1
fi
echo -e "  ${VERDE}✓ Email salvo${RESET}"
echo ""
separador
echo -e "  ${VERDE}${NEGRITO}✓ Etapa 1 concluída!${RESET}"
echo ""
aguardar

# ==============================================================================
# ETAPA 2 — TOKEN DO TEMPO
# ==============================================================================
clear
echo ""
echo -e "  ${CIANO}${NEGRITO}Etapa 2 de 3 — Token do Tempo${RESET}"
separador
echo ""
echo -e "  O token do Tempo permite que o agente lance horas no seu nome."
echo -e "  O caminho até ele fica dentro do próprio Jira:"
echo ""

echo -e "  ${NEGRITO}[ Passo 1 ]${RESET} Abrir o Jira da Vertigo"
echo ""
echo -e "  ${AZUL}  https://vertigobr.atlassian.net${RESET}"
echo ""
echo -e "  ${DIM}  Abrindo no seu navegador agora...${RESET}"
abrir_url "https://vertigobr.atlassian.net"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 2 ]${RESET} Abrir as Definições do Tempo"
echo ""
echo -e "  ${DIM}  → No menu lateral esquerdo, procure o ícone do ${RESET}${NEGRITO}Tempo Planner${RESET}"
echo -e "  ${DIM}  → Role até o final do menu lateral do Tempo${RESET}"
echo -e "  ${DIM}  → Clique em ${RESET}${NEGRITO}\"Definições\"${RESET}${DIM} (ícone de engrenagem, parte inferior do menu)${RESET}"
echo ""
echo -e "  ${VERMELHO}  ⚠ Use as Definições do menu do TEMPO — não as do Jira${RESET}"
echo -e "  ${VERMELHO}    (as do Jira ficam no canto superior direito da tela)${RESET}"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 3 ]${RESET} Ir para Integração API"
echo ""
echo -e "  ${DIM}  → No menu lateral das Definições do Tempo${RESET}"
echo -e "  ${DIM}  → Procure a seção ${RESET}${NEGRITO}\"Acesso aos Dados\"${RESET}"
echo -e "  ${DIM}  → Clique em ${RESET}${NEGRITO}\"Integração API\"${RESET}"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 4 ]${RESET} Criar o token"
echo ""
echo -e "  ${DIM}  → Clique no botão ${RESET}${NEGRITO}\"+ Novo Token\"${RESET}${DIM} (canto superior direito)${RESET}"
echo -e "  ${DIM}  → ${RESET}${NEGRITO}Nome:${RESET}${DIM}    Dev Daily Automation${RESET}"
echo -e "  ${DIM}  → ${RESET}${NEGRITO}Fim:${RESET}${DIM}     escolha a data de expiração${RESET}"
echo -e "  ${DIM}  → ${RESET}${NEGRITO}Acesso:${RESET}${DIM}  selecione ${RESET}${NEGRITO}\"Acesso Total\"${RESET}"
echo -e "  ${DIM}  → Clique em ${RESET}${NEGRITO}\"Confirmar\"${RESET}"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 5 ]${RESET} Copiar o token"
echo ""
echo -e "  ${DIM}  → O token aparece na lista com o nome ${RESET}${NEGRITO}Dev Daily Automation${RESET}"
echo -e "  ${DIM}  → Clique nos ${RESET}${NEGRITO}\"...\"${RESET}${DIM} ao lado dele e escolha ${RESET}${NEGRITO}\"Copiar\"${RESET}"
echo ""
echo -e "  ${VERMELHO}  ⚠ Guarde esse token — você vai precisar dele em reinstalações.${RESET}"
echo ""
aguardar

echo -e "  ${NEGRITO}[ Passo 6 ]${RESET} Cole o token aqui"
echo ""
echo -e "  ${DIM}  O texto não vai aparecer na tela enquanto você digita — isso é normal.${RESET}"
echo ""
read -s -p "  Token do Tempo > " TEMPO_TOKEN
echo ""
echo ""

if [ -z "$TEMPO_TOKEN" ]; then
  echo -e "  ${VERMELHO}❌ Token vazio. Rode o setup novamente.${RESET}"
  exit 1
fi
echo -e "  ${VERDE}✓ Token do Tempo salvo${RESET}"
echo ""
separador
echo -e "  ${VERDE}${NEGRITO}✓ Etapa 2 concluída!${RESET}"
echo ""
aguardar

# ==============================================================================
# ETAPA 3 — PRIMEIRO PROJETO
# ==============================================================================
clear
echo ""
echo -e "  ${CIANO}${NEGRITO}Etapa 3 de 3 — Seu primeiro projeto${RESET}"
separador
echo ""
echo -e "  Vamos cadastrar o primeiro repositório que o agente vai monitorar."
echo -e "  ${DIM}  Você pode adicionar mais depois com: ./setup.sh --add-repo${RESET}"
echo ""

read -p "  Nome do projeto (ex: Plataforma Convert) > " NOME_PROJETO
echo ""

echo -e "  Agora o caminho da pasta no seu computador."
echo -e "  ${DIM}  Dica: abra outro terminal, entre na pasta do projeto e rode ${RESET}${NEGRITO}pwd${RESET}${DIM} para ver o caminho.${RESET}"
echo ""
read -p "  Caminho da pasta > " REPO_PATH
echo ""

echo -e "  A chave do board é o prefixo dos tickets."
echo -e "  ${DIM}  Ex: se o ticket é ${RESET}${NEGRITO}CONVERT-42${RESET}${DIM}, a chave é ${RESET}${NEGRITO}CONVERT${RESET}"
echo ""
read -p "  Chave do board Jira > " JIRA_KEY
echo ""

REPO_PATH_EXPANDED="${REPO_PATH/#\~/$HOME}"
AVISO_CAMINHO=""
if [ ! -d "$REPO_PATH_EXPANDED" ]; then
  AVISO_CAMINHO="⚠ Pasta não encontrada — verifique o caminho em ~/.claude/repos.json"
fi

echo -e "  ${NEGRITO}Lançamento automático às 17h?${RESET}"
echo -e "  ${DIM}  O Claude vai propor os lançamentos todo dia útil no fim do expediente.${RESET}"
echo -e "  ${DIM}  Você ainda confirma antes de qualquer lançamento ser feito.${RESET}"
echo ""
read -p "  Ativar? (s/n) > " HOOK_AUTOMATICO
echo ""

# --------------------------------------------------
# Salvar tudo
# --------------------------------------------------
echo -e "  ${AMARELO}Salvando configurações...${RESET}"
echo ""

# MCP settings
[ -f "$SETTINGS_FILE" ] && cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"

cat > "$SETTINGS_FILE" << EOF
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-jira"],
      "env": {
        "JIRA_URL": "${JIRA_URL}",
        "JIRA_EMAIL": "${JIRA_EMAIL}",
        "JIRA_API_TOKEN": "${JIRA_TOKEN}"
      }
    },
    "tempo": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-tempo"],
      "env": {
        "TEMPO_API_TOKEN": "${TEMPO_TOKEN}",
        "JIRA_URL": "${JIRA_URL}"
      }
    }
  }
}
EOF
echo -e "  ${VERDE}✓ Credenciais salvas em ~/.claude/settings.json${RESET}"

# Skills globais
cp -r "$SCRIPT_DIR/.claude/skills/"* "$SKILLS_DIR/"
echo -e "  ${VERDE}✓ Skills instaladas em ~/.claude/skills/${RESET}"

# Primeiro repo
python3 - <<PYEOF
import json
repos = [{"nome": "$NOME_PROJETO", "path": "$REPO_PATH", "jira": "$JIRA_KEY"}]
with open("$REPOS_FILE", "w") as f:
    json.dump(repos, f, indent=2, ensure_ascii=False)
PYEOF
echo -e "  ${VERDE}✓ Projeto salvo em ~/.claude/repos.json${RESET}"

# Hook cron
if [[ "$HOOK_AUTOMATICO" =~ ^[Ss]$ ]]; then
  (crontab -l 2>/dev/null; echo "0 17 * * 1-5 claude --print '/tempo' >> ~/.claude/tempo.log 2>&1") | crontab -
  echo -e "  ${VERDE}✓ Hook ativado: lançamento proposto todo dia útil às 17h${RESET}"
fi

# ==============================================================================
# RESUMO FINAL
# ==============================================================================
clear
echo ""
echo -e "  ${VERDE}${NEGRITO}╔══════════════════════════════════════════════╗${RESET}"
echo -e "  ${VERDE}${NEGRITO}║   Setup concluído com sucesso!               ║${RESET}"
echo -e "  ${VERDE}${NEGRITO}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${NEGRITO}Configurado para:${RESET}"
echo -e "  ${DIM}  Jira:    ${RESET}${JIRA_URL}"
echo -e "  ${DIM}  Email:   ${RESET}${JIRA_EMAIL}"
echo -e "  ${DIM}  Projeto: ${RESET}${NOME_PROJETO} (${JIRA_KEY})"
echo ""

if [ -n "$AVISO_CAMINHO" ]; then
  echo -e "  ${VERMELHO}  ${AVISO_CAMINHO}${RESET}"
  echo ""
fi

separador
echo ""
echo -e "  ${NEGRITO}Como usar agora — abra o terminal em qualquer pasta:${RESET}"
echo ""
echo -e "  ${CIANO}  claude${RESET}"
echo ""
echo -e "  ${DIM}  Depois use os comandos:${RESET}"
echo -e "  ${CIANO}  /tempo${RESET}    ${DIM}→ lança horas de todos os projetos${RESET}"
echo -e "  ${CIANO}  /daily${RESET}    ${DIM}→ resumo para o stand-up${RESET}"
echo -e "  ${CIANO}  /pr${RESET}       ${DIM}→ descrição do PR (rode dentro do repo)${RESET}"
echo -e "  ${CIANO}  /commit${RESET}   ${DIM}→ mensagem de commit (rode dentro do repo)${RESET}"
echo ""
separador
echo ""
echo -e "  ${NEGRITO}Adicionar mais projetos:${RESET}"
echo -e "  ${CIANO}  ./setup.sh --add-repo${RESET}"
echo ""
echo -e "  ${NEGRITO}Ver projetos cadastrados:${RESET}"
echo -e "  ${CIANO}  ./setup.sh --list-repos${RESET}"
echo ""
separador
echo ""
echo -e "  ${DIM}  Credenciais:  ~/.claude/settings.json  (só na sua máquina)${RESET}"
echo -e "  ${DIM}  Projetos:     ~/.claude/repos.json${RESET}"
echo -e "  ${DIM}  Comandos:     ~/.claude/skills/${RESET}"
echo ""
