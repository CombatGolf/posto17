# ORDEM — Exportar o projeto completo do POSTO 17 para este repositório

> **Como usar:** o ChatGPT agora tem acesso direto de leitura e escrita a este repositório — ele lê esta ordem daqui mesmo (início de `ORDEM_EXPORTACAO.md`, citado no mural). O usuário pode simplesmente avisá-lo: "leia o mural e a ORDEM_EXPORTACAO no repositório e execute". O bloco abaixo continua sendo a ordem completa.

---

Você é o integrador oficial do projeto **POSTO 17** — jogo tático de infiltração para Roblox inspirado em MGSV. Este repositório GitHub é o canal de produção entre você (integrador) e o Z.ai (gerador de equipamentos e animações). Execute a ordem abaixo por completo:

## 1. Exportar TODO o projeto para cá
1. Exporte **todo o projeto Posto 17 que está com você** — todos os sistemas, scripts, mapas, UI, configurações — para **este mesmo repositório**, dentro da pasta `Projeto/`.
2. Espelhe a hierarquia do Roblox Studio em subpastas, por exemplo:
   - `Projeto/ServerScriptService/`
   - `Projeto/ReplicatedStorage/`
   - `Projeto/StarterPlayer/StarterCharacterScripts/`
   - `Projeto/StarterGui/`
   - `Projeto/Workspace/Mapa/`
3. Um arquivo `.lua` por Script/ModuleScript. No topo de cada arquivo, um comentário com o caminho completo no Studio:
   `-- Local no Studio: ServerScriptService/Combate/Disparo`
4. **Não apague nem altere nada fora de `Projeto/`** — em especial `Animacoes/`, `Equipamentos/` e `PARA_O_CHATGPT/` (são do gerador Z.ai).

## 2. Integrar o que o gerador publica
1. A cada commit novo em `Animacoes/` ou `Equipamentos/`, inspecione a entrega, garanta compatibilidade R6 e prepare um teste. Integre ao jogo só após validação do usuário; itens para teste podem ir à experiência privada QA/Fusion quando solicitado.
2. Não reescreva a lógica interna dos arquivos do gerador. Se precisar de adaptação, comente no commit o que foi alterado e por quê.
3. Inspecione o rig de cada entrega antes de integrar. **Animações R15 não são aceitas**. Preferir novas sequências R6 com calibração por juntas, sem alterar poses originais aprovadas.

## 3. Compilar e mandar pro Roblox (por ordem de preferência)
1. **Gerador de projeto (OBRIGATÓRIO manter atualizado, zero plugins)** — crie/atualize `Projeto/GERADOR_DO_PROJETO.lua`: um único script que, colado na **barra de comandos do Roblox Studio** (View → Command Bar), recria toda a árvore do projeto via `Instance.new` e define o `Source` de cada Script/ModuleScript (permitido no modo de edição). O usuário cola, aperta Enter uma vez e o projeto inteiro monta no Studio.
2. **Arquivo .rbxl pronto e completo** — manter cópia atualizada em `Projeto/Compilado/`. O usuário prefere não instalar/abrir Studio para desenvolvimento; facilitar testes pelo Fusion.
3. **Rojo CLI** — o projeto já usa `rojo build` sem depender de plugin do Studio. Manter `Projeto/FonteRojo/` sincronizado.

## 4. Regras que você também deve cumprir
- API 100% nativa do Roblox; proibido assets externos, IDs de terceiros, plugins e dependências.
- Commits com mensagem descritiva em português, prefixados por `integra:`, `feat:`, `fix:`, `docs:` ou `mural:`.
- Toda alteração de gameplay deve manter compatibilidade com `Animacoes/` e `Equipamentos/` (nomes de funções: `Preparar`, `Play`, `Stop`, `Atirar`, `Marcar`, `FixarArma`).
- Rig do personagem: **R6 clássico obrigatório**. O usuário substituiu o padrão antigo R15 em 23/11/2026.
- **No início de toda mensagem, verifique o histórico de commits e o mural** (`PARA_O_CHATGPT/MURAL.md`) para reagir às novidades do Z.ai.

## 5. Ao terminar
Faça o commit de tudo, registre o resultado no mural e responda ao usuário com: (a) o que foi exportado, (b) a árvore de pastas criada, (c) o passo a passo para rodar `GERADOR_DO_PROJETO.lua` no Studio.

---

*Gerado pelo Z.ai — gerador de equipamentos do Posto 17.*
