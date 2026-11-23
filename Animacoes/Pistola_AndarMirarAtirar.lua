--=============================================================================
-- POSTO 17 | ANIMAÇÃO PROCEDURAL — PISTOLA: ANDAR + MIRAR + ATIRAR (COMPOSTO)
--=============================================================================
-- Arquivo    : Pistola_AndarMirarAtirar.lua
-- Tipo       : ModuleScript (independente — não depende de nenhum outro arquivo)
-- API        : 100% nativa do Roblox (RunService, Instance.new, WeldConstraint)
-- Proibições : sem asset externo, sem AnimationId, sem plugin, sem modelo pronto
-- Ciclo      : 0.95 s (loop) | Impulso de tiro: 0.30 s (aditivo) | Rig: R15
-- Prioridade : cobre o corpo inteiro (substitui a locomoção do sistema)
-------------------------------------------------------------------------------
-- ESTRUTURA EM CAMADAS (referência: caminhada com pistola em mira do MGSV —
-- tronco estável, passada controlada, tiro por cima sem parar de andar):
--   CANAL_INFERIOR : pernas + Root — ciclo de passada (2 passos) em loop
--   CANAL_SUPERIOR : braços + tronco + cabeça — mira de duas mãos com
--                    balanço de respiração
--   IMPULSO_TIRO   : camada ADITIVA acionada por :Atirar() — recuo estala o
--                    cano para cima e reassenta, sem interromper a passada
-- Ajuste fino por rig: use CALIBRAGEM e CORRECOES (não mexa nos quadros).
--=============================================================================

local RunService = game:GetService("RunService")

local Animacao = {}
Animacao.Nome          = "Pistola_AndarMirarAtirar"
Animacao.Rig           = "R15"
Animacao.Ciclo         = 0.95   -- duração do ciclo de passada/mira
Animacao.DuracaoImpulso = 0.30  -- duração do recuo aditivo por tiro
Animacao.EmLoop        = true

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

local CANAL_INFERIOR = { "Root", "QuadrilD", "QuadrilE", "JoelhoD", "JoelhoE", "TornozeloD", "TornozeloE" }
local CANAL_SUPERIOR = { "Cintura", "Pescoco", "OmbroD", "OmbroE", "CotoveloD", "CotoveloE", "PulsoD", "PulsoE" }

local E_INFERIOR = {}
for _, nome in ipairs(CANAL_INFERIOR) do
	E_INFERIOR[nome] = true
end

--=============================================================================
-- CANAL INFERIOR — ciclo de passada (2 passos, contato/passage/contato)
--=============================================================================
local QUADROS_INFERIOR = {
	{ t = 0.000, suave = "Linear", p = { -- contato do pé direito à frente
		QuadrilD   = { x = 26,  y = 3, z = 0 },
		JoelhoD    = { x = 10,  y = 0, z = 0 },
		TornozeloD = { x = -12, y = 0, z = 0 },
		QuadrilE   = { x = -14, y = -3, z = 0 },
		JoelhoE    = { x = 30,  y = 0, z = 0 },
		TornozeloE = { x = 8,   y = 0, z = 0 },
		Root       = { x = 3, y = 0, z = 0, pos = { x = 0, y = -0.05, z = 0 } },
	} },
	{ t = 0.120, suave = "Linear", p = { -- peso passando ao meio
		QuadrilD = { x = 16 },
		JoelhoD  = { x = 14 },
		QuadrilE = { x = -4 },
		JoelhoE  = { x = 22 },
		Root     = { x = 2, pos = { x = 0, y = 0.02, z = 0 } },
	} },
	{ t = 0.240, suave = "Linear", p = { -- passagem: pernas quase juntas
		QuadrilD = { x = 6 },
		JoelhoD  = { x = 18 },
		QuadrilE = { x = 2 },
		JoelhoE  = { x = 12 },
		Root     = { x = 2, pos = { x = 0, y = 0.05, z = 0 } },
	} },
	{ t = 0.360, suave = "Linear", p = { -- perna esquerda abre o passo
		QuadrilD = { x = -8 },
		JoelhoD  = { x = 26 },
		TornozeloD = { x = 8 },
		QuadrilE = { x = 10 },
		JoelhoE  = { x = 14 },
		Root     = { x = 3, pos = { x = 0, y = 0.02, z = 0 } },
	} },
	{ t = 0.480, suave = "Linear", p = { -- contato do pé esquerdo à frente
		QuadrilD   = { x = -14, y = -3, z = 0 },
		JoelhoD    = { x = 30,  y = 0, z = 0 },
		TornozeloD = { x = 8,   y = 0, z = 0 },
		QuadrilE   = { x = 26,  y = 3, z = 0 },
		JoelhoE    = { x = 10,  y = 0, z = 0 },
		TornozeloE = { x = -12, y = 0, z = 0 },
		Root       = { x = 3, pos = { x = 0, y = -0.05, z = 0 } },
	} },
	{ t = 0.600, suave = "Linear", p = {
		QuadrilD = { x = -4 },
		JoelhoD  = { x = 22 },
		QuadrilE = { x = 16 },
		JoelhoE  = { x = 14 },
		Root     = { x = 2, pos = { x = 0, y = 0.02, z = 0 } },
	} },
	{ t = 0.720, suave = "Linear", p = { -- passagem
		QuadrilD = { x = 2 },
		JoelhoD  = { x = 12 },
		QuadrilE = { x = 6 },
		JoelhoE  = { x = 18 },
		Root     = { x = 2, pos = { x = 0, y = 0.05, z = 0 } },
	} },
	{ t = 0.840, suave = "Linear", p = { -- perna direita abre o passo
		QuadrilD = { x = 10 },
		JoelhoD  = { x = 14 },
		QuadrilE = { x = -8 },
		JoelhoE  = { x = 26 },
		TornozeloE = { x = 8 },
		Root     = { x = 3, pos = { x = 0, y = 0.02, z = 0 } },
	} },
	{ t = 0.950, suave = "Linear", p = { -- fecha o ciclo (igual a t=0)
		QuadrilD   = { x = 26,  y = 3, z = 0 },
		JoelhoD    = { x = 10,  y = 0, z = 0 },
		TornozeloD = { x = -12, y = 0, z = 0 },
		QuadrilE   = { x = -14, y = -3, z = 0 },
		JoelhoE    = { x = 30,  y = 0, z = 0 },
		TornozeloE = { x = 8,   y = 0, z = 0 },
		Root       = { x = 3, y = 0, z = 0, pos = { x = 0, y = -0.05, z = 0 } },
	} },
}

--=============================================================================
-- CANAL SUPERIOR — mira de duas mãos com respiração
--=============================================================================
local QUADROS_SUPERIOR = {
	{ t = 0.000, suave = "Suave", p = { -- MIRA ESTÁVEL
		Cintura   = { x = 6,   y = 2,  z = 0 },
		Pescoco   = { x = 2,   y = 0,  z = 0 },
		OmbroD    = { x = 78,  y = 14, z = -8 },
		CotoveloD = { x = 24,  y = 0,  z = 0 },
		PulsoD    = { x = -12, y = 0,  z = 0 },
		OmbroE    = { x = 72,  y = 26, z = 10 },
		CotoveloE = { x = 66,  y = 0,  z = 0 },
		PulsoE    = { x = -14, y = 0,  z = -22 },
	} },
	{ t = 0.240, suave = "Suave", p = { -- respiração sobe
		Cintura = { x = 7,   y = 3 },
		OmbroD  = { x = 79 },
		Pescoco = { x = 3 },
	} },
	{ t = 0.480, suave = "Suave", p = { -- volta ao centro
		Cintura = { x = 6,   y = 2 },
		OmbroD  = { x = 78 },
		Pescoco = { x = 2 },
	} },
	{ t = 0.720, suave = "Suave", p = { -- respiração desce
		Cintura = { x = 5.5, y = 1.5 },
		OmbroD  = { x = 77.5 },
		Pescoco = { x = 1.5 },
	} },
	{ t = 0.950, suave = "Linear", p = { -- fecha o ciclo (igual a t=0)
		Cintura = { x = 6, y = 2 },
		Pescoco = { x = 2 },
	} },
}

--=============================================================================
-- IMPULSO TIRO — camada ADITIVA (soma por cima do canal superior)
--=============================================================================
local IMPULSO_TIRO = {
	{ t = 0.000, suave = "Linear", p = {} },
	{ t = 0.040, suave = "Rapida", p = { -- FOGO: cano estala para cima
		PulsoD    = { x = -26 },
		OmbroD    = { x = -7, y = 1 },
		OmbroE    = { x = -6 },
		CotoveloD = { x = 6 },
		Cintura   = { x = -3.5 },
		Pescoco   = { x = -2.5 },
	} },
	{ t = 0.090, suave = "Linear", p = { -- pico do recuo
		PulsoD    = { x = -30 },
		OmbroD    = { x = -9 },
		OmbroE    = { x = -7 },
		CotoveloD = { x = 8 },
		Cintura   = { x = -4 },
		Pescoco   = { x = -3 },
	} },
	{ t = 0.180, suave = "Suave", p = { -- absorção e volta do cano
		PulsoD    = { x = -12 },
		OmbroD    = { x = -3 },
		OmbroE    = { x = -2.5 },
		CotoveloD = { x = 3 },
		Cintura   = { x = -1.5 },
		Pescoco   = { x = -1 },
	} },
	{ t = 0.300, suave = "Linear", p = {} }, -- fim do aditivo (tudo volta a zero)
}

--=============================================================================
-- MOTOR DE REPRODUÇÃO EM CAMADAS (nativo)
--=============================================================================
local motores, rigAtual = {}, nil
local tempoCiclo, tempoTiro, conexao, tocando = 0, nil, nil, false

-- Canal: juntas ausentes carregam o ângulo anterior
local function preencherCanal(quadros, conjunto)
	local anterior = {}
	for _, quadro in ipairs(quadros) do
		for _, nome in ipairs(conjunto) do
			local dado = quadro.p[nome]
			if dado == nil then
				local ant = anterior[nome] or { x = 0, y = 0, z = 0, pos = { x = 0, y = 0, z = 0 } }
				dado = { x = ant.x, y = ant.y, z = ant.z, pos = { x = ant.pos.x, y = ant.pos.y, z = ant.pos.z } }
				quadro.p[nome] = dado
			end
			anterior[nome] = dado
		end
	end
end

-- Impulso aditivo: juntas ausentes voltam a ZERO (não carregam)
local function preencherImpulso(quadros, conjunto)
	for _, quadro in ipairs(quadros) do
		for _, nome in ipairs(conjunto) do
			if quadro.p[nome] == nil then
				quadro.p[nome] = { x = 0, y = 0, z = 0 }
			end
		end
	end
end

local function vetorizar(quadros, conjunto)
	local lista = {}
	for i, quadro in ipairs(quadros) do
		lista[i] = {}
		for _, nome in ipairs(conjunto) do
			local d = quadro.p[nome]
			local pos = d.pos or { x = 0, y = 0, z = 0 }
			local corr = CORRECOES[nome] or {}
			lista[i][nome] = {
				rot = Vector3.new(
					math.rad(d.x) * CALIBRAGEM.X * (corr.X or 1),
					math.rad(d.y) * CALIBRAGEM.Y * (corr.Y or 1),
					math.rad(d.z) * CALIBRAGEM.Z * (corr.Z or 1)
				),
				pos = Vector3.new(pos.x, pos.y, pos.z),
			}
		end
	end
	return lista
end

preencherCanal(QUADROS_INFERIOR, CANAL_INFERIOR)
preencherCanal(QUADROS_SUPERIOR, CANAL_SUPERIOR)
preencherImpulso(IMPULSO_TIRO, CANAL_SUPERIOR)

local VETOR_INFERIOR = vetorizar(QUADROS_INFERIOR, CANAL_INFERIOR)
local VETOR_SUPERIOR = vetorizar(QUADROS_SUPERIOR, CANAL_SUPERIOR)
local VETOR_TIRO = vetorizar(IMPULSO_TIRO, CANAL_SUPERIOR)

local function lerpVetor(a, b, alfa)
	return Vector3.new(
		a.X + (b.X - a.X) * alfa,
		a.Y + (b.Y - a.Y) * alfa,
		a.Z + (b.Z - a.Z) * alfa
	)
end

-- Devolve (indiceA, indiceB, alfa suavizado) do trecho no tempo dado
local function amostrar(quadros, tempo)
	local iA = #quadros - 1
	if tempo < quadros[#quadros].t then
		for i = 1, #quadros - 1 do
			if tempo >= quadros[i].t and tempo < quadros[i + 1].t then
				iA = i
				break
			end
		end
	end
	local iB = iA + 1
	local quadroA, quadroB = quadros[iA], quadros[iB]
	local trecho = quadroB.t - quadroA.t
	local alfa = (trecho > 0) and math.clamp((tempo - quadroA.t) / trecho, 0, 1) or 1
	alfa = (CURVA[quadroA.suave] or CURVA.Linear)(alfa)
	return iA, iB, alfa
end

local function passo(delta)
	if not tocando then return end
	tempoCiclo = tempoCiclo + delta

	-- camada aditiva do tiro (sobre o canal superior)
	local aditivo = nil
	if tempoTiro then
		tempoTiro = tempoTiro + delta
		if tempoTiro >= Animacao.DuracaoImpulso then
			tempoTiro = nil
		else
			aditivo = {}
			local iTA, iTB, alfaT = amostrar(IMPULSO_TIRO, tempoTiro)
			for _, nome in ipairs(CANAL_SUPERIOR) do
				aditivo[nome] = lerpVetor(VETOR_TIRO[iTA][nome].rot, VETOR_TIRO[iTB][nome].rot, alfaT)
			end
		end
	end

	local iAi, iBi, alfaI = amostrar(QUADROS_INFERIOR, tempoCiclo % Animacao.Ciclo)
	local iAs, iBs, alfaS = amostrar(QUADROS_SUPERIOR, tempoCiclo % Animacao.Ciclo)

	for nome, motor in pairs(motores) do
		local rot, pos
		if E_INFERIOR[nome] then
			rot = lerpVetor(VETOR_INFERIOR[iAi][nome].rot, VETOR_INFERIOR[iBi][nome].rot, alfaI)
			pos = lerpVetor(VETOR_INFERIOR[iAi][nome].pos, VETOR_INFERIOR[iBi][nome].pos, alfaI)
		else
			rot = lerpVetor(VETOR_SUPERIOR[iAs][nome].rot, VETOR_SUPERIOR[iBs][nome].rot, alfaS)
			pos = lerpVetor(VETOR_SUPERIOR[iAs][nome].pos, VETOR_SUPERIOR[iBs][nome].pos, alfaS)
			if aditivo and aditivo[nome] then
				rot = rot + aditivo[nome]
			end
		end
		motor.Transform = CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
	end
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
		tempoCiclo = 0
	end
	tocando = true
	if conexao then
		conexao:Disconnect()
	end
	conexao = RunService.Heartbeat:Connect(passo)
	return self
end

function Animacao:Atirar()
	-- Camada aditiva do recuo por cima da passada (cadência mínima 0.30 s)
	tempoTiro = 0
	return self
end

function Animacao:Stop(restaurar)
	tocando = false
	tempoTiro = nil
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
