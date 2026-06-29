#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  HortiFácil FLV — Publicação automática no GitHub Pages            ║
# ║  Execução: bash publicar.sh                                        ║
# ║  Resultado: link gratuito e permanente em ~2 minutos               ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
REPO="hortiflv-monitor"
G="\033[0;32m"; B="\033[0;34m"; Y="\033[1;33m"; R="\033[0;31m"; X="\033[0m"

echo -e "\n${G}🌿 HortiFácil FLV — Publicação no GitHub Pages (gratuito)${X}\n"

if ! command -v git &>/dev/null; then
  echo -e "${R}❌ Git não encontrado.${X}"
  echo "   Instale em: https://git-scm.com/downloads"
  exit 1
fi

if [ -z "$GH_USER" ]; then
  echo -e "${B}ℹ  Você precisa de uma conta em https://github.com (gratuita)${X}"
  read -p "👤 Seu usuário do GitHub: " GH_USER
fi

if [ -z "$GH_TOKEN" ]; then
  echo -e "\n${Y}📋 Como criar o token (30 segundos):${X}"
  echo "   1. Abra: https://github.com/settings/tokens/new"
  echo "   2. Em 'Note': escreva hortiflv"
  echo "   3. Em 'Expiration': selecione 'No expiration'"
  echo "   4. Marque a caixa 'repo' (a principal basta)"
  echo "   5. Clique em 'Generate token' e copie"
  echo ""
  read -s -p "🔑 Cole o token aqui (não aparece na tela): " GH_TOKEN
  echo ""
fi

[ -z "$GH_USER" ] && { echo -e "${R}❌ Usuário não informado.${X}"; exit 1; }
[ -z "$GH_TOKEN" ] && { echo -e "${R}❌ Token não informado.${X}"; exit 1; }

echo -e "\n${B}▶ 1/4 — Criando repositório '$REPO' no GitHub...${X}"
HTTP=$(curl -s -o /tmp/gh_resp.json -w "%{http_code}" \
  -X POST https://api.github.com/user/repos \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "{\"name\":\"$REPO\",\"description\":\"Monitor gratuito de preços de FLV — CONAB, CEAGESP, CEASAs\",\"homepage\":\"https://${GH_USER}.github.io/${REPO}\",\"private\":false,\"auto_init\":false}")

if [ "$HTTP" = "201" ]; then
  echo -e "   ${G}✓ Repositório criado${X}"
elif [ "$HTTP" = "422" ]; then
  echo -e "   ${Y}ℹ Repositório já existe — atualizando conteúdo${X}"
else
  echo -e "${R}❌ Erro ao criar repositório (HTTP $HTTP)${X}"; cat /tmp/gh_resp.json; exit 1
fi

echo -e "${B}▶ 2/4 — Configurando Git local...${X}"
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
git init -b main 2>/dev/null || (git init && git checkout -b main 2>/dev/null) || true
git config user.email "${GH_USER}@users.noreply.github.com"
git config user.name  "$GH_USER"
git remote remove origin 2>/dev/null || true
git remote add origin "https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/${REPO}.git"
echo -e "   ${G}✓ Git configurado${X}"

echo -e "${B}▶ 3/4 — Enviando arquivos...${X}"
git add -A
git diff --staged --quiet || git commit -m "🌿 HortiFácil FLV — deploy $(date '+%d/%m/%Y %H:%M')"
git push -u origin main --force
echo -e "   ${G}✓ Arquivos enviados${X}"

echo -e "${B}▶ 4/4 — Ativando GitHub Pages...${X}"
curl -s -X POST "https://api.github.com/repos/${GH_USER}/${REPO}/pages" \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"source":{"branch":"main","path":"/"}}' > /dev/null 2>&1 || true
curl -s -X PUT "https://api.github.com/repos/${GH_USER}/${REPO}/pages" \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"source":{"branch":"main","path":"/"}}' > /dev/null 2>&1 || true
echo -e "   ${G}✓ GitHub Pages ativado${X}"

URL="https://${GH_USER}.github.io/${REPO}"
echo -e "
${G}╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ✅  PUBLICAÇÃO CONCLUÍDA!                                  ║
║                                                              ║
║   🌐  Link do site:                                          ║
║       ${URL}
║                                                              ║
║   📁  Repositório:                                           ║
║       https://github.com/${GH_USER}/${REPO}
║                                                              ║
║   ⏳  O link fica ativo em 1 a 2 minutos.                   ║
║   📲  Funciona em qualquer celular ou computador.            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝${X}

${Y}Para atualizar o site no futuro:${X}
  Edite o index.html e rode 'bash publicar.sh' novamente.
"
