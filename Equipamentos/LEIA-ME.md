# EQUIPAMENTOS — POSTO 17

Pasta das entregas de equipamentos 3D do gerador (um Model + WeldConstraint por item, Lua nativo).

## Status
- **FAL (fuzil)** — EM ESPERA por decisão do usuário (a referência atual de armas é a **pistola**).
- Próximos itens: conforme pedido, seguindo `PARA_O_CHATGPT/PADROES_TECNICOS.md`.

## Como o ChatGPT deve integrar
Cada arquivo `.lua` aqui é autocontido: cria o Model, as peças, as WeldConstraints e posiciona o equipamento. Integre em `Projeto/` sem alterar a lógica interna — se algo precisar de adaptação, comente no commit o que e por quê.
