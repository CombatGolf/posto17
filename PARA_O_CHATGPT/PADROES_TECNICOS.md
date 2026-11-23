# PADRÕES TÉCNICOS — POSTO 17 (R6 oficial)

## Avatar e animações
- O **rig jogável é R6 clássico, obrigatório para todos os jogadores**, inclusive quando o avatar da conta usa R15.
- Partes R6: `HumanoidRootPart`, `Torso`, `Head`, `Right Arm`, `Left Arm`, `Right Leg`, `Left Leg`.
- Articulações (Motor6D): `RootJoint`, `Neck`, `Right Shoulder`, `Left Shoulder`, `Right Hip`, `Left Hip`.
- **Não existem cotovelos, pulsos, joelhos ou cintura separados no R6.** Nunca use `RightElbow`, `RightKnee`, `Waist` etc. em novas animações.
- Animações procedurais com `Motor6D.Transform` ou KeyframeSequence construída localmente, sem IDs publicados de terceiros.
- Cada entrega deve declarar: rig R6, quadros, tempo, loop, junta alvo e como testar. `CALIBRAGEM`/`CORRECOES` podem ajustar sinais ou intensidade quando aplicável.
- **Não editar diretamente os quadros de arquivos já aprovados** sem pedido do usuário; fazer cópia/versão nova com comparação visual.

## Padrão de integração
- O jogo completo atual e seus controladores R6 estão em `Projeto/`.
- Novos arquivos do Z.ai entram em `Animacoes/` (R6) ou `Equipamentos/`; o integrador lê os commits, testa em bancada e só então incorpora ao jogo.
- Adaptações devem ficar em adaptadores separados sempre que possível; reportar incompatibilidades no mural.
- Sem plugins no jogo; scripts nativos Roblox (Instance.new, WeldConstraint, RunService, TweenService, CFrame).
- Não usar URLs, IDs e recursos de terceiros sem necessidade/consentimento, nem introduzir credenciais.
- Modelos 3D low-poly editáveis, um Model por equipamento, `PrimaryPart` definido e partes fixas com WeldConstraint.
- Colisões visuais de acessórios desligadas; validar frente/costas/lateral, parado e animando.
- Funcionalidade de anexos visuais (miras etc.) fica separada da malha-base.

## Regra de revisão e publicação
- `main` deve conter entregas rastreáveis; preservar o histórico. Qualquer mudança de rig ou contrato precisa de autorização.
- As duas IAs leem `PARA_O_CHATGPT/MURAL.md` e commits recentes antes de começar.
- Qualquer alteração passa por commit e entrada no mural; indicar versão QA publicada quando houver.
- Testes Roblox são na experiência privada de QA; visualização no Fusion pelo usuário após revisão.
