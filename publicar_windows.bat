@echo off
setlocal enabledelayedexpansion

:: Muda para a pasta onde este .bat esta localizado
cd /d "%~dp0"

echo.
echo =====================================================
echo   HortiFacil FLV - Publicacao no GitHub Pages
echo =====================================================
echo.
echo Pasta do projeto: %CD%
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Git nao encontrado.
  echo Instale em: https://git-scm.com/downloads
  pause
  exit /b 1
)

set REPO=hortiflv-monitor

if "%GH_USER%"=="" (
  echo Voce precisa de uma conta em https://github.com
  set /p GH_USER=Seu usuario do GitHub: 
)

if "%GH_TOKEN%"=="" (
  echo.
  echo Como criar o token:
  echo   1. Abra: https://github.com/settings/tokens/new
  echo   2. Note: hortiflv
  echo   3. Expiration: No expiration
  echo   4. Marque "repo" e clique Generate token
  echo.
  set /p GH_TOKEN=Cole o token aqui: 
)

:: Adiciona pasta atual como segura para o Git
git config --global --add safe.directory "%CD%" >nul 2>&1

echo.
echo [1/4] Criando repositorio no GitHub...
curl -s -X POST https://api.github.com/user/repos ^
  -H "Authorization: token %GH_TOKEN%" ^
  -H "Accept: application/vnd.github.v3+json" ^
  -d "{\"name\":\"%REPO%\",\"private\":false,\"auto_init\":false}" > nul
echo     OK

echo [2/4] Configurando Git...
git init
git config --global --add safe.directory "%CD%" >nul 2>&1
git checkout -b main 2>nul
if errorlevel 1 git checkout main 2>nul
git config user.email "%GH_USER%@users.noreply.github.com"
git config user.name "%GH_USER%"
git remote remove origin 2>nul
git remote add origin https://%GH_USER%:%GH_TOKEN%@github.com/%GH_USER%/%REPO%.git
echo     OK

echo [3/4] Enviando arquivos...
git add -A
git commit -m "HortiFacil FLV deploy" 2>nul
if errorlevel 1 git commit --allow-empty -m "HortiFacil FLV deploy"
git push -u origin main --force
echo     OK

echo [4/4] Ativando GitHub Pages...
curl -s -X POST https://api.github.com/repos/%GH_USER%/%REPO%/pages ^
  -H "Authorization: token %GH_TOKEN%" ^
  -H "Accept: application/vnd.github.v3+json" ^
  -d "{\"source\":{\"branch\":\"main\",\"path\":\"/\"}}" > nul
curl -s -X PUT https://api.github.com/repos/%GH_USER%/%REPO%/pages ^
  -H "Authorization: token %GH_TOKEN%" ^
  -H "Accept: application/vnd.github.v3+json" ^
  -d "{\"source\":{\"branch\":\"main\",\"path\":\"/\"}}" > nul
echo     OK

echo.
echo =====================================================
echo   PUBLICACAO CONCLUIDA!
echo.
echo   Site: https://%GH_USER%.github.io/%REPO%
echo   Aguarde 1-2 minutos para o link ativar.
echo =====================================================
echo.
pause
