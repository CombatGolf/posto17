# Posto 17 — cópia completa do jogo (v125; R6)

**Origem:** PC do integrador. **Alvo:** Roblox QA privado, Place ID `119377443515742`.  
**Rig obrigatório:** **R6 clássico**, não R15.

## Onde estão os arquivos
- `Compilado/Posto17-v125-COMPLETO.rbxl`: **arquivo Roblox completo e pronto para abrir no Studio** (alternativa mais fiel).
- `FonteRojo/`: o projeto completo para build, com `default.project.json` e todo `src/`, inclusive animações, modelos R6 e scripts.
- `ServerScriptService/`, `StarterPlayer/`, `ReplicatedStorage/`, `ServerStorage/`: espelho da hierarquia real do Studio; arquivos Luau como `.lua`, com caminho no topo.
- `Modelos_Editaveis/`: modelos 3D originais (Blockbench e arquivos auxiliares).
- `Ferramentas/RigFlip-Posto17/`: editor local e sequências para auditoria das animações.
- `Workspace/Mapa/`: o mapa é gerado dinamicamente pelos scripts, não é um mapa estático separado.
- `StarterGui/`: UI gerada em runtime pelos LocalScripts.
- `GERADOR_DO_PROJETO.lua`: gerador por Command Bar para construir os objetos em Studio. **Para identidade integral do jogo, abra o .rbxl compilado.**
- `MANIFESTO_EXPORTACAO.json`: lista das correspondências de Script/ModuleScript/LocalScript.

## Compilar sem plugin no Studio
Use `Compilado/Posto17-v125-COMPLETO.rbxl` via Arquivo > Abrir do Roblox Studio. O jogo completo
aparece como Place. Não é necessário plugin. Com Rojo CLI, também é possível compilar
`FonteRojo/default.project.json`, a partir da pasta FonteRojo:
`rojo build default.project.json --output Posto17-v125.rbxl`.

**Não execute scripts originais da pasta Ferramentas sem inspeção.**
**Nenhuma chave de publicação, senha ou token foi incluído.**  

## Trabalho conjunto
Toda mudança relevante deve entrar neste repositório, com entrada no
`PARA_O_CHATGPT/MURAL.md`. O Z.ai publica entregas R6 em
`Animacoes/` ou `Equipamentos/` e o ChatGPT integra após revisão e teste.
O usuário pode pedir publicação na experiência privada para testes no Fusion.
