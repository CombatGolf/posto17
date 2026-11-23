from pathlib import Path
import shutil
R=Path.home()/'Projetos/Posto17-v2'
B=R/'backups/P17_Lab_20261123'
def patch(path,changes):
    p=R/path
    if not (B/p.name).exists():shutil.copy2(p,B/p.name)
    s=p.read_text()
    for old,new in changes:
        assert s.count(old)==1,(path,s.count(old),old[:90])
        s=s.replace(old,new,1)
    p.write_text(s)
    print('UPDATED',path)

patch('src/server/InteractionLab.luau',[
('''                        CFrame.new(0,-1.04,-.24)*CFrame.Angles(math.rad(-90),twist,0),
                        "P17SeguroNaMao")''',
'''                        -- Modelo longitudinal deve acompanhar a frente do R6
                        -- (o -90 em X anterior apontava tudo para o chao).
                        CFrame.new(0,-.99,-.38)*CFrame.Angles(0,twist,0),
                        "P17SeguroNaMao")'''),
('''            pulse(st.prop,MID,kind=="fuzil" and GOLD or BLUE)
            local flash=part''',
'''            pulse(st.prop,MID,kind=="fuzil" and GOLD or BLUE)
            -- Ensaiar uma animacao visual sem projeteis nem dano.
            local fxClip=kind=="pistola" and "P17_W_Pistola_Atirar"
                or kind=="submetralhadora" and "P17_W_Sub_Atirar"
                or "P17_W_Fuzil_Recuo"
            playClip(player,fxClip,.95)
            local flash=part''')])

patch('src/client/R6Frames.luau',[
('''    local stance = stanceFor(player)
    if not grounded then''',
'''    local stance = stanceFor(player)
    -- Enquanto um modelo novo estiver equipado no QA, usar os clipes R6
    -- de postura e caminhada correspondentes. Fora do QA: comportamento
    -- tradicional, sem alterar a missao.
    local equipped=player:GetAttribute("P17LabEquipado")
    if player:GetAttribute("Posto17InTestRange")==true and grounded
        and stance=="STAND" and equipped~=nil then
        local looks={
            pistola={"P17_W_Pistola_Pronto","P17_W_Pistola_Mira_Andando"},
            submetralhadora={"P17_W_Sub_Mirar_Parado","P17_W_Sub_Mira_Andando"},
            fuzil={"P17_W_Fuzil_Mirar","P17_W_Fuzil_Mira_Andando"},
        }
        local pair=looks[equipped]
        if pair then
            return speed>.55 and pair[2] or pair[1], stance, grounded, speed
        end
    end
    if not grounded then'''),
('''    local clip=readClip(selected)
    if not clip then return false end''',
'''    local clip=readClip(selected)
    if not clip then return false end
    -- Clipes de caminhada R6 em loop enquanto em movimento no laboratorio.
    if selected=="P17_W_Pistola_Mira_Andando"
       or selected=="P17_W_Sub_Mira_Andando"
       or selected=="P17_W_Fuzil_Mira_Andando" then
        clip.loop=true
    end''')
])
print('VISUAL HELD EQUIPMENT: +Z/-Z IN CORRECT R6 DIRECTION')
