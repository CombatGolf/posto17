#!/usr/bin/env python3
"""Gera uma sequencia manualmente editavel: acordar -> sentar -> descer da cama.

A fonte nao e modificada. Depois da geracao, faca as correcoes de pose no
Blockbench e salve a copia editavel. A cama fica fora da armature e nao e
exportada junto ao avatar.
"""
from pathlib import Path
import base64
import copy
import json
import math
import uuid

BASE = Path(__file__).resolve().parent
SRC = BASE / "P17_Humanoide_Rig_Editavel.bbmodel"
DST = BASE / "P17_Levantar_da_Cama.bbmodel"

def uid():
    return str(uuid.uuid4())

def fmt(value):
    if abs(value) < 1e-8: value=0
    return f"{value:.4f}".rstrip("0").rstrip(".") if not float(value).is_integer() else str(int(value))

def key(channel, time, values):
    return dict(
        channel=channel,
        data_points=[dict(zip("xyz", map(fmt, values)))],
        uuid=uid(),
        time=float(time),
        color=-1,
        interpolation="linear",
    )

def skeletal(name):
    return dict(name=name, type="bone", rotation_global=False,
                quaternion_interpolation=False, keyframes=[])

def bedcube(name, bounds, color, export=False):
    # Usa uma malha real. Faces de cubo sem textura sao invisiveis no
    # Blockbench 5.2, enquanto faces de mesh usam material padrao.
    lo, hi=bounds
    mesh=copy.deepcopy(BED_TEMPLATE)
    mesh.update(name=name, uuid=uid(), type="mesh",
                color=color, export=export, visibility=True,
                origin=[0,0,0], rotation=[0,0,0])
    for k, vertex in mesh["vertices"].items():
        for axis in range(3):
            base_lo=BED_SOURCE_LO[axis]
            base_hi=BED_SOURCE_HI[axis]
            t=(vertex[axis]-base_lo)/(base_hi-base_lo)
            vertex[axis]=round(lo[axis]+t*(hi[axis]-lo[axis]),3)
    return mesh

rig = json.loads(SRC.read_text())
rig["name"] = "POSTO17 | Acordar e sair da cama"
rig["model_identifier"] = "p17_levantar_da_cama"
gmap={g["name"]:g for g in rig["groups"]}
emap={e["name"]:e for e in rig["elements"]}
BED_TEMPLATE=copy.deepcopy(emap["leg-left"])
BED_SOURCE_LO=[min(v[i] for v in BED_TEMPLATE["vertices"].values()) for i in range(3)]
BED_SOURCE_HI=[max(v[i] for v in BED_TEMPLATE["vertices"].values()) for i in range(3)]
assert set(emap)=={"leg-left","leg-right","torso","arm-left","arm-right","head"}

# Duas articulacoes em cada perna para eliminar o movimento robotico
# de mover a perna inteira como um bloco.
for side, suf, femenino in (("left","Esquerdo","Esquerda"),("right","Direito","Direita")):
    original=emap["leg-"+side]
    upper=copy.deepcopy(original)
    upper["name"]="Coxa_"+femenino
    upper["uuid"]=uid()
    lower=copy.deepcopy(original)
    lower["name"]="Canela_"+femenino
    lower["uuid"]=uid()
    for k, v in upper["vertices"].items():
        v[1]=max(8,v[1])
    for k, v in lower["vertices"].items():
        v[1]=min(8,v[1])
    rig["elements"].append(upper)
    rig["elements"].append(lower)
    knee=copy.deepcopy(gmap["Perna_"+femenino])
    knee.update(name="Joelho_"+suf,uuid=uid(),origin=(
        [3.2,8,0] if side=="left" else [-3.2,8,0]
    ))
    rig["groups"].append(knee)
    gmap[knee["name"]]=knee
    legnode=next(child for child in rig["outliner"][0]["children"]
                 if child["uuid"]==gmap["Perna_"+femenino]["uuid"])
    shoe_bounds = (
        ([0,0,-6.8],[6.4,2.7,3.2]) if side=="left"
        else ([-6.4,0,-6.8],[0,2.7,3.2])
    )
    shoe=bedcube("Bota_"+femenino,shoe_bounds,9,export=True)
    rig["elements"].append(shoe)
    legnode["children"]=[upper["uuid"],{
        "uuid":knee["uuid"], "isOpen":True,
        "children":[lower["uuid"],shoe["uuid"]]
    }]
rig["elements"]=[e for e in rig["elements"] if e["name"] not in ("leg-left","leg-right")]

# Cabeca simples com feicoes. O operador continua sendo low-poly, mas nao
# uma caixa vazia. Todos os detalhes seguem o osso Cabeca no animation.
details=[
    bedcube("Cabelo",([-6.55,41.6,-6.5],[6.55,44.0,6.5]),0,export=True),
    bedcube("Olho_Esquerdo",([2.1,37.3,-6.65],[3.5,38.5,-6.41]),15,export=True),
    bedcube("Olho_Direito",([-3.5,37.3,-6.65],[-2.1,38.5,-6.41]),15,export=True),
]
rig["elements"].extend(details)
def find_node(tree, node_id):
    for node in tree:
        if isinstance(node,str): continue
        if node["uuid"]==node_id: return node
        found=find_node(node["children"],node_id)
        if found: return found
    return None
head_node=find_node(rig["outliner"],gmap["Cabeca"]["uuid"])
assert head_node is not None
head_node["children"].extend(e["uuid"] for e in details)

# Cama cenografica: nao faz parte do rig nem da exportacao da animacao.
bed=[
    bedcube("01 | Estrado", ([ -20,7,-30],[20,11,30]), 5),
    bedcube("02 | Colchao", ([-18,11,-29],[18,14,29]), 6),
    bedcube("03 | Travesseiro", ([-11,14,15],[11,16,26]), 3),
    bedcube("04 | Cabeceira", ([-20,7,29],[20,26,31]), 4),
    bedcube("05 | Pe direito", ([16,0,-27],[20,9,-23]), 5),
    bedcube("06 | Pe esquerdo", ([-20,0,-27],[-16,9,-23]), 5),
    bedcube("07 | Pe direito traseiro", ([16,0,23],[20,9,27]), 5),
    bedcube("08 | Pe esquerdo traseiro", ([-20,0,23],[-16,9,27]), 5),
    bedcube("09 | Cobertor dobrado", ([-17,14,-27],[17,15,-22]), 1),
    bedcube("10 | Tapete lateral", ([20,.1,-18],[37,.35,7]), 2),
]
rig["elements"].extend(bed)
# Atlas P17 fosco: 16 cores de referencia, sem brilhos de catalogo.
# Ele fica incorporado ao .bbmodel para que seja editavel offline.
atlas=(BASE / "Paleta_P17_Cama.png")
assert atlas.is_file(), atlas
rig["resolution"]={"width":64,"height":64}
rig["textures"]=[dict(
    name=atlas.name,relative_path=atlas.name,folder="",namespace="",
    id="0",group="",scope=0,width=64,height=64,
    uv_width=64,uv_height=64,particle=False,
    use_as_default=False,layers_enabled=False,sync_to_project="",
    file_format="png",render_mode="default",render_sides="auto",
    wrap_mode="limited",pbr_channel="color",fps=7,
    force_translucent=False,frame_time=1,frame_order_type="loop",
    frame_order="",frame_interpolate=False,visible=True,
    internal=True,saved=True,uuid=uid(),
    source="data:image/png;base64,"+base64.b64encode(atlas.read_bytes()).decode()
)]
colormap={
    "torso":7,"arm-left":7,"arm-right":7,"head":8,
    "Coxa_Esquerda":6,"Coxa_Direita":6,
    "Canela_Esquerda":9,"Canela_Direita":9,
    "Bota_Esquerda":9,"Bota_Direita":9,
    "Cabelo":0,"Olho_Esquerdo":15,"Olho_Direito":15,
    "01 | Estrado":4,"02 | Colchao":1,"03 | Travesseiro":2,
    "04 | Cabeceira":3,"05 | Pe direito":4,"06 | Pe esquerdo":4,
    "07 | Pe direito traseiro":4,"08 | Pe esquerdo traseiro":4,
    "09 | Cobertor dobrado":5,"10 | Tapete lateral":11,
}
assert {e["name"] for e in rig["elements"]} == set(colormap)
for element in rig["elements"]:
    c=colormap[element["name"]]
    uv=[(c%4)*16+8,(c//4)*16+8]
    for face in element["faces"].values():
        face["texture"]=0
        for vertex in face["uv"]:
            face["uv"][vertex]=uv.copy()
ref=copy.deepcopy(gmap["Root"])
ref.update(name="CAMA_REFERENCIA_NAO_EXPORTAR",uuid=uid(),origin=[0,0,0],
           rotation=[0,0,0],export=False,selected=False,primary_selected=False)
rig["groups"].append(ref)
rig["outliner"].append({
    "uuid":ref["uuid"],"isOpen":False,
    "children":[e["uuid"] for e in bed],
})
gmap[ref["name"]]=ref

# Quadros de acao com poses distintas:
# 00-1.2 deitado, respira/olha
# 1.2-2.1 senta, apoiando-se
# 2.1-3.9 desloca o quadril, gira joelhos e poe os pes pela lateral
# 3.9-4.65 espera sentado, pes no chao
# 4.65-5.8 ergue o tronco, transfere o peso e fica em pe
t=[0,.5,1.05,1.6,2.05,2.55,3.05,3.55,4.05,4.55,5.05,5.5,5.85]
D={
    "Root": {
        "rotation":[(90,0,0)]*10+[(63,0,0),(25,0,0),(0,0,0)],
        "position":[
            (0,14,-20),(0,14,-20),(0,14,-20),(0,14,-20),
            (0,14,-20),(4,14,-20),(10,14,-20),(16,14,-20),
            (20,14,-20),(20,14,-20),
            (25,14-16*math.cos(math.radians(63)),
             -4-16*math.sin(math.radians(63))),
            (30,14-16*math.cos(math.radians(25)),
             -4-16*math.sin(math.radians(25))),
            (34,0,-4),
        ],
    },
    "Tronco":{
        "rotation":[
            (0,0,0),(-5,0,0),(-15,0,0),(-60,0,0),(-90,0,0),
            (-90,0,0),(-90,0,0),(-89,0,-7),(-88,0,-8),
            (-85,0,-10),(-60,0,-8),(-25,0,-3),(0,0,0),
        ],
    },
    "Cabeca":{
        "rotation":[
            (2,0,0),(-4,0,0),(-13,5,0),(-12,8,0),(1,4,0),
            (5,0,0),(6,3,0),(2,0,0),(-7,-7,0),(-8,-7,0),
            (-5,0,0),(0,0,0),(0,0,0),
        ],
    },
    "Perna_Esquerda":{
        "rotation":[
            (0,0,0)]*5+
            [(0,0,12),(0,0,33),(-15,0,32),(-39,0,17),
             (-40,0,16),(-24,0,8),(-11,0,3),(0,0,0)],
    },
    "Perna_Direita":{
        "rotation":[
            (0,0,0)]*5+
            [(0,0,9),(0,0,28),(-12,0,29),(-39,0,14),
             (-40,0,14),(-24,0,7),(-11,0,2),(0,0,0)],
    },
    "Joelho_Esquerdo":{
        "rotation":[
            (0,0,0)]*6+
            [(-10,0,0),(-26,0,0),(-50,0,0),(-50,0,0),
             (-39,0,0),(-14,0,0),(0,0,0)],
    },
    "Joelho_Direito":{
        "rotation":[
            (0,0,0)]*6+
            [(-10,0,0),(-30,0,0),(-50,0,0),(-50,0,0),
             (-39,0,0),(-14,0,0),(0,0,0)],
    },
    "Braco_Esquerdo":{
        "rotation":[
            (7,0,12),(8,0,10),(20,0,15),(36,0,25),(42,0,22),
            (22,0,10),(32,0,19),(44,0,26),(62,0,20),(65,0,15),
            (45,0,10),(15,0,6),(4,0,4),
        ],
    },
    "Braco_Direito":{
        "rotation":[
            (7,0,-12),(8,0,-10),(20,0,-15),(36,0,-25),(42,0,-22),
            (22,0,-10),(32,0,-19),(44,0,-26),(62,0,-20),(65,0,-15),
            (45,0,-10),(15,0,-6),(4,0,-4),
        ],
    }
}
assert len(t)==13
assert len(D)==len(gmap)-1
for name, channels in D.items():
    for channel, values in channels.items():
        assert len(values)==len(t), (name,channel,len(values))
    if "rotation" in channels:
        for values in channels["rotation"]:
            assert all(abs(n)<=180 for n in values)

anim=dict(
    uuid=uid(), name="acordar_sentar_girar_pernas_descer",
    loop="once", override=False, length=t[-1], snapping=24,
    selected=True, group_name="", scope=0, anim_time_update="",
    blend_weight="", start_delay="", loop_delay="", animators={}
)
for name, channels in D.items():
    a=skeletal(name)
    for channel, poses in channels.items():
        for moment, vals in zip(t,poses):
            a["keyframes"].append(key(channel,moment,vals))
    anim["animators"][gmap[name]["uuid"]]=a
rig["animations"]=[anim]
rig["timeline_setups"]=[]
DST.write_text(json.dumps(rig,indent=2,ensure_ascii=False)+"\n")

# Checagem de estrutura: todo modelo visivel pertence a uma arvore,
# cada grupo animado corresponde a uma articulacao verdadeira.
def collect(nodes):
    for node in nodes:
        if isinstance(node,str):
            yield node
        else:
            yield from collect(node["children"])
ids=set(collect(rig["outliner"]))
assert len(ids)==len(rig["elements"]),(len(ids),len(rig["elements"]))
assert ids=={e["uuid"] for e in rig["elements"]}
assert all(u in {g["uuid"] for g in rig["groups"]} for u in anim["animators"])
assert all(len(a["keyframes"])>=13 for a in anim["animators"].values())
print("CRIADO",DST)
print("DURACAO",anim["length"],"segundos")
print("ARTICULACOES_ANIMADAS",len(anim["animators"]))
print("QUADROS_DE_CONTROLE",len(t))
print("TOTAL_KEYFRAMES",sum(len(a["keyframes"]) for a in anim["animators"].values()))
print("MALHAS_PERSONAGEM",len(rig["elements"])-len(bed),"CENARIO_CAMA",len(bed))
