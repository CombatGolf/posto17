#!/usr/bin/env python3
"""Integrate Z.ai corrections as permanent R6 keyframe fixes; source in GitHub Correcoes/.
Also replaces the deprecated crouch-walk clip with its existing corrected counterpart.
Does NOT execute any Lua or alter the 73-item showcase index.
"""
from pathlib import Path
from collections import Counter
from copy import deepcopy
import xml.etree.ElementTree as ET
import math, re, shutil

P=Path.home()/'Projetos/Posto17-v2'
G=Path.home()/'Projetos/posto17-github-sync'
ASSET=P/'src/assets/Posto17R6Corpo.rbxmx'
FIX=G/'Correcoes/CorrigeCrouchIdle.client.lua'
BACK=P/'backups/ZAI_R6_v126'
BACK.mkdir(exist_ok=True,parents=True)
assert FIX.is_file() and ASSET.is_file()
shutil.copy2(ASSET,BACK/ASSET.name)
# Parse only literal numeric table lines (never run Z.ai Lua).
text=FIX.read_text()
lines=text.splitlines()
frames=[]
for ln in lines:
    m=re.match(r'^\s*\{([\d.]+),\{T=\{(.+)\}\}\},?\s*$',ln)
    if not m:continue
    tim=float(m.group(1))
    matches=re.findall(r'([A-Z]{1,2})=\{([^}]*)\}', 'T={'+m.group(2)+'}')
    pose={}
    for key,raw in matches:
        nums=[float(x.strip()) for x in raw.split(',')]
        assert len(nums)==12,(key,tim,len(nums))
        assert all(math.isfinite(x) for x in nums),(key,tim)
        pose[key]=nums
    assert set(pose)=={'T','H','LA','RA','LL','RL'},(tim,set(pose))
    frames.append((tim,pose))
assert len(frames)==15,('Parsed Z.ai keyframes',len(frames))
assert frames[0][0]==0 and abs(frames[-1][0]-1.367)<.001
assert all(frames[i][0]<frames[i+1][0] for i in range(14))
tree=ET.parse(ASSET);root=tree.getroot()
names={}
for obj in root.iter('Item'):
    if obj.get('class')!='KeyframeSequence':continue
    name=obj.findtext('./Properties/string[@name="Name"]')
    assert name not in names,name
    names[name]=obj
assert all(n in names for n in ['P17_Corpo_013','P17_Corpo_018','P17_Corpo_035','P17_Corpo_024','P17_Corpo_015'])
cf_keys='X Y Z R00 R01 R02 R10 R11 R12 R20 R21 R22'.split()
def cframe(values):
    item=ET.Element('CoordinateFrame',{'name':'CFrame'})
    for k,v in zip(cf_keys,values):
        el=ET.SubElement(item,k)
        el.text=format(v,'.9g')
    return item
def pose_node(typ,name,mat=None,weight=1,tag=''):
    el=ET.Element('Item',{'class':'Pose','referent':f'P17_ZAI126_{tag}_{name.replace(" ","")}'} )
    pr=ET.SubElement(el,'Properties')
    ET.SubElement(pr,'string',{'name':'Name'}).text=name
    ET.SubElement(pr,'float',{'name':'Weight'}).text=str(weight)
    ET.SubElement(pr,'token',{'name':'EasingStyle'}).text='0'
    ET.SubElement(pr,'token',{'name':'EasingDirection'}).text='0'
    pr.append(cframe(mat if mat is not None else [0,0,0,1,0,0,0,1,0,0,0,1]))
    return el
def make_frame(t,poses,clip,i):
    frame=ET.Element('Item',{'class':'Keyframe','referent':f'P17_ZAI126_{clip}_K{i}'})
    props=ET.SubElement(frame,'Properties')
    ET.SubElement(props,'string',{'name':'Name'}).text='Keyframe'
    ET.SubElement(props,'float',{'name':'Time'}).text=format(t,'.9g')
    rootpose=pose_node('Pose','HumanoidRootPart',weight=0,tag=f'{clip}_{i}')
    torso=pose_node('Pose','Torso',poses['T'],tag=f'{clip}_{i}')
    for key,name in [('H','Head'),('LA','Left Arm'),('RA','Right Arm'),('LL','Left Leg'),('RL','Right Leg')]:
        torso.append(pose_node('Pose',name,poses[key],tag=f'{clip}_{i}'))
    rootpose.append(torso)
    frame.append(rootpose)
    return frame
def replace_frames(name,replacements):
    seq=names[name]
    old=seq.findall('./Item[@class="Keyframe"]')
    for item in old:seq.remove(item)
    for idx,(t,pose) in enumerate(replacements):
        seq.append(make_frame(t,pose,name,idx))
    assert len(seq.findall('./Item[@class="Keyframe"]'))==len(replacements)
    return len(old)
for n in ('P17_Corpo_013','P17_Corpo_018','P17_Corpo_035'):
    old=replace_frames(n,frames)
    assert old==15,(n,old)
# CrouchWalk_024 older corrupted version: use user's approved CrouchWalk_Corrigido,
# already in the game as P17_Corpo_015. Keep source id/name/priority/loop.
cw=names['P17_Corpo_015'].findall('./Item[@class="Keyframe"]')
assert len(cw)==76
target=names['P17_Corpo_024']
old=len(target.findall('./Item[@class="Keyframe"]'))
assert old==76
for x in target.findall('./Item[@class="Keyframe"]'):target.remove(x)
for idx,item in enumerate(cw):
    clone=deepcopy(item)
    for j,node in enumerate(clone.iter('Item')):node.set('referent',f'P17_ZAI126_WALK24_{idx}_{j}')
    target.append(clone)
# Prevent duplicate referent IDs in serialized Roblox XML.
all_refs=[x.attrib['referent'] for x in root.iter('Item') if 'referent' in x.attrib]
assert len(all_refs)==len(set(all_refs)), 'Duplicate XML referents'
# Ensure all R6 clips remain present.
assert len(names)==47
ASSET.write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True))
parsed=ET.parse(ASSET).getroot()
assert len([x for x in parsed.iter('Item') if x.get('class')=='KeyframeSequence'])==47
for n in ('P17_Corpo_013','P17_Corpo_018','P17_Corpo_035'):
    seq=next(x for x in parsed.iter('Item') if x.get('class')=='KeyframeSequence' and x.findtext('./Properties/string[@name="Name"]')==n)
    keys=seq.findall('./Item[@class="Keyframe"]')
    assert len(keys)==15
    assert abs(float(keys[-1].findtext('./Properties/float[@name="Time"]'))-1.367)<.001
    for key in keys:
        poseNames=[x.findtext('./Properties/string[@name="Name"]') for x in key.iter('Item') if x.get('class')=='Pose']
        assert len(poseNames)==7 and len(set(poseNames))==7,(n,poseNames)
assert len(names['P17_Corpo_024'].findall('./Item[@class="Keyframe"]'))==76
print('FIXED 4 clips: 013,018,035 using Z.ai 15-frame CrouchIdle; 024 copied user-approved CrouchWalk_Corrigido')
print('SOURCE:',FIX)
print('OUTPUT:',ASSET,ASSET.stat().st_size,'bytes; BACKUP:',BACK)
