#!/usr/bin/env python3
"""Generate Studio Command Bar importer from self-contained Luau and XML in Projeto/.
The canonical complete version remains Projeto/Compilado/Posto17-v131-COMPLETO.rbxl.
This generator recreates source scripts, models, R6 keyframes, and UI definitions.
"""
from pathlib import Path
import json,xml.etree.ElementTree as ET,base64
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'Projeto'
manifest=json.loads((OUT/'MANIFESTO_EXPORTACAO.json').read_text())
def lua_str(value):
    # choose a non-colliding Lua long-string delimiter
    for n in range(1,9):
        opening='['+'='*n+'['
        closing=']'+'='*n+']'
        if closing not in value:return opening+value+closing
    raise ValueError('delimiter conflict')
scripts=[]
for row in manifest['scripts']:
    source=(ROOT/row['file']).read_text()
    assert source.startswith('-- Local no Studio: ')
    scripts.append({'studio':row['studio'],'class':row['class'],'source':source})
assert len(scripts)>=50
def parse_float(text,default=0):
    try:return float(text)
    except (ValueError,TypeError):return default
def props_of(elem):
    result=[]
    if elem is None:return result
    for p in elem:
        n=p.get('name')
        tag=p.tag
        if not n:continue
        v=None
        if tag in ('string','bool','float','double','int','int64','token'):
            if tag=='string':v=p.text or ''
            elif tag=='bool':v=(p.text or '').lower()=='true'
            else:v=parse_float(p.text)
        elif tag in ('Content','ContentId'):
            v=p.findtext('url') or p.text or ''
            tag='string'
        elif tag in ('CoordinateFrame','OptionalCoordinateFrame'):
            # OptionalCoordinateFrame may wrap CoordinateFrame
            target=p if tag=='CoordinateFrame' else p.find('CoordinateFrame')
            if target is None:continue
            v=[parse_float(target.findtext(t)) for t in ('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22')]
            tag='CFrame'
        elif tag in ('Vector3','Vector2'):
            keys=('X','Y','Z') if tag=='Vector3' else ('X','Y')
            v=[parse_float(p.findtext(key)) for key in keys]
        elif tag=='Color3':
            v=[parse_float(p.findtext(key)) for key in ('R','G','B')]
        elif tag=='Color3uint8':
            try:
                val=int(p.text)
                v=[(val>>16 & 255)/255,(val>>8 & 255)/255,(val & 255)/255]
                tag='Color3'
            except Exception:pass
        elif tag=='UDim2':
            v=[parse_float(p.findtext(x)) for x in ('XS','XO','YS','YO')]
        elif tag=='UDim':
            v=[parse_float(p.findtext(x)) for x in ('S','O')]
        elif tag=='NumberRange':
            v=[parse_float(p.findtext(x)) for x in ('Min','Max')]
        elif tag=='Ref':
            v=p.text or ''
        elif tag=='NumberSequence':
            v=[]
            for item in p.findall('Keypoint'):
                v.append([parse_float(item.findtext('Time')),parse_float(item.findtext('Value')),parse_float(item.findtext('Envelope'))])
        elif tag=='ColorSequence':
            v=[]
            for item in p.findall('Keypoint'):
                c=item.find('Value')
                color=[parse_float(c.findtext(x)) for x in ('R','G','B')] if c is not None else [1,1,1]
                v.append([parse_float(item.findtext('Time'))]+color)
        else:
            continue
        if v is not None:
            result.append([n,tag,v])
    return result

ASSET_MAP={
 'Posto17R6StarterCharacter.rbxmx':'StarterPlayer',
 'Posto17R6Preview.rbxmx':'ReplicatedStorage/Posto17Shared',
 'Posto17R6Interacoes.rbxmx':'ReplicatedStorage/Posto17Shared',
 'Posto17R6Corpo.rbxmx':'ReplicatedStorage/Posto17Shared',
 'Posto17R6Amostras.rbxmx':'ReplicatedStorage/Posto17Shared',
 'StoreBed.rbxmx':'ReplicatedStorage/Posto17Shared',
 'StoreDoor.rbxmx':'ReplicatedStorage/Posto17Shared',
 'Posto17RobloxWeapons.rbxmx':'ServerStorage',
}
asset_groups=[]
for name,service in ASSET_MAP.items():
    root=ET.parse(OUT/'FonteRojo/src/assets'/name).getroot()
    nodes=[]
    def visit(item,parent_idx):
        idx=len(nodes)+1
        typ=item.get('class')
        ref=item.get('referent')
        pr=props_of(item.find('Properties'))
        nodes.append([typ,parent_idx,ref,pr])
        for child in item.findall('Item'):visit(child,idx)
    for item in root.findall('Item'):visit(item,0)
    asset_groups.append({'source':name,'service':service,'nodes':nodes})
    print('SERIALIZED',name,len(nodes),'objects')
# The legacy R15 StoreWalk archive is preserved as .rbxm and within .rbxl,
# but is not loaded by the R6-only runtime or the Command Bar generator.
assert len(asset_groups)==8

head=r'''-- POSTO 17 / GERADOR DO PROJETO | R6 CLASSICO
-- Execute no Roblox Studio > View > Command Bar (modo EDICAO).
-- Restaurar o projeto completo sem reconstruir: abra Compilado/Posto17-v131-COMPLETO.rbxl.
-- Este gerador cria scripts Luau, rigs, mapas via scripts e sequencias R6,
-- sem baixar assets externos nem depender de plugins.
-- NAO execute em servidores publicos. Execute apenas no Studio em uma cópia vazia.
local HttpService = game:GetService("HttpService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local countScripts,countInstances = 0,0
local activeScripts={}
local failCount=0
local function warnSet(className,prop,msg)
    failCount+=1
    if failCount<18 then warn("[Posto17] Propriedade nao aplicada:",className,prop,msg) end
end
local function destination(path)
    local parent
    local first=true
    for piece in string.gmatch(path,"[^/]+") do
        if first then
            parent=game:GetService(piece)
            first=false
        else
            local nextObj=parent:FindFirstChild(piece)
            if not nextObj then
                nextObj=Instance.new("Folder")
                nextObj.Name=piece
                nextObj.Parent=parent
            end
            parent=nextObj
        end
    end
    return parent
end
local function enumValue(name,value)
    local mapping={
        Priority="AnimationPriority",RigType="HumanoidRigType",
        EasingStyle="PoseEasingStyle",EasingDirection="PoseEasingDirection",
        MeshType="MeshType",Face="NormalId",Material="Material",
        BackSurface="SurfaceType",BottomSurface="SurfaceType",
        FrontSurface="SurfaceType",LeftSurface="SurfaceType",
        RightSurface="SurfaceType",TopSurface="SurfaceType",
        Orientation="OrientationAlignmentMode",Shape="PartType",
        AutomaticSize="AutomaticSize",TextXAlignment="TextXAlignment",
        TextYAlignment="TextYAlignment",ScaleType="ScaleType",
        ZIndexBehavior="ZIndexBehavior",BorderMode="BorderMode",
        SizeConstraint="SizeConstraint",Font="Font",
    }
    local category=mapping[name]
    if not category then return nil end
    local enum=Enum[category]
    if not enum then return nil end
    for _,item in ipairs(enum:GetEnumItems()) do
        if item.Value==value then return item end
    end
    return nil
end
local function propertyValue(prop,kind,v)
    if kind=="CFrame" then
        return CFrame.new(table.unpack(v))
    elseif kind=="Vector3" then
        return Vector3.new(table.unpack(v))
    elseif kind=="Vector2" then
        return Vector2.new(table.unpack(v))
    elseif kind=="Color3" then
        return Color3.new(table.unpack(v))
    elseif kind=="UDim2" then
        return UDim2.new(table.unpack(v))
    elseif kind=="UDim" then
        return UDim.new(table.unpack(v))
    elseif kind=="NumberRange" then
        return NumberRange.new(table.unpack(v))
    elseif kind=="NumberSequence" then
        local points={}
        for _,k in ipairs(v) do
            table.insert(points,NumberSequenceKeypoint.new(k[1],k[2],k[3]))
        end
        return NumberSequence.new(points)
    elseif kind=="ColorSequence" then
        local points={}
        for _,k in ipairs(v) do
            table.insert(points,ColorSequenceKeypoint.new(k[1],Color3.new(k[2],k[3],k[4])))
        end
        return ColorSequence.new(points)
    elseif kind=="token" then
        return enumValue(prop,v) or v
    end
    return v
end
local function installAsset(group)
    local folder=destination(group.service)
    local instanceList={}
    local refList={}
    local delayed={}
    for i,item in ipairs(group.nodes) do
        local typ,parentIndex,referent,props=item[1],item[2],item[3],item[4]
        local success,obj=pcall(Instance.new,typ)
        if not success then
            warnSet(typ,"Instance.new",obj)
        else
            instanceList[i]=obj
            if referent then refList[referent]=obj end
            for _,prop in ipairs(props) do
                local key,kind,v=prop[1],prop[2],prop[3]
                if kind=="Ref" then
                    if v~="null" and v~="" then table.insert(delayed,{obj,key,v}) end
                elseif key=="Source" then
                    -- Assets from earlier Studio versions may omit embedded source.
                    -- The canonical .rbxl includes exact original serialized data.
                else
                    local result,value=pcall(propertyValue,key,kind,v)
                    if result then
                        local ok,err=pcall(function()obj[key]=value end)
                        if not ok and key~="AttributesSerialize" and key~="SourceAssetId" then
                            warnSet(typ,key,err)
                        end
                    end
                end
            end
            obj.Parent=parentIndex>0 and instanceList[parentIndex] or folder
            countInstances+=1
        end
    end
    for _,ref in ipairs(delayed) do
        local source,key,target=ref[1],ref[2],ref[3]
        local obj=refList[target]
        if obj then
            pcall(function()source[key]=obj end)
        end
    end
    print("[Posto17]",group.source,#group.nodes,"objetos")
end
local function installScript(item)
    local className=item.class
    local segments=string.split(item.studio,"/")
    local scriptName=segments[#segments]
    local parentPath=table.concat(segments,"/",1,#segments-1)
    local parent=destination(parentPath)
    local old=parent:FindFirstChild(scriptName)
    if old and old:IsA(className) then old:Destroy() end
    local object=Instance.new(className)
    object.Name=scriptName
    if object:IsA("BaseScript") then object.Disabled=true end
    local ok,err=pcall(function()object.Source=item.source end)
    if not ok then error("Sem permissao para atribuir Source em "..item.studio..": "..tostring(err)) end
    object.Parent=parent
    if object:IsA("BaseScript") then table.insert(activeScripts,object) end
    countScripts+=1
end
pcall(function()Workspace.StreamingEnabled=true end)
pcall(function()StarterPlayer.LoadCharacterAppearance=false end)
'''

tail=r'''
-- Importacao local, por ordem: assets/rigs primeiro, scripts depois.
-- Evita scripts executando enquanto os modelos estao incompletos.
print("[Posto17] Restaurando modelos, rigs e sequencias R6...")
for _,group in ipairs(assetData) do installAsset(group) end
print("[Posto17] Criando scripts Lua e ModuleScripts...")
for _,item in ipairs(sourceScripts) do installScript(item) end
for _,entry in ipairs(activeScripts) do
    if entry.Parent then entry.Disabled=false end
end
print(string.format("[Posto17] Concluido: %d scripts, %d instancias, %d avisos de propriedades.",
  countScripts,countInstances,failCount))
print("[Posto17] Para reproducao 100%% exata e imediata do mapa, use o .rbxl na pasta Compilado.")
'''

scriptdata=json.dumps(scripts,ensure_ascii=False,separators=(',',':'))
assetdata=json.dumps(asset_groups,ensure_ascii=False,separators=(',',':'))
code=head
code+='local sourceScripts=HttpService:JSONDecode('+lua_str(scriptdata)+')\n'
code+='local assetData=HttpService:JSONDecode('+lua_str(assetdata)+')\n'
code+=tail
assert len(code)<50_000_000
out=OUT/'GERADOR_DO_PROJETO.lua'
out.write_text(code)
(OUT/'RELATORIO_GERADOR.md').write_text(f'''# Gerador de projeto (Command Bar)

- Gerado automaticamente com {len(scripts)} scripts e {sum(len(g['nodes']) for g in asset_groups)} instâncias de modelos e animações.
- Tamanho do gerador: {len(code):,} caracteres.
- Inclui todos os scripts e os principais modelos/rigs/seqüências R6 a partir do projeto original.
- **Recomendado:** para abrir integralmente o jogo no Studio sem reconstrução, utilize
  `Compilado/Posto17-v131-COMPLETO.rbxl`. É o artefato exato gerado pelo Rojo.
- O gerador cria scripts e propriedades via APIs do Studio; alguns dados legados de
  assets serializados (como `StoreWalk.rbxm` R15 e scripts internos protegidos em
  `Posto17RobloxWeapons.rbxmx`) permanecem no `.rbxl` compilado, não totalmente
  reproduzíveis pelo gerador de texto. Essas diferenças não afetam a cópia compilada.
- O gerador precisa ser rodado na **barra de comandos do Roblox Studio** em modo edição,
  em um Place vazio, não como Script do jogo.
- Não executado em Roblox Studio nesta exportação. Compile o `.rbxl` para teste real.
''')
print('GENERATOR',out,len(code),'bytes, source',len(scripts),'asset inst',sum(len(g['nodes']) for g in asset_groups))
