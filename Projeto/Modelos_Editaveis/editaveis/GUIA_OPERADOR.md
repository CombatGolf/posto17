# Posto 17 — Operador estilizado e locomoção básica

## Editar no Blockbench
Abra `P17_Operador_8_Movimentos.bbmodel` e escolha a aba **Animar**.
O arquivo preserva as proporções e o atlas de cores; tem 15 malhas\n(13 do original, com dois braços divididos em antebraços) e as proporções
do personagem de `P17_Levantar_da_Cama.bbmodel`; a cama não está incluída.

Clipes:
1. P17_Parado_Respirar (2,80 s, loop)
2. P17_Caminhar (0,95 s, loop)
3. P17_Correr (0,72 s, loop)
4. P17_Agachado_Parado (2,80 s, loop)
5. P17_Andar_Agachado (1,10 s, loop)
6. P17_Deitado_Parado (3,00 s, loop)
7. P17_Rastejar (1,35 s, loop)
8. P17_Rastejar_Duto (1,35 s, loop — animação compacta antiga)\n9. P17_Saltar_Pousar (0,90 s, uma vez)

Cada clip usa 11 grupos e 156 quadros-chave. A animação de levantar
da cama continua em arquivo separado, sem alterações.

## Uso no Roblox
- `src/server/P17BlockyOperator.luau`: reconstrói no próprio R15 o corpo
  visível inspirado no modelo Blockbench, sem trocar Humanoid nem colisões.
- `src/server/Protagonista.server.luau`: ativa a nova aparência no R15;
  preserva fallback de aparência anterior em outros rigs.
- `src/shared/PoseLibrary.luau` e `src/client/Postura.client.luau`:
  locomoção procedural básica de braços, pernas e respiração, respeitando
  os estados de postura que já existiam.
- `src/client/OperatorCamera.client.luau`: zoom de câmera nativo
  com transições suaves, proteção contra conflito com o menu/revisão/cobertura.
- A cópia `Posto17-v2.rbxl` foi gerada pelo Rojo.

**Importante:** os clipes completos do Blockbench ainda não são assets
de animação importados no Roblox. A locomoção jogável neste estágio é a
adaptação procedural R15; as poses de agachar/rastejar aproveitam o
sistema de postura existente. Ainda faltam testes de qualidade visual
dentro do Roblox Studio, em especial pés, transições e câmera móvel.

## Regeneração
`python3 gerar_locomocao.py` reescreve o pacote editável.
**Não execute isso após editar manualmente os clipes**, a menos que
queira substituí-los pelo protótipo.

## Testes
`bash tests/verificar.sh` executa compilação Luau, regressões,
validação do pacote e build do projeto. Não publica a experiência.
