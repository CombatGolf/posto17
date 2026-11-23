# POSTO 17 — Oito movimentos básicos, revisão MGSV

## Entrega

Arquivo editável: `P17_MGSV_8_Iniciais.bbmodel`.
Exportação binária com oito clipes: `P17_MGSV_8_Iniciais_Anim.glb`.
Gerador: `gerar_mgsv_8_iniciais.py`.

É um **novo projeto**, não substitui `P17_Operador_8_Movimentos.bbmodel`
nem a animação de levantar da cama.

Foram comparadas imagens do vídeo de referência enviado pelo usuário:
`J24utG52ya0`. Os trechos utilizados foram:

| Clipe novo | Intervalo no vídeo | Adaptação criada |
| --- | --- | --- |
| P17_01_Idle | 0:00–0:11 | deslocamento mínimo do peso e respiração |
| P17_02_Walk | 0:11–0:45 | passada sem exagero e braços baixos |
| P17_03_Run | 0:45–1:10 | passada mais longa, tronco à frente |
| P17_04_Run_Pivot | 1:10–1:30 | freada, giro e retomada |
| P17_05_Sprint | 1:30–2:08 | tronco mais inclinado e braços ativos |
| P17_06_Sprint_Pivot | 2:08–2:33 | freada mais intensa antes do giro |
| P17_07_Crouch_Idle | 2:33–2:53 | peito inclinado, um joelho baixo, pé dianteiro plantado |
| P17_08_Crouch_Walk | 2:53–3:35 | alternância de apoio nos pés, passos curtos e baixo centro de gravidade |

**Limitações reais:** não são cópias dos dados de animação de MGSV,
nem reprodução idêntica quadro por quadro. São animações originais
reconstruídas a partir das posturas e do ritmo observados no vídeo.
A filmagem também movimenta a câmera, portanto as poses do Snake não
são isoladas em cada quadro. O corpo low-poly do Posto 17 tem menos
articulações. Conferir visualmente durante a reprodução.

## Mudança técnica em relação ao protótipo

- Mantidas as 15 malhas do modelo low-poly que já tinha cotovelos.
- Adicionadas 2 articulações de tornozelo: total de 13 grupos.
- `Crouch Idle`: joelho traseiro calculado a cerca de 0,2 unidade do solo,
  com o pé dianteiro apoiado.
- `Crouch Walk`: apoio alternado, altura de quadril quase estável
  (variação vertical menor que 0,12 unidades por ciclo).
- Cada clipe tem seus próprios quadros-chave; 6 movimentos cíclicos,
  2 giros únicos. Sem movimentos de ferramentas ou acessórios.

## Testar

Abra o `.bbmodel` no Blockbench, clique em **Animar**,
selecione cada um dos oito clipes e reproduza o ciclo.
Gire a câmera para conferir a posição dos joelhos e dos pés de lado.

`python3 tests/test_mgsv8.py` — valida 8 clipes, articulações, loops,
giros, apoios e estabilidade vertical.

**Não execute o gerador depois de editar manualmente o .bbmodel**,
pois o script o reescreve. A integração definitiva no Roblox Studio
não faz parte deste protótipo e ainda requer validação visual e de rig.
