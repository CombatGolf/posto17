#!/usr/bin/env python3
"""Original R6 contextual interaction sequences: 16 short staged gestures.
Preserve all 73 original animations; add discrete 16 new previewable clips.
"""
from pathlib import Path
from copy import deepcopy
import json, xml.etree.ElementTree as ET
from scipy.spatial.transform import Rotation as Rot
import numpy as np
R=Path.home()/'Projetos/Posto17-v2'
BODY=R/'src/assets/Posto17R6Corpo.rbxmx'
OUT=R/'src/assets/Posto17R6Interacoes.rbxmx'
LIB=R/'src/shared/Posto17ShowcaseIndex.luau'
body=ET.parse(BODY).getroot()
sequences={}
for e in body.iter('Item'):
    if e.get('class')=='KeyframeSequence':
        name=e.findtext('./Properties/string[@name="Name"]')
        sequences[name]=e
def base_pose(id):
    source=sequences[id]
    original=source.find('./Item[@class="Keyframe"]')
    assert original is not None
    output={}
    for node in original.iter('Item'):
        if node.get('class')!='Pose':continue
        name=node.findtext('./Properties/string[@name="Name"]')
        cf=node.find('./Properties/CoordinateFrame[@name="CFrame"]')
        assert cf is not None,(id,name)
        fields='X Y Z R00 R01 R02 R10 R11 R12 R20 R21 R22'.split()
        nums=[float(cf.findtext(key) or '0') for key in fields]
        output[name]=nums
    assert len(output)==7
    return original,output
# identifier, display name, source, [torso bend,yaw/roll, right reach, left reach, legs]
# Deltas are only stylized R6 gestures, not real-world weapon operations.
entries=[
('porta','Abrir porta','P17_Corpo_003', (8,-8,0,-70,0,0,0)),
('armario','Deslizar armario','P17_Corpo_003',(5,17,0,-35,-24,0,0)),
('terminal','Operar terminal','P17_Corpo_003',(8,0,0,-45,-43,0,0)),
('botao','Pressionar botao','P17_Corpo_003',(3,0,-2,-66,0,0,0)),
('chave','Girar chave','P17_Corpo_003',(4,17,0,-38,0,0,0)),
('luz','Acionar luz','P17_Corpo_003',(-7,0,0,-116,0,0,0)),
('caixa','Mover caixa','P17_Corpo_003',(32,0,0,-35,-35,-12,-12)),
('mesa','Inspecionar mesa','P17_Corpo_003',(23,10,0,-25,-5,0,0)),
('duto','Entrar no duto','P17_Corpo_017',(0,0,0,-8,16,8,-8)),
('escada','Escalar plataforma','P17_Corpo_029',(4,0,0,-25,-13,16,-22)),
('barreira','Transpor barreira','P17_Corpo_011',(4,0,0,-14,-19,22,-16)),
('cobertura','Entrar na cobertura','P17_Corpo_020',(0,0,15,-16,-7,-3,5)),
('cama','Deitar na cama','P17_Corpo_008',(0,0,0,9,2,4,-3)),
('inspecao','Inspecionar objeto','P17_Corpo_003',(0,8,0,-46,-25,0,0)),
('painel','Reconfigurar painel','P17_Corpo_003',(0,-10,0,-61,-58,0,0)),
('alvo','Sinalizar painel','P17_Corpo_003',(0,0,0,-49,0,0,0))
]
assert len(entries)==16 and len(set(x[0] for x in entries))==16
times=(0,.12,.29,.46,.64,.79,.94)
weight=(0,.2,.74,1,.88,.33,0)

root=ET.Element('roblox',{'version':'4',
    'xmlns:xsi':'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:noNamespaceSchemaLocation':'http://www.roblox.com/roblox.xsd'})
folder=ET.SubElement(root,'Item',{'class':'Folder','referent':'P17_INTERACOES_FOLDER'})
pr=ET.SubElement(folder,'Properties')
ET.SubElement(pr,'string',{'name':'Name'}).text='Posto17R6Interacoes'
fields='X Y Z R00 R01 R02 R10 R11 R12 R20 R21 R22'.split()
def set_cf(el,raw,angles,offset=(0,0,0)):
    cf=el.find('./Properties/CoordinateFrame[@name="CFrame"]')
    assert cf is not None
    pos=np.array(raw[:3])+np.array(offset)
    matrix=np.array(raw[3:]).reshape((3,3))
    target=matrix@Rot.from_euler('xyz',angles,degrees=True).as_matrix()
    vals=[*pos,*target.ravel()]
    for field,value in zip(fields,vals):
        cf.find(field).text=format(value,'.9g')
def pose_map(frame):
    return {x.findtext('./Properties/string[@name="Name"]'):x
        for x in frame.iter('Item') if x.get('class')=='Pose'}
for clipIndex,(id,name,source,spec) in enumerate(entries,1):
    base_frame,base=base_pose(source)
    sequence=deepcopy(sequences[source])
    for old in list(sequence.findall('./Item[@class="Keyframe"]')):
        sequence.remove(old)
    nm=sequence.find('./Properties/string[@name="Name"]')
    assert nm is not None
    nm.text='P17_I_'+id
    loop=sequence.find('./Properties/bool[@name="Loop"]')
    if loop is not None:loop.text='false'
    for k,(t,alpha) in enumerate(zip(times,weight)):
        frame=deepcopy(base_frame)
        frame.find('./Properties/float[@name="Time"]').text=format(t,'.6g')
        poses=pose_map(frame)
        torsoBend,yaw,roll,ra,la,rl,ll=spec
        rot={
            'Torso':(torsoBend*alpha,yaw*alpha,roll*alpha),
            'Head':(-torsoBend*.35*alpha,-yaw*.4*alpha,0),
            'Right Arm':(ra*alpha,0,-8*alpha),
            'Left Arm':(la*alpha,0,8*alpha),
            'Right Leg':(rl*alpha,0,0),
            'Left Leg':(ll*alpha,0,0),
        }
        for part,angles in rot.items():
            offset=(0,-.07*alpha,-.09*alpha) if part=='Torso' else (0,0,0)
            set_cf(poses[part],base[part],angles,offset)
        sequence.append(frame)
    for n,obj in enumerate(sequence.iter('Item')):
        obj.set('referent',f'P17_INTERACOES_{clipIndex}_{n}')
    folder.append(sequence)
ET.indent(root,space='  ')
OUT.write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True))
assert len(ET.parse(OUT).getroot().findall('.//Item[@class="KeyframeSequence"]'))==16

s=LIB.read_text()
assert s.count('category="Interacao"') in (0,16)
if 'category="Interacao"' not in s:
    assert s.strip().endswith('}')
    pos=s.rfind('}')
    rows=['    {id="P17_I_'+id+'", name="'+name+'", category="Interacao", model=""},'
          for id,name,*_ in entries]
    s=s[:pos]+'\n'.join(rows)+'\n'+s[pos:]
    s=s.replace('-- Lista de todas as animacoes disponiveis na bancada R6 (47 + 26)',
                '-- Bancada R6: 47 corporais + 26 equipamentos + 16 interacoes (89)')
    LIB.write_text(s)
assert LIB.read_text().count('category="Interacao"')==16
print('CREATED: 16 original interaction keyframe sequences, 7 frames each')
print('ASSET:',OUT,OUT.stat().st_size,'bytes')
print('SHOWCASE INDEX:',sum(line.lstrip().startswith('{id=') for line in LIB.read_text().splitlines()),'entries')
