from pathlib import Path
import shutil
R=Path.home()/'Projetos/Posto17-v2'
B=R/'backups/P17_Lab_20261123'
def replace(name,items):
    path=R/name
    if not (B/path.name).exists():shutil.copy2(path,B/path.name)
    s=path.read_text()
    for a,b in items:
        if s.count(a)!=1:raise ValueError((name,s.count(a),a[:80]))
        s=s.replace(a,b,1)
    path.write_text(s)
    print('PATCHED',name,len(s))
replace('src/client/R6Frames.luau',[
('''local samples = shared:WaitForChild("Posto17R6Amostras",12)''',
'''local samples = shared:WaitForChild("Posto17R6Amostras",12)
local interactions = shared:WaitForChild("Posto17R6Interacoes",12)'''),
('''key:match("^P17_Corpo_%d+$") or key:match("^P17_W_[%w_]+$")) and key)''',
'''key:match("^P17_Corpo_%d+$") or key:match("^P17_W_[%w_]+$")
        or key:match("^P17_I_[%w_]+$")) and key)'''),
('''    local sequence=id and (library:FindFirstChild(id)
        or (samples and samples:FindFirstChild(id)))''',
'''    local sequence=id and (library:FindFirstChild(id)
        or (samples and samples:FindFirstChild(id))
        or (interactions and interactions:FindFirstChild(id)))''')
])
replace('src/client/AnimacaoIndividual.client.luau',[
('''-- Inclui 47 sequencias corporais e 26 sequencias com os modelos originais.''',
'''-- Inclui 47 corporais, 26 com equipamentos e 16 interacoes R6 novas.'''),
('''local weapons=shared:WaitForChild("Posto17R6Amostras")''',
'''local weapons=shared:WaitForChild("Posto17R6Amostras")
local interactions=shared:WaitForChild("Posto17R6Interacoes")'''),
('''local launch=button(gui,"AbrirBancada","ANIMACOES  73",''',
'''local launch=button(gui,"AbrirBancada","ANIMACOES  89",'''),
('''local heading=text(root,"Titulo","POSTO 17 / BANCADA R6   •   73 SEQUENCIAS",''',
'''local heading=text(root,"Titulo","POSTO 17 / BANCADA R6   •   89 SEQUENCIAS",'''),
('''    {"Sub","submetralhadora"},{"Fuzil","fuzil"}
}''',
'''    {"Sub","submetralhadora"},{"Fuzil","fuzil"},{"Interacoes","Interacao"}
}'''),
('''    local item=button(filters,"Filtro"..i,opt[1],UDim2.new((i-1)/5,2,0,1),
        UDim2.new(.2,-4,1,-2),i==1 and RED or SURFACE)''',
'''    local item=button(filters,"Filtro"..i,opt[1],UDim2.new((i-1)/6,2,0,1),
        UDim2.new(1/6,-4,1,-2),i==1 and RED or SURFACE)'''),
('''    local parent=row.category=="Movimento" and bodies or weapons''',
'''    local parent=row.category=="Movimento" and bodies
        or (row.category=="Interacao" and interactions or weapons)'''),
('''    clipInfo.Text=(row.category=="Movimento" and "CORPO R6" or string.upper(row.category))''',
'''    clipInfo.Text=(row.category=="Movimento" and "CORPO R6" or string.upper(row.category))'''), # no-op? count1 yes
('''assert(#records==73,"A lista da bancada deve conter 73 clipes")''',
'''assert(#records==89,"A lista da bancada deve conter 89 clipes")''')
])
replace('src/server/InteractionLab.luau',[
('''-- 73 estacoes contextualizadas + 16 interacoes cenicas e equipamentos visuais.''',
'''-- 73 estacoes contextualizadas + 16 interacoes cenicas e equipamentos visuais.'''),
('''    for i,row in ipairs(Catalog) do
        local col=(i-1)%9''',
'''    for i,row in ipairs(Catalog) do
        if row.category=="Interacao" then continue end
        local col=(i-1)%9'''),
('''{id="porta",text="ABRIR PORTA",cue="DOOR",clip="P17_Corpo_036"}''',
'''{id="porta",text="ABRIR PORTA",cue="DOOR",clip="P17_I_porta"}'''),
('''{id="armario",text="DESLIZAR ARMARIO",cue="LOCKER",clip="P17_Corpo_003"}''',
'''{id="armario",text="DESLIZAR ARMARIO",cue="LOCKER",clip="P17_I_armario"}'''),
('''{id="terminal",text="USAR TERMINAL",cue="TERMINAL",clip="P17_Corpo_003"}''',
'''{id="terminal",text="USAR TERMINAL",cue="TERMINAL",clip="P17_I_terminal"}'''),
('''{id="botao",text="APERTAR BOTAO",cue="BUTTON",clip="P17_Corpo_003"}''',
'''{id="botao",text="APERTAR BOTAO",cue="BUTTON",clip="P17_I_botao"}'''),
('''{id="chave",text="GIRAR CHAVE",cue="LOCK",clip="P17_Corpo_003"}''',
'''{id="chave",text="GIRAR CHAVE",cue="LOCK",clip="P17_I_chave"}'''),
('''{id="luz",text="ACIONAR LUZ",cue="BUTTON",clip="P17_Corpo_003"}''',
'''{id="luz",text="ACIONAR LUZ",cue="BUTTON",clip="P17_I_luz"}'''),
('''{id="caixa",text="MOVER CAIXA",cue="BOX",clip="P17_Corpo_011"}''',
'''{id="caixa",text="MOVER CAIXA",cue="BOX",clip="P17_I_caixa"}'''),
('''{id="mesa",text="INSPECIONAR MESA",cue="TERMINAL",clip="P17_Corpo_046"}''',
'''{id="mesa",text="INSPECIONAR MESA",cue="TERMINAL",clip="P17_I_mesa"}'''),
('''{id="duto",text="ENTRAR DUTO",cue="VENT",clip="P17_Corpo_017"}''',
'''{id="duto",text="ENTRAR DUTO",cue="VENT",clip="P17_I_duto"}'''),
('''{id="escada",text="ESCALAR",cue="CLIMB",clip="P17_Corpo_029"}''',
'''{id="escada",text="ESCALAR",cue="CLIMB",clip="P17_I_escada"}'''),
('''{id="barreira",text="TRANSPOR BARREIRA",cue="VAULT",clip="P17_Corpo_011"}''',
'''{id="barreira",text="TRANSPOR BARREIRA",cue="VAULT",clip="P17_I_barreira"}'''),
('''{id="cobertura",text="COBERTURA",cue="COVER",clip="P17_Corpo_020"}''',
'''{id="cobertura",text="COBERTURA",cue="COVER",clip="P17_I_cobertura"}'''),
('''{id="cama",text="DEITAR NA CAMA",cue="REST",clip="P17_Corpo_008"}''',
'''{id="cama",text="DEITAR NA CAMA",cue="REST",clip="P17_I_cama"}'''),
('''{id="inspecao",text="CONFERIR PROPS",cue="TERMINAL",clip="P17_Corpo_046"}''',
'''{id="inspecao",text="CONFERIR PROPS",cue="TERMINAL",clip="P17_I_inspecao"}'''),
('''{id="painel",text="RECONFIGURAR PAINEL",cue="TERMINAL",clip="P17_Corpo_003"}''',
'''{id="painel",text="RECONFIGURAR PAINEL",cue="TERMINAL",clip="P17_I_painel"}'''),
('''{id="alvo",text="TESTAR EFEITO VISUAL",cue="BUTTON",clip="P17_Corpo_053"}''',
'''{id="alvo",text="TESTAR EFEITO VISUAL",cue="BUTTON",clip="P17_I_alvo"}''')
])
print('R6_89 PATCH OK')
