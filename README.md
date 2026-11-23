# POSTO 17 — Repositório de Produção

Jogo tático de infiltração para Roblox, inspirado em Metal Gear Solid V (estética low-poly militar).
Este repositório é o canal oficial de arquivos **e de conversa direta** entre o **gerador de conteúdo (Z.ai)** e o **integrador (ChatGPT)** — os dois têm acesso de leitura e escrita aqui.

## Fluxo de trabalho
1. **No início de toda mensagem, cada IA verifica o repositório** (histórico de commits + mural) para ver o que o outro fez.
2. **Z.ai** gera equipamentos e animações (100% Lua nativo, sem assets externos), publica aqui e registra no mural.
3. **ChatGPT** integra as entregas ao jogo, **exporta o projeto completo para a pasta `Projeto/` deste mesmo repositório** e responde no mural.
4. **Compilação para o Roblox Studio** pelo gerador de projeto (zero plugins) — ver `PARA_O_CHATGPT/ORDEM_EXPORTACAO.md`.
5. Testes do usuário e feedback viram novas entregas e correções em commits descritivos.

## Estrutura
| Pasta | Conteúdo | Responsável |
|---|---|---|
| `Animacoes/` | 5 animações procedurais da pistola (arquivos independentes) | Z.ai |
| `Equipamentos/` | equipamentos 3D (FAL em espera por decisão) | Z.ai |
| `Projeto/` | projeto completo exportado pelo ChatGPT (sistemas, mapas, UI) | ChatGPT |
| `PARA_O_CHATGPT/` | mural de mensagens, ordem de exportação, fluxo e padrões técnicos | Z.ai ↔ ChatGPT |

## Regras técnicas (invioláveis)
- Somente **API nativa do Roblox** (`Instance.new`, `WeldConstraint`, `RunService`, `TweenService`, `CFrame`).
- **Proibido**: assets externos, IDs de modelo/animação de terceiros, plugins e dependências externas.
- Animações 100% procedurais: quadros-chave em tabelas Lua + interpolação de `Motor6D.Transform` (nada de `AnimationId`).
- Equipamentos: um único Model por item, partes unidas por `WeldConstraint`, nomes descritivos em português.
- Nenhum script modifica objetos de terceiros no Workspace.

## Status
- [x] Estrutura do repositório + ORDEM para o ChatGPT
- [x] 5 animações da pistola (v2, quadro a quadro, calibráveis por rig)
- [x] Mural de comunicação Z.ai ↔ ChatGPT (`PARA_O_CHATGPT/MURAL.md`)
- [ ] Exportação do projeto completo pelo ChatGPT (`Projeto/`)
- [ ] FAL — em espera por decisão do usuário
