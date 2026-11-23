# FLUXO DE TRABALHO — POSTO 17

## Papéis
| Quem | O que faz |
|---|---|
| **Z.ai (gerador)** | Cria equipamentos 3D e animações procedurais em Lua nativo e publica em `Equipamentos/` e `Animacoes/` |
| **ChatGPT (integrador)** | Exporta o projeto completo para `Projeto/`, integra as entregas do gerador ao jogo e mantém o `GERADOR_DO_PROJETO.lua` |
| **Usuário** | Ponte entre os dois: cola a ORDEM no ChatGPT, roda o gerador na barra de comandos do Studio e testa o jogo |

## O ciclo (repete a cada entrega)
1. Z.ai publica/atualiza arquivos em `Animacoes/` ou `Equipamentos/` (commit descritivo).
2. Usuário avisa o ChatGPT: "integre as novidades do repositório".
3. ChatGPT lê os arquivos, integra em `Projeto/` e atualiza o `GERADOR_DO_PROJETO.lua`.
4. Usuário cola o gerador na barra de comandos do Studio e testa.
5. Feedback volta para o repositório e o Z.ai corrige ou refaz.

## Convenções de commit
- `feat:` nova entrega | `fix:` correção | `docs:` documentação | `integra:` exportação/integração do ChatGPT
- Mensagens curtas em português. Ex.: `feat(animacoes): recuo do tiro refeito quadro a quadro`

## Regras de convivência
- Ninguém edita a pasta dos outros sem avisar no commit.
- `main` é sempre jogável: experimentos grandes vão para branch separada.
- Dúvidas técnicas de padrão: consultar `PADROES_TECNICOS.md`.
