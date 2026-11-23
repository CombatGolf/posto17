# FLUXO DE TRABALHO — POSTO 17

## Papéis
| Quem | O que faz |
|---|---|
| **Z.ai (gerador)** | Cria equipamentos 3D e animações procedurais em Lua nativo, publica em `Equipamentos/` e `Animacoes/` e registra no mural |
| **ChatGPT (integrador)** | Exporta o projeto completo para `Projeto/`, integra as entregas do gerador, mantém o `GERADOR_DO_PROJETO.lua` e responde no mural |
| **Usuário** | Testa no Studio, cola o gerador na barra de comandos e traz feedback — o repositório substitui a cola manual entre as IAs |

## Regra de ouro: verificar antes de agir
1. **No início de TODA mensagem, cada IA olha o repositório** (histórico de commits) para ver se o outro mudou algo desde a última vez.
2. Commit novo do outro = ler o que mudou e reagir: integrar, corrigir ou responder no mural.
3. Nenhum dos dois começa trabalho novo sem sincronizar com o estado atual do repositório.

## Mural — onde a conversa acontece
- `PARA_O_CHATGPT/MURAL.md` é o quadro de mensagens entre Z.ai e ChatGPT.
- Cada IA registra lá: o que acabou de entregar (arquivo + commit), pedidos, dúvidas e respostas.
- Uma entrada por evento, com data, autor e título; as mais novas no topo.
- Commit que mexe no mural usa prefixo `mural:`.

## O ciclo (repete a cada entrega)
1. Uma IA publica arquivos novos/atualizados + entrada no mural (commit descritivo).
2. A outra IA, no início da próxima mensagem, lê o repo, integra e responde no mural.
3. Usuário testa no Studio e traz feedback para qualquer um dos dois.
4. Correções voltam pelo mesmo caminho.

## Convenções de commit
- `feat:` nova entrega | `fix:` correção | `docs:` documentação | `integra:` exportação/integração do ChatGPT | `mural:` mensagem no mural
- Mensagens curtas em português. Ex.: `feat(animacoes): recuo do tiro refeito quadro a quadro`

## Regras de convivência
- Ninguém edita a pasta dos outros sem avisar no commit e registrar no mural.
- `main` é sempre jogável: experimentos grandes vão para branch separada.
- Dúvidas técnicas de padrão: consultar `PADROES_TECNICOS.md`.
