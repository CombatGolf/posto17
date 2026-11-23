--=============================================================================
-- POSTO 17 | ANIMAÇÃO PROCEDURAL — PISTOLA: DISPARO E ESTABILIZAÇÃO DA MIRA
--=============================================================================
-- Arquivo    : Pistola_TiroRecuo.lua
-- Tipo       : ModuleScript (independente — não depende de nenhum outro arquivo)
-- API        : 100% nativa do Roblox (RunService, Instance.new, WeldConstraint)
-- Proibições : sem asset externo, sem AnimationId, sem plugin, sem modelo pronto
-- Duração    : 0.95 s | Loop: não (chame :Play() a cada disparo)
-- Prioridade : Action | Rig: R15
-------------------------------------------------------------------------------
-- REPICAGEM QUADRO A QUADRO — fases (referência: tiro de pistola do MGSV,
-- empunhadura de duas mãos, recuo curto e controle rígido):
--   F1 0.00-0.06 : imagem de mira estável + micro compactação pré-disparo
--   F2 0.06-0.14 : FOGO: cano estala para cima (pico do recuo em 2 quadros)
--   F3 0.14-0.22 : cotovelos e pulsos absorvem a energia do recuo
--   F4 0.22-0.48 : o cano desce e passa levemente da linha de mira
--   F5 0.48-0.95 : reassentamento fino na imagem de mira (pronto p/ o próximo)
-- Encadeamento: chame :Play() a cada tiro — a animação termina já em mira.
-- Ajuste fino por rig: use CALIBRAGEM e CORRECOES (não mexa nos quadros).
--=============================================================================

local RunService = game:GetService("RunService")

local Animacao = {}
Animacao.Nome       = "Pistola_TiroRecuo"
Animacao.Rig        = "R15"
Animacao.Duracao    = 0.95
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
-- QUADROS-CHAVE — janela do disparo (0.06-0.22 s) com quadros densos
--=============================================================================
local QUADROS = {
	{ t = 0.000, suave = "Linear", p = { -- MIRA ESTÁVEL (estado inicial)
		OmbroD    = { x = 78,  y = 14, z = -8 },
		CotoveloD = { x = 24,  y = 0,  z = 0 },
		PulsoD    = { x = -12, y = 0,  z = 0 },
		OmbroE    = { x = 72,  y = 26, z = 10 },
		CotoveloE = { x = 66,  y = 0,  z = 0 },
		PulsoE    = { x = -14, y = 0,  z = -22 },
		Cintura   = { x = 6,   y = 2,  z = 0 },
		Pescoco   = { x = 2,   y = 0,  z = 0 },
		QuadrilD  = { x = -6,  y = 4,  z = 0 },
		QuadrilE  = { x = 6,   y = -4, z = 0 },
		JoelhoD   = { x = 8,   y = 0,  z = 0 },
		JoelhoE   = { x = 8,   y = 0,  z = 0 },
	} },
	{ t = 0.060, suave = "Linear", p = { -- micro compactação pré-disparo
		OmbroD  = { x = 77 },
		PulsoD  = { x = -11 },
		Cintura = { x = 6.5 },
	} },
	{ t = 0.100, suave = "Rapida", p = { -- FOGO: cano estala para cima
		PulsoD    = { x = -34 },
		OmbroD    = { x = 71, y = 15 },
		OmbroE    = { x = 67, y = 27 },
		CotoveloD = { x = 30 },
		CotoveloE = { x = 70 },
		Cintura   = { x = 3.5, y = 2 },
		Pescoco   = { x = 0 },
		Root      = { x = -2,  y = 0, z = 0 },
	} },
	{ t = 0.140, suave = "Linear", p = { -- pico do recuo
		PulsoD  = { x = -38 },
		OmbroD  = { x = 69 },
		OmbroE  = { x = 64 },
		Cintura = { x = 3 },
		Root    = { x = -2.5 },
	} },
	{ t = 0.220, suave = "Suave", p = { -- pulso e ombros absorvem e voltam
		PulsoD    = { x = -20 },
		OmbroD    = { x = 74 },
		OmbroE    = { x = 68 },
		CotoveloD = { x = 27 },
		Cintura   = { x = 4.5 },
		Pescoco   = { x = 1 },
		Root      = { x = -1 },
	} },
	{ t = 0.340, suave = "Suave", p = { -- cano passa levemente da linha de mira
		PulsoD  = { x = -7 },
		OmbroD  = { x = 80 },
		Cintura = { x = 6.5 },
		Root    = { x = -0.5 },
	} },
	{ t = 0.480, suave = "Rapida", p = { -- volta exata à imagem de mira
		PulsoD    = { x = -12 },
		OmbroD    = { x = 78, y = 14 },
		OmbroE    = { x = 72, y = 26 },
		CotoveloD = { x = 24 },
		CotoveloE = { x = 66 },
		Cintura   = { x = 6,  y = 2 },
		Pescoco   = { x = 2 },
		Root      = { x = 0,  y = 0, z = 0 },
	} },
	{ t = 0.700, suave = "Suave", p = { -- micro balanço residual
		OmbroD  = { x = 78.6 },
		PulsoD  = { x = -12.8 },
		Cintura = { x = 6.4 },
	} },
	{ t = 0.950, suave = "Linear", p = { -- assenta em MIRA ESTÁVEL (igual a t=0)
		PulsoD  = { x = -12 },
		OmbroD  = { x = 78, y = 14 },
		Cintura = { x = 6,  y = 2 },
		Pescoco = { x = 2 },
		Root    = { x = 0,  y = 0, z = 0 },
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
			Animacao:Stop(false) -- termina mantendo a pose final (em mira)
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
