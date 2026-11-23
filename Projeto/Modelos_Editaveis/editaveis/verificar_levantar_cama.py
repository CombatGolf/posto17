#!/usr/bin/env python3
"""Teste local do projeto animado e da exportacao para glTF 2.0."""
from pathlib import Path
import json
import struct

BASE=Path(__file__).resolve().parent
SOURCE=BASE/"P17_Levantar_da_Cama.bbmodel"
EXPORT=BASE/"P17_Levantar_da_Cama_Anim.glb"
source=json.loads(SOURCE.read_text())
assert source["meta"]["model_format"]=="free"
assert len(source["elements"])==23, "23 malhas: 13 corpo e 10 cama"
assert len(source["groups"])==10, "7 grupos iniciais + 2 joelhos + cama"
assert len(source["textures"])==1, "atlas de cores incorporado"
assert len(source["animations"])==1
animation=source["animations"][0]
assert animation["name"]=="acordar_sentar_girar_pernas_descer"
assert abs(animation["length"]-5.85)<1e-4
assert len(animation["animators"])==9
keycount=sum(len(a.get("keyframes",[])) for a in animation["animators"].values())
assert keycount==130,keycount
names={a["name"] for a in animation["animators"].values()}
expected={
    "Root","Tronco","Cabeca","Braco_Esquerdo","Braco_Direito",
    "Perna_Esquerda","Perna_Direita","Joelho_Esquerdo","Joelho_Direito",
}
assert names==expected,(names,expected)
assert all(len(a["keyframes"])>=13 for a in animation["animators"].values())
exported_bed={e["name"] for e in source["elements"]
              if e["name"].startswith(("01 |","02 |","03 |","04 |","05 |",
                                      "06 |","07 |","08 |","09 |","10 |"))
              and e.get("export")}
assert not exported_bed,"O cenario nao deve entrar no GLB do personagem"

glb=EXPORT.read_bytes()
assert glb[:4]==b"glTF"
assert struct.unpack_from("<I",glb,4)[0]==2
assert struct.unpack_from("<I",glb,8)[0]==len(glb)
json_length, json_tag=struct.unpack_from("<II",glb,12)
assert json_tag==0x4E4F534A
gltf=json.loads(glb[20:20+json_length])
assert gltf["asset"]["version"]=="2.0"
assert len(gltf["skins"])==1
assert len(gltf["animations"])==1
clip=gltf["animations"][0]
assert clip["name"]==animation["name"]
assert len(clip["channels"])==10
assert len(gltf["skins"][0]["joints"])==9
allnodes=gltf["nodes"]
tracks={(allnodes[ch["target"]["node"]]["name"],ch["target"]["path"])
        for ch in clip["channels"]}
assert ("Root","translation") in tracks
assert ("Root","rotation") in tracks
assert all((name,"rotation") in tracks for name in names if name!="Root")
assert len(gltf["meshes"])==1
assert len(gltf.get("textures",[]))==1
for samp in clip["samplers"]:
    clock=gltf["accessors"][samp["input"]]
    assert clock["count"]==13,(clock["count"],clock)
    assert abs(clock["min"][0])<1e-3
    assert abs(clock["max"][0]-5.85)<1e-3

print("PASSOU: .bbmodel editavel, 23 malhas, 9 juntas, 130 quadros-chave")
print("PASSOU: glTF 2.0, 9 juntas esqueléticas, 1 clip de 5.85s")
print("PASSOU: translacao Root e rotacoes de tronco, membros, cabeca e joelhos")
print("PASSOU: textura incorporada; cama excluida da malha exportada")
