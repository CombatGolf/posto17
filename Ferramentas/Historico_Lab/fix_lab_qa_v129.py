from pathlib import Path
import shutil
R=Path.home()/'Projetos/Posto17-v2'
BACK=R/'backups/P17_Lab_20261123'
def patch(file,arr):
    p=R/file
    if not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
    text=p.read_text()
    for a,b in arr:
        assert text.count(a)==1,(file,text.count(a),a[:80])
        text=text.replace(a,b,1)
    p.write_text(text)
    print('FIXED',file)
patch('src/client/P17Interacoes.client.luau',[
('''local launch=button(ui,"AbrirInteracoes","INTERACOES  16",
    UDim2.new(1,-407,0,105),UDim2.fromOffset(181,43),RED,12)
local equipment=button(ui,"AbrirItens","EQUIPAMENTOS",
    UDim2.new(1,-407,0,153),UDim2.fromOffset(181,35),TEAL,11)''',
'''-- Compacto e alinhado abaixo do botao ANIMACOES 89.
local launch=button(ui,"AbrirInteracoes","INTERACOES  16",
    UDim2.new(1,-201,0,154),UDim2.fromOffset(172,35),RED,11)'''),
('''    CellSize=UDim2.new(.5,-8,0,48),
    CellPadding=UDim2.fromOffset(8,7),''',
'''    CellSize=UDim2.new(1/3,-8,0,32),
    CellPadding=UDim2.fromOffset(7,5),'''),
('''    local b=button(scroll,"Interacao_"..row[1],row[2],
        UDim2.fromOffset(0,0),UDim2.fromOffset(100,48),i%2==0 and SURFACE or TEAL,12)''',
'''    local b=button(scroll,"Interacao_"..row[1],row[2],
        UDim2.fromOffset(0,0),UDim2.fromOffset(100,32),i%2==0 and SURFACE or TEAL,11)'''),
('''        panel.Visible=false
        event:FireServer("goto",row[1])''',
'''        panel.Visible=false
        launch.Visible=true
        event:FireServer("goto",row[1])'''),
('''    UDim2.new(0,15,1,-40),UDim2.new(1,-30,0,36),11)''',
'''    UDim2.new(0,15,1,-40),UDim2.new(1,-30,0,36),11)'''),
('''label(panel,"Rodape","As 73 animacoes corporais e de equipamento continuam na bancada ANIMACOES 73 e nos totens do mapa.",''',
'''label(panel,"Rodape","89 sequencias na bancada ANIMACOES 89. Os totens fisicos exibem as 73 antigas; as 16 novas ficam nesta area.",'''),
('''    equipment.Visible=available() and not panel.Visible''',
'''    -- Equipamentos ja possuem controles dentro deste painel.'''),
('''equipment.Activated:Connect(open)
close.Activated:Connect(function()panel.Visible=false;update()end)''',
'''close.Activated:Connect(function()panel.Visible=false;update()end)
local home=button(panel,"Inicio","INICIO",UDim2.new(1,-205,0,8),
    UDim2.fromOffset(91,34),TEAL,11)
home.Activated:Connect(function()
    panel.Visible=false
    update()
    event:FireServer("return")
end)''')
])
patch('src/server/TestRange.luau',[
('''        group=group,geometry=geometry,label=label,
    })''',
'''        group=group,geometry=geometry,label=label,spawn=spawn,
    })''')
])
patch('src/server/InteractionLab.luau',[
('''        elseif verb=="effect" then
            local kind=inventory[player]''',
'''        elseif verb=="return" and ctx.spawn then
            local char,hum,root=positionOK(player)
            if not root then return end
            root.CFrame=ctx.spawn.CFrame*CFrame.new(0,4,0)
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        elseif verb=="effect" then
            local kind=inventory[player]''')
])
print('UI ACCESS FIX, COMPACT PANEL, HOME RETURN READY')