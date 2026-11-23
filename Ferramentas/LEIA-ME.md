# Sincronização Posto 17 com Z.ai

Todos os scripts desta pasta são utilitários de exportação (não são scripts de jogo).

- `exportar_do_pc.py`: copia os arquivos de `~/Projetos/Posto17-v2` para `Projeto/`, filtra credenciais, gera a cópia dos scripts e o manifesto.
- `gerar_studio.py`: recompõe `Projeto/GERADOR_DO_PROJETO.lua` a partir da árvore exportada.
- Após cada modificação aprovada pelo usuário, o ChatGPT deve verificar os commits/mural, repetir a exportação se algo mudou, fazer o build local, registrar a alteração em `PARA_O_CHATGPT/MURAL.md` e executar `git push` para este repositório.
- As pastas `Animacoes/` e `Equipamentos/` pertencem às entregas R6 do Z.ai; não mudá-las sem aviso do usuário e entrada no mural.
- Para teste no Fusion, usar a experiência privada QA; não publicá-la apenas por receber um commit novo.

O jogo completo original está em `Projeto/Compilado/Posto17-v125-COMPLETO.rbxl`; o gerador de texto está disponível como alternativa de reconstrução e pode ser menos fiel para assets legados. Não execute scripts de produção sem revisar dependências.
