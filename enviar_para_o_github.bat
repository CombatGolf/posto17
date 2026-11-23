@echo off
REM ============================================================
REM  POSTO 17 - enviar esta pasta para o GitHub (opcional)
REM  Use somente se optar por enviar manualmente.
REM  Requisitos: git instalado + repositorio criado em:
REM     https://github.com/CombatGolf/posto17
REM  Se o nome do repositorio for outro, ajuste a linha do remote.
REM ============================================================
cd /d "%~dp0"
git init
git add .
git commit -m "feat: estrutura do repositorio + ordem para o ChatGPT + 5 animacoes da pistola v2"
git branch -M main
git remote add origin https://github.com/CombatGolf/posto17.git
git push -u origin main
echo.
echo Pronto: verifique em https://github.com/CombatGolf/posto17
pause
