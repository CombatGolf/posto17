# PADRÕES TÉCNICOS — POSTO 17 (invioláveis)

## API e dependências
- Somente API nativa do Roblox: `Instance.new`, `WeldConstraint`, `RunService`, `TweenService`, `CFrame`, `Vector3`.
- PROIBIDO: assets externos (modelos, decalques, sons de terceiros), IDs de animação publicados, plugins, frameworks externos.
- Animações: 100% procedurais — quadros-chave em tabelas Lua + interpolação de `Motor6D.Transform`. Nada de `AnimationId`.

## Rig e personagem
- Rig **R15** (juntas: Root, Waist, Neck, Shoulders, Elbows, Wrists, Hips, Knees, Ankles).
- Cada arquivo de animação traz, no topo:
  - `CALIBRAGEM = { X = 1, Y = 1, Z = 1 }` — multiplicadores globais por eixo;
  - `CORRECOES = {}` — correção por junta (ex.: `CORRECOES.JoelhoD = { X = -1 }`).
  Ajuste por rig é feito só nessas tabelas; os quadros-chave não se mexem.

## Equipamentos 3D
- Um único Model por equipamento, partes unidas por `WeldConstraint`, `PrimaryPart` definido.
- Nomes descritivos em português (ex.: `Corpo_Pistola`, `Cano_Pistola`, `Cabo_Pistola`).
- Nenhum script modifica objetos de terceiros no Workspace.

## Convenção dos ângulos (quadros-chave, em graus)
| Junta | x | y | z |
|---|---|---|---|
| Ombros / Cotovelos / Quadril | sobe/dobra à frente | gira para dentro | abre para o lado |
| Joelhos | dobra (calcanhar sobe atrás) | — | — |
| Cintura / Pescoço / Root | inclina à frente | gira para a esquerda | inclina de lado |
| Pulsos | quebra para cima | gira | quebra de lado |

Se alguma junta dobrar para o lado oposto no seu rig, inverta o sinal do eixo dela em `CORRECOES` — não reescreva a animação.

## Camadas de animação (prioridade)
| Camada | Uso |
|---|---|
| Idle/Movement do sistema | locomoção básica (desativada durante animações procedurais — helper `SilenciarAnimationsDoSistema`) |
| Action (arquivos 1 a 4) | mira/saque, tiro, transposição de obstáculo, escalada |
| Composto (arquivo 5) | canal inferior (passada em loop) + canal superior (mira) + impulso aditivo de tiro via `:Atirar()` |

## Como testar no Studio (mínimo)
1. Importe os ModuleScripts (via `Projeto/GERADOR_DO_PROJETO.lua` na barra de comandos, ou colagem manual).
2. Num LocalScript de `StarterPlayerScripts`, siga o exemplo de uso do `Animacoes/LEIA-ME.md`.
3. Chame `SilenciarAnimationsDoSistema()` uma vez após `Preparar(rig)` para o procedural assumir as juntas.
