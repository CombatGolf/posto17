# ANIMAÇÕES — PISTOLA (POSTO 17)

5 animações 100% procedurais (sem `AnimationId`, sem plugins), cada uma num arquivo independente (ModuleScript). Rig: R15.

| # | Arquivo | O que faz | Duração | Loop |
|---|---|---|---|---|
| 1 | `Pistola_MiraSaque.lua` | guarda → coldre → saque → empunhadura de 2 mãos → linha de mira | 1.60 s | não |
| 2 | `Pistola_TiroRecuo.lua` | disparo: estalo do cano, absorção e reassentamento da mira | 0.95 s | não (1 Play por tiro) |
| 3 | `Pistola_TransporObstaculos.lua` | vault em obstáculo baixo: 1 mão de apoio, arma presa ao peito | 1.45 s | não |
| 4 | `Pistola_EscaladaDuasMaos.lua` | escalada/mantle com as 2 mãos na borda | 1.85 s | não |
| 5 | `Pistola_AndarMirarAtirar.lua` | composto: passada + mira + tiro (2 canais + impulso aditivo) | ciclo 0.95 s | sim |

## Status honesto (v2)
O vídeo de referência **nunca chegou até mim** — nenhum arquivo de vídeo foi anexado nesta conversa (ele se perdeu no envio). Por isso esta v2 reconstrói os quadros a partir da referência de empunhadura de pistola do MGSV (fases, tempos e posturas descritas no cabeçalho de cada arquivo), com densidade alta de quadros nas janelas críticas (impacto do tiro, impulso do vault, puxada da escalada).

**Para ficar idêntico ao vídeo de verdade:** anexe o vídeo de novo (ou descreva quadro a quadro) que eu ajusto ângulo por ângulo e faço commit direto no repositório.

## Calibração por rig
No topo de cada arquivo:
- `CALIBRAGEM = { X = 1, Y = 1, Z = 1 }` — multiplicadores globais por eixo.
- `CORRECOES = {}` — correção por junta. Ex.: se os joelhos dobrarem para frente no seu rig:
  `CORRECOES.JoelhoD = { X = -1 }` e `CORRECOES.JoelhoE = { X = -1 }`.

## Como usar no Studio
1. Importe os arquivos como **ModuleScript** (via `Projeto/GERADOR_DO_PROJETO.lua` ou colagem manual).
2. Exemplo de uso:

```lua
-- LocalScript em StarterPlayerScripts (personagem R15)
local pistolaMira = require(game.ReplicatedStorage.Animacoes.Pistola_MiraSaque)
local personagem = game.Players.LocalPlayer.Character

pistolaMira:Preparar(personagem)
pistolaMira:SilenciarAnimationsDoSistema()

-- pistola saindo do coldre no quadro certo (0.28 s):
-- pistolaMira:Marcar(0.28, function() pistolaMira:FixarArma(suaPistola) end)

pistolaMira:Play()
```

3. Tiro (arquivo 2): chame `:Play()` a cada disparo — ele termina já assentado em mira.
4. Composto (arquivo 5): `:Play()` inicia andar + mirar em loop; `:Atirar()` dispara o recuo por cima da passada, sem interrompê-la (cadência mínima 0.30 s).
5. Fim de animação única: `:Stop(false)` mantém a pose final; `:Stop()` limpa as juntas.

## Integração com arma
`FixarArma(modeloDaPistola)` solda a pistola na mão direita com `WeldConstraint` (um Model, `PrimaryPart` definido). Chame via `Marcar(segundo, funcao)` no instante certo da animação (saque no coldre, por exemplo).
