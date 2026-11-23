#!/usr/bin/env python3
"""Export public safe Roblox Posto17 project into its official GitHub repository.
Only uses local user-owned source. Refuses files with recognized live credentials.
"""
from pathlib import Path
from shutil import copy2,copytree
import json, re, os, hashlib
ROOT=Path.home()/'Projetos/Posto17-v2'
REPO=Path.home()/'Projetos/posto17-github-sync'
OUT=REPO/'Projeto'
assert ROOT.is_dir() and (REPO/'.git').is_dir()
smap={
'src/server':'ServerScriptService',
'src/client':'StarterPlayer/StarterPlayerScripts',
'src/shared':'ReplicatedStorage/Posto17Shared',
}
skip_names={'__pycache__','.venv','.git','node_modules'}
secret_patterns=[
 re.compile(r'gh[pousr]_[A-Za-z0-9]{25,}'),
 re.compile(r'github_pat_[A-Za-z0-9_]{30,}'),
 re.compile(r'AKIA[0-9A-Z]{16}'),
 re.compile(r'AIza[0-9A-Za-z_-]{30,}'),
 re.compile(r'-----BEGIN (RSA|OPENSSH|EC|PRIVATE) PRIVATE KEY-----'),
]
def clean_text(p):
    data=p.read_text(encoding='utf-8')
    bad=[pat.pattern for pat in secret_patterns if pat.search(data)]
    if bad:raise RuntimeError('POSSIBLE CREDENTIAL: '+str(p)+' '+repr(bad))
    return data
def add_text(p,text):
    p.parent.mkdir(parents=True,exist_ok=True)
    for pat in secret_patterns:
        assert not pat.search(text),str(p)
    p.write_text(text,encoding='utf-8')
def safe_copy(source,dest):
    assert source.is_file()
    if source.suffix.lower() in {'.lua','.luau','.py','.js','.md','.json','.html','.css','.sh','.txt','.toml','.yml','.yaml','.bbmodel'}:clean_text(source)
    dest.parent.mkdir(parents=True,exist_ok=True)
    copy2(source,dest)

mappings=[]
for sub,service in smap.items():
    for src in sorted((ROOT/sub).rglob('*.luau')):
        rel=src.relative_to(ROOT/sub)
        # Correct Rojo class based on .client/.server suffix
        if src.name.endswith('.client.luau'):className='LocalScript'
        elif src.name.endswith('.server.luau'):className='Script'
        else:className='ModuleScript' # Most server files are modules required by Posto17.server
        dst=OUT/service/rel.with_suffix('.lua')
        dest_object=rel.name.removesuffix('.luau').removesuffix('.server').removesuffix('.client')
        studio=f'{service}/{"/".join(rel.parts[:-1])+"/" if len(rel.parts)>1 else ""}{dest_object}'
        source=clean_text(src)
        add_text(dst, f'-- Local no Studio: {studio} ({className})\n-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).\n'+source)
        mappings.append({'source':str(src.relative_to(ROOT)), 'file':str(dst.relative_to(REPO)), 'studio':studio, 'class':className})
# Canonical Rojo source + config, so full game can be built without any plugins.
safe_copy(ROOT/'default.project.json',OUT/'FonteRojo/default.project.json')
for src in sorted((ROOT/'src').rglob('*')):
    if src.is_file():safe_copy(src,OUT/'FonteRojo'/src.relative_to(ROOT))
# Dedicated visible Studio hierarchy for non-script assets, not only raw Rojo.
asset_map={
  'Posto17R6StarterCharacter.rbxmx':'StarterPlayer/StarterCharacter/StarterCharacter.rbxmx',
  'StoreWalk.rbxm':'ReplicatedStorage/Posto17Shared/StoreWalk.rbxm',
  'StoreBed.rbxmx':'ReplicatedStorage/Posto17Shared/StoreBed.rbxmx',
  'StoreDoor.rbxmx':'ReplicatedStorage/Posto17Shared/StoreDoor.rbxmx',
  'Posto17R6Corpo.rbxmx':'ReplicatedStorage/Posto17Shared/Posto17R6Corpo.rbxmx',
  'Posto17R6Amostras.rbxmx':'ReplicatedStorage/Posto17Shared/Posto17R6Amostras.rbxmx',
  'Posto17R6Preview.rbxmx':'ReplicatedStorage/Posto17Shared/Posto17R6Preview.rbxmx',
  'Posto17RobloxWeapons.rbxmx':'ServerStorage/Posto17RobloxWeapons.rbxmx',
}
for name,dest in asset_map.items():safe_copy(ROOT/'src/assets'/name,OUT/dest)
compiled=ROOT/'tests/headless/Posto17-HEADLESS-DEV.rbxl'
assert compiled.stat().st_size>500_000
safe_copy(compiled,OUT/'Compilado/Posto17-v126-COMPLETO.rbxl')
# Editable models, actual 3D origin; do not include external binary executables or test backups.
models=ROOT/'assets3d'
models_copied=0
for src in models.rglob('*'):
    if not src.is_file() or src.is_symlink():continue
    if any(n in skip_names for n in src.relative_to(models).parts):continue
    if src.stat().st_size>95_000_000:continue
    safe_copy(src,OUT/'Modelos_Editaveis'/src.relative_to(models))
    models_copied+=1
# RigFlip source and relevant animation sets (no cache, history ZIPs or browser DB files).
rig=ROOT/'tools/RigFlip-Posto17'
selected={
 'index.html','app.js','style.css','Posto17_Modelos_Padrao.json',
}
rigcopied=0
for src in rig.rglob('*'):
    if not src.is_file() or src.is_symlink():continue
    parts=src.relative_to(rig).parts
    if any(n in skip_names for n in parts):continue
    keep=False
    if len(parts)==1 and src.name in selected:keep=True
    if parts[0] in {'Posto17_Animacoes','Modelos_P17V2','Importados_Genericos','Auditoria_Projetos','Exportacao_Limpa_R6'}:
        if src.suffix in {'.rbxmx','.json','.lua','.js','.html','.css','.md','.bbmodel'}:
            keep=True
        if src.name.endswith('.r6flip.json'):keep=True
        if src.name in {'manifest.json','manifest_intermediarias.json','manifest_auditoria.json','relatorio.md'}:keep=True
        if 'thumbs' in parts:keep=False
    if keep:
        safe_copy(src,OUT/'Ferramentas/RigFlip-Posto17'/src.relative_to(rig))
        rigcopied+=1
# Published game scripts create terrain, map and UI procedurally.
add_text(OUT/'Workspace/Mapa/LEIA-ME.md',
'''# Mapa / Workspace
O mapa do Posto 17 é criado por scripts Luau em `Projeto/ServerScriptService/`, principalmente `Posto17.server.lua`, `Facilities.lua`, `WorldDetail.lua`, `TestRange.lua` e `VisualShowcase.lua`.
A reprodução binária exata do jogo inteiro está em `Projeto/Compilado/Posto17-v126-COMPLETO.rbxl`.
''')
add_text(OUT/'StarterGui/LEIA-ME.md',
'''# Interfaces / StarterGui
A UI é construída dinamicamente pelos LocalScripts em `Projeto/StarterPlayer/StarterPlayerScripts/`:
`MenuInicial.client.lua`, `HUD.client.lua`, `AnimacaoIndividual.client.lua`, `TouchLayout.client.lua` e outros.
A reprodução exata de tudo já compilado está em `Projeto/Compilado/Posto17-v126-COMPLETO.rbxl`.
''')
add_text(OUT/'README.md',
'''# Posto 17 — cópia completa do jogo (v126; R6)

**Origem:** PC do integrador. **Alvo:** Roblox QA privado, Place ID `119377443515742`.  
**Rig obrigatório:** **R6 clássico**, não R15.

## Onde estão os arquivos
- `Compilado/Posto17-v126-COMPLETO.rbxl`: **arquivo Roblox completo e pronto para abrir no Studio** (alternativa mais fiel).
- `FonteRojo/`: o projeto completo para build, com `default.project.json` e todo `src/`, inclusive animações, modelos R6 e scripts.
- `ServerScriptService/`, `StarterPlayer/`, `ReplicatedStorage/`, `ServerStorage/`: espelho da hierarquia real do Studio; arquivos Luau como `.lua`, com caminho no topo.
- `Modelos_Editaveis/`: modelos 3D originais (Blockbench e arquivos auxiliares).
- `Ferramentas/RigFlip-Posto17/`: editor local e sequências para auditoria das animações.
- `Workspace/Mapa/`: o mapa é gerado dinamicamente pelos scripts, não é um mapa estático separado.
- `StarterGui/`: UI gerada em runtime pelos LocalScripts.
- `GERADOR_DO_PROJETO.lua`: gerador por Command Bar para construir os objetos em Studio. **Para identidade integral do jogo, abra o .rbxl compilado.**
- `MANIFESTO_EXPORTACAO.json`: lista das correspondências de Script/ModuleScript/LocalScript.

## Compilar sem plugin no Studio
Use `Compilado/Posto17-v126-COMPLETO.rbxl` via Arquivo > Abrir do Roblox Studio. O jogo completo
aparece como Place. Não é necessário plugin. Com Rojo CLI, também é possível compilar
`FonteRojo/default.project.json`, a partir da pasta FonteRojo:
`rojo build default.project.json --output Posto17-v126.rbxl`.

**Não execute scripts originais da pasta Ferramentas sem inspeção.**
**Nenhuma chave de publicação, senha ou token foi incluído.**  

## Trabalho conjunto
Toda mudança relevante deve entrar neste repositório, com entrada no
`PARA_O_CHATGPT/MURAL.md`. O Z.ai publica entregas R6 em
`Animacoes/` ou `Equipamentos/` e o ChatGPT integra após revisão e teste.
O usuário pode pedir publicação na experiência privada para testes no Fusion.
''')
add_text(OUT/'MANIFESTO_EXPORTACAO.json',json.dumps({
 'rig':'R6','place_id_qa':119377443515742,'base_version':126,
 'scripts':mappings,'model_files':models_copied,'rigflip_files':rigcopied,
 'source_count':len(mappings),'assets':asset_map
},ensure_ascii=False,indent=2)+'\n')
add_text(REPO/'.gitignore',
'''# Ignore personal credentials, environment and caches
.env
.env.*
*.pem
*.key
*secret*
*credentials*
*api_key*
**/.venv/
**/node_modules/
**/__pycache__/
**/.DS_Store
*.incomplete
''')
print('EXPORT FINISHED: source scripts',len(mappings),'editable model files',models_copied,'RigFlip files',rigcopied)
print('Staged new project size (MiB)',round(sum(p.stat().st_size for p in OUT.rglob('*') if p.is_file())/1048576,2))
