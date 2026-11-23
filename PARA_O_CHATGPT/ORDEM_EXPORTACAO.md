# ORDEM — Exportar o projeto completo do POSTO 17 para este repositório

> **Como usar:** copie todo o bloco abaixo (da primeira linha `---` até a última) e cole como mensagem para o ChatGPT. Ele contém a ordem completa de exportação, integração e compilação.

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
1. A cada commit novo em `Animacoes/` ou `Equipamentos/`, integre os arquivos ao projeto: crie os ModuleScripts correspondentes nos caminhos corretos e ligue-os aos controles do personagem (mira, disparo, movimento, interação com obstáculos).
2. Não reescreva a lógica interna dos arquivos do gerador. Se precisar de adaptação, comente no commit o que foi alterado e por quê.
3. Cada animação traz `CALIBRAGEM` e `CORRECOES` no topo — use-as para ajustar por rig; não mexa nos quadros-chave.

## 3. Compilar e mandar pro Roblox (por ordem de preferência)
1. **Gerador de projeto (OBRIGATÓRIO manter atualizado, zero plugins)** — crie/atualize `Projeto/GERADOR_DO_PROJETO.lua`: um único script que, colado na **barra de comandos do Roblox Studio** (View → Command Bar), recria toda a árvore do projeto via `Instance.new` e define o `Source` de cada Script/ModuleScript (permitido no modo de edição). O usuário cola, aperta Enter uma vez e o projeto inteiro monta no Studio.
2. **Colagem manual** — para entregas pequenas, liste em ordem: caminho no Studio, tipo da instância (Script/ModuleScript) e o arquivo correspondente.
3. **Rojo (opcional)** — apenas se o usuário autorizar instalar o plugin do Rojo no Studio (ferramenta de desenvolvimento; não faz parte do jogo).

## 4. Regras que você também deve cumprir
- API 100% nativa do Roblox; proibido assets externos, IDs de terceiros, plugins e dependências.
- Commits com mensagem descritiva em português, prefixados por `integra:`, `feat:`, `fix:` ou `docs:`.
- Toda alteração de gameplay deve manter compatibilidade com `Animacoes/` e `Equipamentos/` (nomes de funções: `Preparar`, `Play`, `Stop`, `Atirar`, `Marcar`, `FixarArma`).
- Rig do personagem: R15.

## 5. Ao terminar
Faça o commit de tudo e responda ao usuário com: (a) o que foi exportado, (b) a árvore de pastas criada, (c) o passo a passo para rodar `GERADOR_DO_PROJETO.lua` no Studio.

---

*Gerado pelo Z.ai — gerador de equipamentos do Posto 17.*
