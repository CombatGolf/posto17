#!/usr/bin/env python3
"""Cria 9 movimentos corporais no mesmo rig Blockbench da cena da cama.
Não altera P17_Levantar_da_Cama.bbmodel. Nenhum movimento de equipamento.
"""
import copy, json, math, uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
src = json.loads((HERE/"P17_Levantar_da_Cama.bbmodel").read_text())
names = {g["name"]: g["uuid"] for g in src["groups"]}
root = src["animations"][0]
for side in ("Esquerdo", "Direito"):
    names["Cotovelo_"+side] = str(uuid.uuid5(uuid.NAMESPACE_URL,
                                            "Posto17-Cotovelo-"+side))
keys = ("Root","Tronco","Cabeca","Braco_Esquerdo","Braco_Direito",
        "Cotovelo_Esquerdo","Cotovelo_Direito",
        "Perna_Esquerda","Perna_Direita","Joelho_Esquerdo","Joelho_Direito")
assert all(name in names for name in keys)
serial = 0
def new_id():
    global serial
    serial += 1
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"p17-locomocao-basica-{serial}"))
def rot(x=0,y=0,z=0): return (x,y,z)
def pose(kind, u):
    theta = u*2*math.pi
    s, c = math.sin(theta), math.cos(theta)
    d = {name:rot() for name in keys}
    y = 0
    if kind == "parado":
        d["Tronco"] = rot(1.3*math.sin(theta))
        d["Cabeca"] = rot(-1.0*math.sin(theta))
        d["Braco_Esquerdo"] = rot(2.0*c,0,-2.8)
        d["Braco_Direito"] = rot(-2.0*c,0,2.8)
        d["Cotovelo_Esquerdo"] = rot(10.5)
        d["Cotovelo_Direito"] = rot(10.5)
        y = .18*(1-math.cos(theta))
    elif kind == "caminhar":
        d["Tronco"] = rot(-3, 3*s, 1.8*s)
        d["Cabeca"] = rot(1,-1.5*s)
        d["Braco_Esquerdo"] = rot(-24*s,0,-4)
        d["Braco_Direito"] = rot(24*s,0,4)
        d["Perna_Esquerda"] = rot(28*s)
        d["Perna_Direita"] = rot(-28*s)
        d["Joelho_Esquerdo"] = rot(-20*max(0,-s))
        d["Joelho_Direito"] = rot(-20*max(0,s))
        d["Cotovelo_Esquerdo"] = rot(12+10*max(0,-s))
        d["Cotovelo_Direito"] = rot(12+10*max(0,s))
        y = .42*(1-c*c)
    elif kind == "correr":
        d["Tronco"] = rot(-11,2*s,3*s)
        d["Cabeca"] = rot(7)
        d["Braco_Esquerdo"] = rot(-43*s,0,-9)
        d["Braco_Direito"] = rot(43*s,0,9)
        d["Perna_Esquerda"] = rot(47*s)
        d["Perna_Direita"] = rot(-47*s)
        d["Joelho_Esquerdo"] = rot(-52*max(0,-s))
        d["Joelho_Direito"] = rot(-52*max(0,s))
        d["Cotovelo_Esquerdo"] = rot(42+10*max(0,-s))
        d["Cotovelo_Direito"] = rot(42+10*max(0,s))
        y = .75*(1-c*c)
    elif kind in ("agachado","andar_agachado"):
        # Referencia: crouch/kneeling tatico assimetrico.
        # A perna esquerda fica plantada e a direita apoia o joelho atras.
        # Root -8u: joelho direito (y~8) se aproxima do chao.
        walk = kind == "andar_agachado"
        step = s if walk else 0
        lift = max(0, c) if walk else 0
        d["Root"] = rot(0, 0, -2+1.6*step)
        d["Tronco"] = rot(-23+2*step, 1.8*step, -2.8+1.4*step)
        d["Cabeca"] = rot(17-1.5*step, -1.2*step)
        d["Braco_Esquerdo"] = rot(43-8*step, -3, -10)
        d["Braco_Direito"] = rot(43+8*step, 3, 10)
        d["Cotovelo_Esquerdo"] = rot(43+8*step)
        d["Cotovelo_Direito"] = rot(43-8*step)
        d["Perna_Esquerda"] = rot(50+10*step, 0, -5)
        d["Joelho_Esquerdo"] = rot(-119-8*step)
        d["Perna_Direita"] = rot(0-11*step, 0, 6)
        d["Joelho_Direito"] = rot(-90+15*step)
        y = -8.0 + (0.24*lift if walk else .05*s)
    elif kind in ("deitado","rastejar"):
        # Prone normal: personagem voltado para BAIXO, com a cabeca apontada
        # para frente (-Z). No rig antigo +76 graus apontava para tras.
        moving = kind == "rastejar"
        step = s if moving else 0
        armPull = max(0, s)
        armPush = max(0,-s)
        d["Root"] = rot(-90, 0, 1.2*step)
        d["Tronco"] = rot(-2.0, 1.2*step)
        d["Cabeca"] = rot(69+3*step)
        # Bracos quase estendidos a frente, alternando uma puxada curta.
        d["Braco_Esquerdo"] = rot(150-6*step, -2, -8)
        d["Braco_Direito"] = rot(150+6*step, 2, 8)
        d["Cotovelo_Esquerdo"] = rot(30+10*step)
        d["Cotovelo_Direito"] = rot(30-10*step)
        # Joelhos apoiam os ciclos com pouca oscilacao vertical.
        d["Perna_Esquerda"] = rot(5+11*step)
        d["Perna_Direita"] = rot(5-11*step)
        d["Joelho_Esquerdo"] = rot(32+18*armPush)
        d["Joelho_Direito"] = rot(32+18*armPull)
        # Modelo mede ~44u. Centro do corpo em z ~0, altura do peito baixa.
        # Pequena progressao no root, compensada na costura do loop.
        y = 7.6 + (0.12*math.sin(2*theta) if moving else 0.07*s)
    elif kind == "duto":
        # Guarda o clip compacto original para dutos, sem substituir o prone.
        d["Root"] = rot(76)
        d["Tronco"] = rot(-6, 2*s)
        d["Cabeca"] = rot(-14,3*s)
        d["Braco_Esquerdo"] = rot(49-20*s,0,-12)
        d["Braco_Direito"] = rot(49+20*s,0,12)
        d["Cotovelo_Esquerdo"] = rot(0)
        d["Cotovelo_Direito"] = rot(0)
        d["Perna_Esquerda"] = rot(-9+16*s)
        d["Perna_Direita"] = rot(-9-16*s)
        d["Joelho_Esquerdo"] = rot(-17-18*max(0,-s))
        d["Joelho_Direito"] = rot(-17-18*max(0,s))
        y = 3.3+.16*s
    elif kind == "saltar_pousar":
        h = max(0,math.sin(math.pi*u))
        d["Tronco"] = rot(-7*h+5*max(0,(u-.65)/.35))
        d["Cabeca"] = rot(4*h)
        d["Braco_Esquerdo"] = rot(-25*h,0,-9*h)
        d["Braco_Direito"] = rot(-25*h,0,9*h)
        d["Cotovelo_Esquerdo"] = rot(15*h)
        d["Cotovelo_Direito"] = rot(15*h)
        d["Perna_Esquerda"] = rot(12*h)
        d["Perna_Direita"] = rot(12*h)
        d["Joelho_Esquerdo"] = rot(-30*h)
        d["Joelho_Direito"] = rot(-30*h)
        y = 5.5*h
    return d,y

clips = [
    ("P17_Parado_Respirar", "parado", 2.8, True),
    ("P17_Caminhar", "caminhar", .95, True),
    ("P17_Correr", "correr", .72, True),
    ("P17_Agachado_Parado", "agachado", 2.8, True),
    ("P17_Andar_Agachado", "andar_agachado", 1.10, True),
    ("P17_Deitado_Parado", "deitado", 3.0, True),
    ("P17_Rastejar", "rastejar", 1.35, True),
    ("P17_Rastejar_Duto", "duto", 1.35, True),
    ("P17_Saltar_Pousar", "saltar_pousar", .90, False),
]

def frame(t, v, channel):
    return {
        "channel":channel,
        "data_points":[{name:f"{0 if abs(value)<.00005 else value:.4f}" for name,value in zip(("x","y","z"),v)}],
        "uuid":new_id(),"time":round(t,4),
        "color":-1,"interpolation":"linear"
    }

anims = []
for title,kind,length,loop in clips:
    anim = {k:copy.deepcopy(v) for k,v in root.items() if k != "animators"}
    anim["uuid"],anim["name"],anim["length"] = new_id(),title,length
    anim["loop"],anim["selected"] = "loop" if loop else "once",False
    anim["snapping"],anim["animators"] = 24,{}
    for name in keys:
        a = {"name":name,"type":"bone","rotation_global":False,
             "quaternion_interpolation":False,"keyframes":[]}
        for i in range(13):
            u=i/12
            d,y=pose(kind,u)
            a["keyframes"].append(frame(u*length,d[name],"rotation"))
            if name=="Root":
                a["keyframes"].append(frame(u*length,(0,y,21 if kind in ("deitado","rastejar") else 0),"position"))
        anim["animators"][names[name]]=a
    anims.append(anim)

out = copy.deepcopy(src)
out["elements"] = out["elements"][:13]
out["groups"] = [g for g in out["groups"] if g["name"] != "CAMA_REFERENCIA_NAO_EXPORTAR"]
out["outliner"] = [o for o in out["outliner"] if not isinstance(o,dict) or o.get("uuid") != names["CAMA_REFERENCIA_NAO_EXPORTAR"]]
# Dividir os dois braços no cotovelo: malha contínua no repouso.
# Isto permite apoios reais nos antebracos durante agachamento/rastejo.
for side, original in (("Esquerdo","arm-left"),("Direito","arm-right")):
    arm = next(e for e in out["elements"] if e["name"] == original)
    forearm = copy.deepcopy(arm)
    forearm["uuid"] = str(uuid.uuid5(uuid.NAMESPACE_URL,"Posto17-Antebraco-"+side))
    forearm["name"] = "Antebraco_"+side
    arm["name"] = "Braco_Superior_"+side
    split = 21.6
    for v in arm["vertices"].values():
        v[1] = max(v[1],split)
    for v in forearm["vertices"].values():
        v[1] = min(v[1],split)
    out["elements"].append(forearm)
    elbowgroup = {"name":"Cotovelo_"+side, "origin":[9.6 if side=="Esquerdo" else -9.6,split,-1.6],
                  "uuid":names["Cotovelo_"+side], "children":[], "export":True}
    out["groups"].append(elbowgroup)
    def insert_elbow(node):
        if isinstance(node,dict):
            if node["uuid"] == names["Braco_"+side]:
                children=node["children"]
                children.append({"uuid":elbowgroup["uuid"],"isOpen":True,"children":[forearm["uuid"]]})
                return True
            for item in node.get("children",[]):
                if insert_elbow(item): return True
        return False
    assert any(insert_elbow(x) for x in out["outliner"])
out["animations"] = anims
out["meta"]["model_format"]="free"
out["name"]="P17 — Protagonista / Locomoção"
dest = HERE/"P17_Operador_8_Movimentos.bbmodel"
dest.write_text(json.dumps(out,ensure_ascii=False,indent=2))
assert len(out["elements"])==15 and len(out["animations"])==9
assert len(out["groups"])==11 and len(out["outliner"])==1
print("GERADOS",len(out["animations"]),"clips,",len(out["elements"]),"malhas,",dest.stat().st_size,"bytes")
for a in out["animations"]:
    n=sum(len(x["keyframes"]) for x in a["animators"].values())
    print(" -",a["name"],a["length"],"segundos,",n,"quadros-chave")
