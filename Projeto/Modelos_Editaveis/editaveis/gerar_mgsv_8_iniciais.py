#!/usr/bin/env python3
"""Oito clipes originais de movimento, referenciados nas oito primeiras
categorias do video MGSV https://youtu.be/J24utG52ya0 (0:00 a 3:35).
Preserva o corpo existente; adiciona tornozelos para apoio de ponta de pé.
Nao altera animacoes antigas nem modelos publicados.
"""
import copy, json, math, uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASE = json.loads((HERE/"P17_Operador_8_Movimentos.bbmodel").read_text())
DEST = HERE/"P17_MGSV_8_Iniciais.bbmodel"
source_group = {g["name"]:g for g in BASE["groups"]}
S = math.sin
C = math.cos
PI = math.pi
def u_id(tag):
    return str(uuid.uuid5(uuid.NAMESPACE_URL,"P17-mgsv-ref-v3-"+tag))
def clamp(x,a=0,b=1): return max(a,min(b,x))
def ease(u): u=clamp(u); return u*u*(3-2*u)
def interp(a,b,t): return a+(b-a)*t
def rot(x=0,y=0,z=0): return (x,y,z)
def g(name, poses, x=0,y=0,z=0): poses[name]=(x,y,z)
def make_base():
    return {name:rot() for name in GROUPS}

def locomotion(u,mode):
    """Ciclo original: contato, transferencia, elevacao, oscilacao."""
    t=2*PI*u
    s,c=S(t),C(t)
    fast = mode in ("run","sprint")
    sprint = mode=="sprint"
    power = 1.0 if mode=="walk" else (1.45 if mode=="run" else 1.84)
    p=make_base()
    # Pés em oposicao: perna de sustentacao com joelho ligeiramente flexionado;
    # perna pendular flexiona ao avancar. Tornozelo compensa a inclinacao.
    for side,phase in (("Esquerda",0),("Direita",PI)):
        suffix="Esquerda" if side=="Esquerda" else "Direita"
        q=S(t+phase)
        swing=max(0,-q)
        knee=interp(9,17,power/1.84)+interp(14,35,power/1.84)*swing
        hip=(24*power)*q + (6 if sprint else 0)
        g("Perna_"+suffix,p,hip,0,(2.5 if side=="Esquerda" else -2.5)*power)
        key="Esquerdo" if side=="Esquerda" else "Direito"
        g("Joelho_"+key,p,-knee)
        g("Tornozelo_"+key,p, -hip+knee*.42+7*max(0,q))
    g("Tronco",p,-(3 if mode=="walk" else (12 if mode=="run" else 25)),
      3.4*s, 2.2*S(2*t))
    g("Cabeca",p,(2 if mode=="walk" else (9 if mode=="run" else 19)), -2*s)
    armPitch=(18 if mode=="walk" else (47 if mode=="run" else 65))
    g("Braco_Esquerdo",p,-armPitch*s-5,0,-8)
    g("Braco_Direito",p,armPitch*s-5,0,8)
    g("Cotovelo_Esquerdo",p,18+(46 if fast else 9)*max(0,-s))
    g("Cotovelo_Direito",p,18+(46 if fast else 9)*max(0,s))
    # movimento vertical discreto para evitar saltos exagerados
    y=(.21 if mode=="walk" else (.46 if mode=="run" else .57))*abs(S(2*t))
    g("Root",p,(0 if mode=="walk" else -1.5), 0, 0)
    return p,(0,y,0)

def sole_y(p, side):
    # Cinematica vertical do rig: quadril y16, joelho y8, tornozelo y2.7.
    # Apoio leva em conta a frente e o calcanhar da bota.
    suffix = "Esquerdo" if side=="Esquerda" else "Direito"
    hip = p["Perna_"+side][0] * PI/180
    knee = p["Joelho_"+suffix][0] * PI/180
    ankle = p["Tornozelo_"+suffix][0] * PI/180
    shin = hip + knee
    foot = shin + ankle
    ankleY = 16 - 8*C(hip) - 5.3*C(shin)
    bottom = ankleY - 2.7*C(foot)
    return bottom + min(6.8*S(foot),-3.2*S(foot))

def ground_y(p):
    return -min(sole_y(p,"Esquerda"),sole_y(p,"Direita"))

def idle(u):
    t=2*PI*u
    p=make_base()
    g("Root",p,0,0,0)
    g("Tronco",p, .95*S(t))
    g("Cabeca",p, -.70*S(t),2*S(t*.5))
    g("Braco_Esquerdo",p,1.25*S(t),0,-3.1)
    g("Braco_Direito",p,-1.25*S(t),0,3.1)
    g("Cotovelo_Esquerdo",p,11)
    g("Cotovelo_Direito",p,11)
    g("Joelho_Esquerdo",p,-3)
    g("Joelho_Direito",p,-3)
    return p,(0,.13*(1-C(t)),0)

def crouch_idle(u):
    """Apoio assimetrico no joelho traseiro, peito inclinado e pé dianteiro no solo."""
    t=2*PI*u
    p=make_base()
    g("Root",p,0,0,-1)
    g("Tronco",p,-43+.75*S(t),-3,0)
    g("Cabeca",p,28-.65*S(t),3)
    # Coxa dianteira horizontal, joelho alto, pé dianteiro plantado.
    g("Perna_Esquerda",p,68,0,-12)
    g("Joelho_Esquerdo",p,-130)
    g("Tornozelo_Esquerdo",p,62)
    # Joelho traseiro a altura do chao; pé apoiado na ponta.
    g("Perna_Direita",p,-1,0,12)
    g("Joelho_Direito",p,-120)
    g("Tornozelo_Direito",p,121)
    g("Braco_Esquerdo",p,78,0,-18)
    g("Braco_Direito",p,74,0,18)
    g("Cotovelo_Esquerdo",p,-44+2*S(t))
    g("Cotovelo_Direito",p,-40-2*S(t))
    return p,(0,ground_y(p)+.03*S(t),0)

def crouch_walk(u):
    """Crouch baixo com apoio alternado, sem quicar nem virar engatinhar."""
    t=2*PI*u
    s,c=S(t),C(t)
    p=make_base()
    g("Root",p,0,0,-.8*S(t))
    g("Tronco",p,-46,2.4*s,-2*S(2*t))
    g("Cabeca",p,29,-2*s)
    # Quando um pe avancar, outro sustenta o corpo; a pelvis fica baixa.
    for side,phase in (("Esquerda",0),("Direita",PI)):
        cycle=t+phase
        lift=max(0,-C(cycle))
        stride=S(cycle)
        hip=80+5*lift+2*stride*lift
        knee=-135-10*lift
        suffix="Esquerdo" if side=="Esquerda" else "Direito"
        ankle=-(hip+knee)-4*(1-lift)
        g("Perna_"+side,p,hip,0,12 if side=="Esquerda" else -12)
        g("Joelho_"+suffix,p,knee)
        g("Tornozelo_"+suffix,p,ankle)
    g("Braco_Esquerdo",p,65-9*s,0,-17)
    g("Braco_Direito",p,65+9*s,0,17)
    g("Cotovelo_Esquerdo",p,34+7*max(0,s))
    g("Cotovelo_Direito",p,34+7*max(0,-s))
    return p,(0,ground_y(p)+.035*abs(S(2*t)),0)

def pivot(u,mode):
    """Freada de apoio, giro de quadril e retomada de corrida."""
    sprint = mode=="sprint"
    running=locomotion(u*1.35,mode)[0]
    p=make_base()
    brake=ease(u/.30)
    turn=ease((u-.26)/.42)
    depart=ease((u-.62)/.38)
    # Na freada, perna dianteira firma o apoio e quadril fica baixo.
    for key in GROUPS: p[key]=running[key]
    g("Root",p,-(3 if sprint else 1)*brake,178*turn,-5*brake*(1-depart))
    g("Tronco",p,interp(-(25 if sprint else 12),-31,brake*(1-depart)),
      (18 if sprint else 12)*S(PI*turn),-8*S(PI*turn))
    g("Cabeca",p,18*brake*(1-depart),-12*S(PI*turn))
    g("Perna_Esquerda",p,interp(running["Perna_Esquerda"][0],61,brake*(1-depart)),
      0,-6*brake)
    g("Perna_Direita",p,interp(running["Perna_Direita"][0],-24,brake*(1-depart)),
      0,7*brake)
    g("Joelho_Esquerdo",p,-(42 if sprint else 36)*brake*(1-depart)-10)
    g("Joelho_Direito",p,-(37 if sprint else 28)*brake*(1-depart)-12)
    g("Tornozelo_Esquerdo",p,23*brake*(1-depart))
    g("Tornozelo_Direito",p,-18*brake*(1-depart))
    g("Braco_Esquerdo",p,58*brake*(1-depart)-30*depart)
    g("Braco_Direito",p,34*brake*(1-depart)+30*depart)
    g("Cotovelo_Esquerdo",p,53*brake+17)
    g("Cotovelo_Direito",p,53*brake+17)
    y= -2.7*brake*(1-depart)
    return p,(.9*S(PI*turn),y,-2.2*brake*(1-depart))

def setup_rig(base):
    # Os antebracos vem do pacote antigo. Os sapatos ganham articulacao propria.
    out=copy.deepcopy(base)
    assert len(out["elements"])==15 and len(out["groups"])==11
    for side,sign in (("Esquerda",1),("Direita",-1)):
        suffix="Esquerdo" if sign>0 else "Direito"
        name="Tornozelo_"+suffix
        gid=u_id("bone-"+name)
        shoe_name="Bota_"+side
        shoe=next(e for e in out["elements"] if e["name"]==shoe_name)
        knee=next(g for g in out["groups"] if g["name"]=="Joelho_"+suffix)
        out["groups"].append({"uuid":gid,"name":name,
            "origin":[3.2*sign,2.7,0],"export":True,"children":[]})
        def walk(node):
            if isinstance(node,dict):
                if node["uuid"]==knee["uuid"]:
                    children=node["children"]
                    children.remove(shoe["uuid"])
                    children.append({"uuid":gid,"isOpen":True,"children":[shoe["uuid"]]})
                    return True
                for child in node.get("children",[]):
                    if walk(child): return True
            return False
        assert walk(out["outliner"][0])
    return out

out=setup_rig(BASE)
GROUPS=tuple(x["name"] for x in out["groups"])
groupids={x["name"]:x["uuid"] for x in out["groups"]}
assert len(GROUPS)==13
samples=[
 ("P17_01_Idle","idle",2.4,True,24,"0:00","0:11"),
 ("P17_02_Walk","walk",1.14,True,36,"0:11","0:45"),
 ("P17_03_Run","run",.78,True,30,"0:45","1:10"),
 ("P17_04_Run_Pivot","run_pivot",1.35,False,45,"1:10","1:30"),
 ("P17_05_Sprint","sprint",.70,True,30,"1:30","2:08"),
 ("P17_06_Sprint_Pivot","sprint_pivot",1.42,False,48,"2:08","2:33"),
 ("P17_07_Crouch_Idle","crouch_idle",2.40,True,30,"2:33","2:53"),
 ("P17_08_Crouch_Walk","crouch_walk",1.16,True,36,"2:53","3:35"),
]
def make_key(t,channel,xyz,clipname,bone,i):
    xyz=["0.0000" if abs(x)<.00005 else f"{x:.4f}" for x in xyz]
    return {"channel":channel,"data_points":[dict(zip(("x","y","z"),xyz))],
            "uuid":u_id(f"{clipname}-{bone}-{channel}-{i}"),
            "time":round(t,5),"color":-1,"interpolation":"linear"}

def sample(kind,u):
    if kind=="idle":return idle(u)
    if kind=="crouch_idle":return crouch_idle(u)
    if kind=="crouch_walk":return crouch_walk(u)
    if kind=="run_pivot":return pivot(u,"run")
    if kind=="sprint_pivot":return pivot(u,"sprint")
    return locomotion(u,kind)

out["animations"]=[]
for name,kind,duration,loop,count,start,end in samples:
    animation={"uuid":u_id(name),"name":name,"loop":"loop" if loop else "once",
               "override":False,"length":duration,"snapping":30,"selected":False,
               "group_name":"","scope":0,"anim_time_update":"","blend_weight":"",
               "start_delay":"","loop_delay":"","animators":{}}
    for bone in GROUPS:
        keyframes=[]
        for i in range(count+1):
            u=i/count
            pose,pos=sample(kind,u)
            keyframes.append(make_key(u*duration,"rotation",pose[bone],name,bone,i))
            if bone=="Root":
                keyframes.append(make_key(u*duration,"position",pos,name,bone,i))
        animation["animators"][groupids[bone]]={
            "name":bone,"type":"bone","rotation_global":False,
            "quaternion_interpolation":False,"keyframes":keyframes}
    out["animations"].append(animation)
out["name"]="P17 / oito movimentos basicos (referencia MGSV)"
DEST.write_text(json.dumps(out,ensure_ascii=False,indent=2))
print("CRIADO",DEST,"bytes",DEST.stat().st_size)
for a in out["animations"]:
    print(a["name"],a["length"],len(a["animators"]))
