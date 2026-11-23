--=============================================================================
-- POSTO 17 | ANIMAÇÃO PROCEDURAL — PISTOLA: TRANSPOSIÇÃO DE OBSTÁCULO BAIXO
--=============================================================================
-- Arquivo    : Pistola_TransporObstaculos.lua
-- Tipo       : ModuleScript (independente — não depende de nenhum outro arquivo)
-- API        : 100% nativa do Roblox (RunService, Instance.new, WeldConstraint)
-- Proibições : sem asset externo, sem AnimationId, sem plugin, sem modelo pronto
-- Duração    : 1.45 s | Loop: não | Prioridade: Action | Rig: R15
-------------------------------------------------------------------------------
-- REPICAGEM QUADRO A QUADRO — fases (referência: vault tático do MGSV —
-- movimento econômico, arma presa ao peito, cabeça sempre acima do obstáculo):
--   F1 0.00-0.16 : aproximação e agachamento de carregada
--   F2 0.16-0.32 : mão esquerda planta no obstáculo (arma presa no peito)
--   F3 0.32-0.52 : impulso — perna direita lidera a passagem
--   F4 0.52-0.68 : ápice sobre o obstáculo
--   F5 0.68-1.08 : aterrissagem com absorção nos joelhos
--   F6 1.08-1.45 : reerguer, reerguer a arma e voltar à guarda de mira
-- Ajuste fino por rig: use CALIBRAGEM e CORRECOES (não mexa nos quadros).
--=============================================================================

local RunService = game:GetService("RunService")

local Animacao = {}
Animacao.Nome       = "Pistola_TransporObstaculos"
Animacao.Rig        = "R15"
Animacao.Duracao    = 1.45
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
	{ t = 0.000, suave = "Suave", p = { -- aproximação em guarda compacta
		Cintura   = { x = 8,  y = 0,  z = 0 },
		Pescoco   = { x = -8, y = 0,  z = 0 },
		OmbroD    = { x = 38, y = 8,  z = -6 },
		CotoveloD = { x = 62, y = 0,  z = 0 },
		OmbroE    = { x = 30, y = -8, z = 6 },
		CotoveloE = { x = 55, y = 0,  z = 0 },
		QuadrilD  = { x = -10, y = 4, z = 0 },
		QuadrilE  = { x = 10,  y = -4, z = 0 },
		JoelhoD   = { x = 14, y = 0, z = 0 },
		JoelhoE   = { x = 14, y = 0, z = 0 },
	} },
	{ t = 0.160, suave = "Suave", p = { -- agachamento de carregada
		Cintura    = { x = 20 },
		Pescoco    = { x = -14 },
		QuadrilD   = { x = 26 },
		QuadrilE   = { x = 26 },
		JoelhoD    = { x = 55 },
		JoelhoE    = { x = 55 },
		TornozeloD = { x = -22 },
		TornozeloE = { x = -22 },
		OmbroD     = { x = 42 },
		CotoveloD  = { x = 66 },
	} },
	{ t = 0.320, suave = "Rapida", p = { -- mão esquerda planta no obstáculo
		OmbroE    = { x = 78, y = 12, z = 6 },
		CotoveloE = { x = 22, y = 0,  z = 0 },
		PulsoE    = { x = 10, y = 0,  z = 0 },
		OmbroD    = { x = 46, y = 10, z = -10 },
		CotoveloD = { x = 78, y = 0,  z = 0 },
		PulsoD    = { x = -20, y = 0, z = 0 },
		Cintura   = { x = 26, y = -8 },
		Pescoco   = { x = -20, y = 4 },
	} },
	{ t = 0.520, suave = "Rapida", p = { -- impulso: perna direita lidera
		QuadrilD   = { x = 82, y = 0,  z = 0 },
		JoelhoD    = { x = 96, y = 0,  z = 0 },
		QuadrilE   = { x = -38 },
		JoelhoE    = { x = 16 },
		TornozeloE = { x = 12 },
		Cintura    = { x = 34, y = -6 },
		Pescoco    = { x = -26 },
		OmbroE     = { x = 88 },
		CotoveloE  = { x = 10 },
		OmbroD     = { x = 40, y = 12, z = -12 },
		CotoveloD  = { x = 84 },
	} },
	{ t = 0.680, suave = "Linear", p = { -- ápice sobre o obstáculo
		QuadrilD = { x = 58 },
		JoelhoD  = { x = 72 },
		QuadrilE = { x = -12 },
		JoelhoE  = { x = 78 },
		Cintura  = { x = 30, y = -4 },
		Pescoco  = { x = -22 },
	} },
	{ t = 0.900, suave = "Rapida", p = { -- aterrissagem: pé direito toca o chão
		QuadrilD   = { x = 30 },
		JoelhoD    = { x = 46 },
		QuadrilE   = { x = -6, y = -4 },
		JoelhoE    = { x = 42 },
		TornozeloE = { x = -8 },
		Cintura    = { x = 20, y = 0 },
		Pescoco    = { x = -12 },
		OmbroE     = { x = 46, y = -8, z = 6 },
		CotoveloE  = { x = 48 },
		OmbroD     = { x = 48, y = 10, z = -8 },
		CotoveloD  = { x = 70 },
	} },
	{ t = 1.080, suave = "Suave", p = { -- absorção com os joelhos
		QuadrilD  = { x = 18 },
		JoelhoD   = { x = 52 },
		QuadrilE  = { x = 14 },
		JoelhoE   = { x = 50 },
		Cintura   = { x = 14 },
		OmbroD    = { x = 52 },
		CotoveloD = { x = 64 },
	} },
	{ t = 1.260, suave = "Rapida", p = { -- reerguer o corpo e reerguer a arma
		Cintura   = { x = 6 },
		Pescoco   = { x = -6 },
		QuadrilD  = { x = -8, y = 4 },
		QuadrilE  = { x = 8,  y = -4 },
		JoelhoD   = { x = 10 },
		JoelhoE   = { x = 10 },
		OmbroD    = { x = 58, y = 12, z = -8 },
		CotoveloD = { x = 40 },
		OmbroE    = { x = 52, y = 20, z = 8 },
		CotoveloE = { x = 58 },
	} },
	{ t = 1.450, suave = "Linear", p = { -- volta à guarda de mira compacta
		OmbroD    = { x = 78,  y = 14, z = -8 },
		CotoveloD = { x = 24,  y = 0,  z = 0 },
		PulsoD    = { x = -12, y = 0,  z = 0 },
		OmbroE    = { x = 72,  y = 26, z = 10 },
		CotoveloE = { x = 66,  y = 0,  z = 0 },
		PulsoE    = { x = -14, y = 0,  z = -22 },
		Cintura   = { x = 6,   y = 2,   z = 0 },
		Pescoco   = { x = 2,   y = 0,   z = 0 },
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
