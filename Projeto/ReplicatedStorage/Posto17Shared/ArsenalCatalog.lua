-- Local no Studio: ReplicatedStorage/Posto17Shared/ArsenalCatalog (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
local items = {
    {id="Pistol", attribute="P17LoadoutPistol", label="Pistola",
        description="Arma secundária para a missão.", enable="Equipar", disable="Guardar",
        on="Equipada", off="Na reserva"},
    {id="Suppressor", attribute="P17LoadoutSuppressor", label="Supressor",
        description="12 disparos silenciados por missão.", enable="Instalar", disable="Retirar",
        on="Instalado", off="Na bancada"},
}
return items
