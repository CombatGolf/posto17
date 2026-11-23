# CORREÇÕES v126 — Posto 17 (pacote Z.ai → ChatGPT)

Pacote de correções dos 4 problemas reportados pelo usuário. Diagnóstico feito
lendo o código-fonte do v125 (`Projeto/`) quadro a quadro. Nada foi inventado:
os dados de animação vêm do clipe de edição original.

## O que foi corrigido

### 1. Agachar "andando parado" — CAUSA ENCONTRADA: clipe corrompido
O clipe `P17_Corpo_013` (CrouchIdle) dentro de
`ReplicatedStorage/Posto17Shared/Posto17R6Corpo` está **corrompido**:

- as pernas alternam 0° ↔ 7,6° a cada ~0,03 s → passo tremido = "andar parado";
- a cabeça salta 0° ↔ 19° entre quadros vizinhos;
- os braços saltam 0° ↔ 13,4°;
- existe **um quadro infiltrado de pose em pé** (torso rotacionado 25,7° com o
  offset de agachamento zerado) — o boneco "pula" para fora do agachamento por
  um quadro a cada loop.

A versão de edição (`CrouchIdle.rbxmx`, 16 quadros, 1,367 s) é limpa — só tem o
mesmo quadro infiltrado em t=1,000 s, descartado na reconstrução.

**Arquivo:** `CorrigeCrouchIdle.client.lua` (LocalScript)
**Destino no Studio:** `StarterPlayer/StarterPlayerScripts/CorrigeCrouchIdle`
**O que faz:** reconstrói o `KeyframeSequence` P17_Corpo_013 com os 15 quadros
limpos (preenchidos em todas as 6 partes, o que também elimina o tremor de
cabeça/braço causado por poses ausentes) e substitui o clipe antigo no
Posto17R6Corpo local. 100% `Instance.new`, sem IDs externos.

> **Para o integrador (ChatGPT):** este hotfix é a solução imediata no v125.
> No próximo re-embalo, gere o clipe DENTRO de `Posto17R6Corpo.rbxmx` com
> estes mesmos quadros (a tabela está embutida no hotfix) e remova o hotfix.
> **A mesma corrupção contaminou os "Reusos" derivados do CrouchIdle:**
> `P17_Corpo_018` (Fuzil_Mira_Agachado_Reuso), `P17_Corpo_035`
> (Sub_Mira_Agachado_Reuso) — mesma digital (15 quadros/0,47 s, 2 resets + 2
> saltos) — e o `P17_Corpo_024` (CrouchWalk antigo, 57/76 quadros suspeitos;
> o jogo usa o 015 Corrigido, então não afeta o controle).
> Reembalar os três a partir das fontes limpas.

### 2. Pistola mais colada na perna
`Posto17Modelos.lua` → placement `pistola`: X de `.75` → `.62`.
A coxa tem 1 stud de largura; o grip tem ~0,18. Em `.75` a arma flutuava
~0,16 stud fora da perna; em `.62` encosta na superfície externa da coxa.

### 3. Submetralhadora ao lado do corpo, como espada
`Posto17Modelos.lua` → placement `submetralhadora`:
- X `-1.67` → `-1.32` (elimina a folga flutuante de ~0,67 stud do corpo);
- Y `-1.18` → `-1.35` (punho na altura do cinto, boca no meio da canela);
- inclinação `-19°` → `+4°` (quase vertical; os 4° encostam a base no corpo,
  como bainha pendurada). Cano continua para baixo = espada na bainha.

### 4. Fuzil inclinado nas costas (e cano certo na mão)
`Posto17Modelos.lua` → placement `fuzil`:
- inclinação no plano das costas `-9°` → `+38°`: coronha sobe no ombro
  direito, boca do cano desce ao quadril esquerdo — diagonal de bandoleira;
- Z `.86` → `.76` (recebedor mais rente ao torso, sem atravessar).

`AnimacaoIndividual.client.lua` (bancada): o fuzil usava o mesmo giro de mão
das armas +Z, mas seu modelo de origem (FAL_Militar) aponta para **-Z** — ele
sacava/guardava invertido, com o cano para o ombro. Agora o giro é
condicional ao tipo (`giro = kind=="fuzil" and 0 or math.pi`).

## Como aplicar (ChatGPT)
1. Copiar os 3 arquivos para os caminhos de Studio acima (nomes Rojo
   preservados: `.client.lua` = LocalScript, sem sufixo = ModuleScript).
2. `Posto17Modelos.lua` e `AnimacaoIndividual.client.lua` substituem os
   existentes (neste pacote estão completos, prontos para substituir).
3. `CorrigeCrouchIdle.client.lua` é arquivo NOVO.
4. Reexportar v126 e publicar na QA (Place 119377443515742).

## Como testar (Studio)
1. Abrir o jogo, entrar, apertar C (agachar): **parado**, o boneco não deve
   mais dar passinhos nem pular de altura — só respiração leve do torso.
2. Andar agachado: caminhada agachada normal (clipe 015, intocado).
3. Bancada "ANIMAÇÕES 73": olhar a lista Pistola/Sub/Fuzil —
   - pistola: colada na coxa direita;
   - sub: vertical ao lado do quadril esquerdo, tipo espada;
   - fuzil: diagonal nas costas, coronha no ombro direito;
   - clipes "Sacar/Guardar" do fuzil: arma na mão com o cano para a frente.
