--=============================================================================
-- POSTO 17 | ANIMAÇÃO PROCEDURAL — PISTOLA: ESCALADA COM 2 MÃOS (MANTLE)
--=============================================================================
-- Arquivo    : Pistola_EscaladaDuasMaos.lua
-- Tipo       : ModuleScript (independente — não depende de nenhum outro arquivo)
-- API        : 100% nativa do Roblox (RunService, Instance.new, WeldConstraint)
-- Proibições : sem asset externo, sem AnimationId, sem plugin, sem modelo pronto
-- Duração    : 1.85 s | Loop: não | Prioridade: Action | Rig: R15
-------------------------------------------------------------------------------
-- REPICAGEM QUADRO A QUADRO — fases (referência: mantle do MGSV — as duas
-- mãos agarram a borda, a pistola fica presa na mão direita apoiada na borda):
--   F1 0.00-0.18 : chegada ao muro e agachamento para reunir força
--   F2 0.18-0.38 : salto — as duas mãos esticam para a borda
--   F3 0.38-0.56 : impacto da pegada — cotovelos absorvem
--   F4 0.56-0.82 : puxada funda — olhos vencem a borda primeiro
--   F5 0.82-1.08 : pressão final — peito vence a borda
--   F6 1.08-1.34 : joelhos sobem a borda (passagem de perna)
--   F7 1.34-1.85 : em pé sobre a borda -> solta e volta à guarda de mira
-- Ajuste fino por rig: use CALIBRAGEM e CORRECOES (não mexa nos quadros).
--=============================================================================

local RunService = game:GetService("RunService")

local Animacao = {}
Animacao.Nome       = "Pistola_EscaladaDuasMaos"
Animacao.Rig        = "R15"
Animacao.Duracao    = 1.85
Animacao.EmLoop     = false
Animacao.Prioridade = "Action"

local CALIBRAGEM = { X = 1, Y = 1, Z = 1 }
local CORRECOES = {}

local JUNTAS = {
	Root       = "Root",
	Cintura    = "Waist",
	Pescoco    = "Neck",
	OmbroD     = "RightShoulder",
	OmbroE     = "LeftShoulder",
	CotoveloD  = "RightElbow",
	CotoveloE  = "LeftElbow",
	PulsoD     = "RightWrist",
	PulsoE     = "LeftWrist",
	QuadrilD   = "RightHip",
	QuadrilE   = "LeftHip",
	JoelhoD    = "RightKnee",
	JoelhoE    = "LeftKnee",
	TornozeloD = "RightAnkle",
	TornozeloE = "LeftAnkle",
}

local CURVA = {
	Linear = function(a) return a end,
	Suave  = function(a) return a * a * (3 - 2 * a) end,
	Lenta  = function(a) return a * a end,
	Rapida = function(a) return 1 - (1 - a) * (1 - a) end,
}

--=============================================================================
-- QUADROS-CHAVE (ângulos em GRAUS)
--=============================================================================
local QUADROS = {
	{ t = 0.000, suave = "Suave", p = { -- chegada ao muro em guarda baixa
		Cintura   = { x = 10, y = 0,  z = 0 },
		Pescoco   = { x = -10, y = 0, z = 0 },
		OmbroD    = { x = 30, y = 6,  z = -6 },
		CotoveloD = { x = 50, y = 0,  z = 0 },
		OmbroE    = { x = 30, y = -6, z = 6 },
		CotoveloE = { x = 50, y = 0,  z = 0 },
		QuadrilD  = { x = -8, y = 4,  z = 0 },
		QuadrilE  = { x = 8,  y = -4, z = 0 },
		JoelhoD   = { x = 12, y = 0,  z = 0 },
		JoelhoE   = { x = 12, y = 0,  z = 0 },
	} },
	{ t = 0.180, suave = "Suave", p = { -- agacha para reunir força
		Cintura    = { x = 22 },
		QuadrilD   = { x = 30 },
		QuadrilE   = { x = 30 },
		JoelhoD    = { x = 62 },
		JoelhoE    = { x = 62 },
		TornozeloD = { x = -24 },
		TornozeloE = { x = -24 },
		OmbroD     = { x = 62, y = 6 },
		OmbroE     = { x = 62, y = -6 },
		CotoveloD  = { x = 40 },
		CotoveloE  = { x = 40 },
	} },
	{ t = 0.380, suave = "Rapida", p = { -- salto: duas mãos esticam para a borda
		OmbroD    = { x = 148, y = -8, z = -6 },
		OmbroE    = { x = 148, y = 8,  z = 6 },
		CotoveloD = { x = 16,  y = 0,  z = 0 },
		CotoveloE = { x = 16,  y = 0,  z = 0 },
		PulsoD    = { x = 20,  y = 0,  z = 0 },
		PulsoE    = { x = 20,  y = 0,  z = 0 },
		Cintura   = { x = -8,  y = 0,  z = 0 },
		Pescoco   = { x = -18, y = 0,  z = 0 },
		QuadrilD  = { x = -18, y = 0,  z = 0 },
		QuadrilE  = { x = -18, y = 0,  z = 0 },
		JoelhoD   = { x = 8,   y = 0,  z = 0 },
		JoelhoE   = { x = 8,   y = 0,  z = 0 },
	} },
	{ t = 0.560, suave = "Rapida", p = { -- impacto da pegada: cotovelos absorvem
		OmbroD    = { x = 138, y = -8 },
		OmbroE    = { x = 138, y = 8 },
		CotoveloD = { x = 48 },
		CotoveloE = { x = 48 },
		Cintura   = { x = 6 },
		Pescoco   = { x = -22 },
		QuadrilD  = { x = 4 },
		QuadrilE  = { x = 4 },
		JoelhoD   = { x = 26 },
		JoelhoE   = { x = 26 },
	} },
	{ t = 0.820, suave = "Lenta", p = { -- puxada: cotovelos dobram fundo
		OmbroD    = { x = 118, y = -6 },
		OmbroE    = { x = 118, y = 6 },
		CotoveloD = { x = 94 },
		CotoveloE = { x = 94 },
		Cintura   = { x = 18 },
		Pescoco   = { x = -30 },
		QuadrilD  = { x = 22 },
		QuadrilE  = { x = 22 },
		JoelhoD   = { x = 48 },
		JoelhoE   = { x = 48 },
	} },
	{ t = 1.080, suave = "Rapida", p = { -- peito vence a borda
		OmbroD    = { x = 96, y = -4 },
		OmbroE    = { x = 96, y = 4 },
		CotoveloD = { x = 30 },
		CotoveloE = { x = 30 },
		Cintura   = { x = 28 },
		Pescoco   = { x = -24 },
		QuadrilD  = { x = 46 },
		QuadrilE  = { x = 46 },
		JoelhoD   = { x = 72 },
		JoelhoE   = { x = 72 },
	} },
	{ t = 1.340, suave = "Rapida", p = { -- joelhos sobem a borda (perna passa)
		QuadrilD   = { x = 96, y = 0 },
		QuadrilE   = { x = 96, y = 0 },
		JoelhoD    = { x = 112, y = 0 },
		JoelhoE    = { x = 112, y = 0 },
		Cintura    = { x = 32 },
		Pescoco    = { x = -16 },
		OmbroD     = { x = 80, y = -4 },
		OmbroE     = { x = 80, y = 4 },
		CotoveloD  = { x = 24 },
		CotoveloE  = { x = 24 },
		TornozeloD = { x = 14 },
		TornozeloE = { x = 14 },
	} },
	{ t = 1.600, suave = "Suave", p = { -- em pé sobre a borda: corpo sobe
		QuadrilD  = { x = 8,  y = 4 },
		QuadrilE  = { x = 8,  y = -4 },
		JoelhoD   = { x = 24 },
		JoelhoE   = { x = 24 },
		Cintura   = { x = 12 },
		Pescoco   = { x = -8 },
		OmbroD    = { x = 36, y = 6,  z = -6 },
		OmbroE    = { x = 36, y = -6, z = 6 },
		CotoveloD = { x = 34 },
		CotoveloE = { x = 34 },
	} },
	{ t = 1.850, suave = "Linear", p = { -- solta a borda e volta à guarda de mira
		OmbroD    = { x = 78,  y = 14, z = -8 },
		CotoveloD = { x = 24,  y = 0,  z = 0 },
		PulsoD    = { x = -12, y = 0,  z = 0 },
		OmbroE    = { x = 72,  y = 26, z = 10 },
		CotoveloE = { x = 66,  y = 0,  z = 0 },
		PulsoE    = { x = -14, y = 0,  z = -22 },
		Cintura   = { x = 6,   y = 2,   z = 0 },
		Pescoco   = { x = 2,   y = 0,   z = 0 },
		QuadrilD  = { x = -6,  y = 4,   z = 0 },
		QuadrilE  = { x = 6,   y = -4,  z = 0 },
		JoelhoD   = { x = 8,   y = 0,   z = 0 },
		JoelhoE   = { x = 8,   y = 0,   z = 0 },
	} },
}

--=============================================================================
-- MOTOR DE REPRODUÇÃO (nativo: interpola Motor6D.Transform entre quadros)
--=============================================================================
local motores, rigAtual = {}, nil
local tempoAtual, conexao, tocando, marcas = 0, nil, false, {}

do
	local anterior = {}
	for _, quadro in ipairs(QUADROS) do
		for nome in pairs(JUNTAS) do
			local ang = quadro.p[nome]
			if ang == nil then
				local ant = anterior[nome] or { x = 0, y = 0, z = 0 }
				ang = { x = ant.x, y = ant.y, z = ant.z }
				quadro.p[nome] = ang
			end
			anterior[nome] = ang
		end
	end
end

local VETOR = {}
for i, quadro in ipairs(QUADROS) do
	VETOR[i] = {}
	for nome, ang in pairs(quadro.p) do
		local corr = CORRECOES[nome] or {}
		VETOR[i][nome] = Vector3.new(
			math.rad(ang.x) * CALIBRAGEM.X * (corr.X or 1),
			math.rad(ang.y) * CALIBRAGEM.Y * (corr.Y or 1),
			math.rad(ang.z) * CALIBRAGEM.Z * (corr.Z or 1)
		)
	end
end

local function aplicarPose(tempo)
	local iA = #QUADROS - 1
	if tempo < QUADROS[#QUADROS].t then
		for i = 1, #QUADROS - 1 do
			if tempo >= QUADROS[i].t and tempo < QUADROS[i + 1].t then
				iA = i
				break
			end
		end
	end
	local iB = iA + 1
	local quadroA, quadroB = QUADROS[iA], QUADROS[iB]
	local trecho = quadroB.t - quadroA.t
	local alfa = (trecho > 0) and math.clamp((tempo - quadroA.t) / trecho, 0, 1) or 1
	alfa = (CURVA[quadroA.suave] or CURVA.Linear)(alfa)
	for nome, motor in pairs(motores) do
		local a = VETOR[iA][nome]
		local b = VETOR[iB][nome] or a
		motor.Transform = CFrame.Angles(
			a.X + (b.X - a.X) * alfa,
			a.Y + (b.Y - a.Y) * alfa,
			a.Z + (b.Z - a.Z) * alfa
		)
	end
end

local function passo(delta)
	if not tocando then return end
	local antes = tempoAtual
	tempoAtual = tempoAtual + delta
	for segundo, acao in pairs(marcas) do
		if antes < segundo and tempoAtual >= segundo then
			pcall(acao)
		end
	end
	if tempoAtual >= Animacao.Duracao then
		if Animacao.EmLoop then
			tempoAtual = tempoAtual % Animacao.Duracao
		else
			tempoAtual = Animacao.Duracao
			aplicarPose(tempoAtual)
			Animacao:Stop(false) -- termina mantendo a pose final
			return
		end
	end
	aplicarPose(tempoAtual)
end

--=============================================================================
-- API PÚBLICA
--=============================================================================

function Animacao:Preparar(rig)
	assert(rig and rig:IsA("Model"), "Informe o Model do personagem (rig R15)")
	motores = {}
	for nomeLogico, nomeMotor in pairs(JUNTAS) do
		local motor = rig:FindFirstChild(nomeMotor, true)
		if motor and motor:IsA("Motor6D") then
			motores[nomeLogico] = motor
		end
	end
	assert(next(motores) ~= nil, "Nenhum Motor6D encontrado — o rig precisa ser R15")
	rigAtual = rig
	return self
end

function Animacao:SilenciarAnimationsDoSistema()
	if not rigAtual then return self end
	local humanoide = rigAtual:FindFirstChildOfClass("Humanoid")
	local animador = humanoide and humanoide:FindFirstChildOfClass("Animator")
	if animador then
		for _, trilha in ipairs(animador:GetPlayingAnimationTracks()) do
			trilha:Stop(0)
		end
	end
	local animate = rigAtual:FindFirstChild("Animate")
	if animate then
		animate.Disabled = true
	end
	return self
end

function Animacao:Marcar(segundo, acao)
	marcas[segundo] = acao
	return self
end

function Animacao:FixarArma(modeloArma, nomeParte)
	if not (rigAtual and modeloArma and modeloArma:IsA("Model")) then return self end
	local mao = rigAtual:FindFirstChild("RightHand", true)
	local parte = (nomeParte and modeloArma:FindFirstChild(nomeParte, true))
		or modeloArma.PrimaryPart
		or modeloArma:FindFirstChildWhichIsA("BasePart", true)
	if mao and parte then
		modeloArma.PrimaryPart = parte
		parte.CFrame = mao.CFrame * CFrame.new(0, -0.4, -0.35) * CFrame.Angles(0, 0, math.rad(90))
		local solda = Instance.new("WeldConstraint")
		solda.Name = "Solda_Arma_MaoDireita"
		solda.Part0 = parte
		solda.Part1 = mao
		solda.Parent = parte
	end
	return self
end

function Animacao:Play(reiniciar)
	assert(rigAtual, "Chame Animacao:Preparar(rig) antes de Play()")
	if reiniciar ~= false then
		tempoAtual = 0
	end
	tocando = true
	if conexao then
		conexao:Disconnect()
	end
	conexao = RunService.Heartbeat:Connect(passo)
	aplicarPose(tempoAtual)
	return self
end

function Animacao:Stop(restaurar)
	tocando = false
	if conexao then
		conexao:Disconnect()
		conexao = nil
	end
	if restaurar ~= false then
		for _, motor in pairs(motores) do
			motor.Transform = CFrame.new()
		end
	end
	return self
end

return Animacao
