Config = {}

Config.DevMode   = false
Config.ActionKey = 0x760A9C6F --[G]

-----------------------------------------------------------
--[[ Webhooking (Only DevTools - Injection Cheat Logs) ]]--
-----------------------------------------------------------

-- (!) Checkout tpz_core/server/discord/webhooks.lua to modify the webhook urls.
Config.Webhooks = {
    
    ['DEVTOOLS_INJECTION_CHEAT'] = { -- Warnings and Logs about players who used or atleast tried to use devtools injection.
        Enabled = false, 
        Color = 10038562,
    },

}

-----------------------------------------------------------
--[[ General ]]--
-----------------------------------------------------------

-- Set to false if you don't use tpz_leveling resource.
Config.tpz_leveling                 = true

Config.Jobs                         = { "lumberjack" } -- set to false if you want to disable jobs based.

Config.HatchetItem                  = "hatchet"
Config.ObjectModel                  = 'p_axe02x'

-- Set to false if you don't want the hatchet durability to removed.
Config.Durability                   = { Enabled = true, RemoveValue = { min = 0, max = 1 } }

Config.ChoppingTimer                = 10 -- Time in seconds.

-- (!) Set to false if you don't want them to chop again the same tree until the next restart.
Config.ChopAgain                    = 30 -- Time in minutes (Time before you can chop again in the same tree location).

Config.ActionDistance               = 1.1

Config.DisplayActionMarkers         = true
Config.DisplayActionMarkersDistance = 10.0
Config.DisplayActionMarkersRGBA     = {r = 240, g = 230, b = 140, a = 255}

-----------------------------------------------------------
--[[ Rewards ]]--
-----------------------------------------------------------

-- (!) The default reward item to receive always.
-- @param exp : is the experience to receive if tpz_leveling is enabled based on the lumberjacks.
Config.DefaultReward = {Enabled = true, Item = "wooden_sticks", Label = "Wooden Sticks", Quantity = { min = 1, max = 2 }, Experience = 2 }

-- Extra random rewards! Set to {} or false if you don't want any extra random rewards.
Config.RandomRewards = {
    { Item = "wood", Label = "Wooden Log", Chance = 50, Quantity = { min = 1, max = 2 }, Experience = 10 },
}

-----------------------------------------------------------
--[[ Town Restrictions ]]--
-----------------------------------------------------------

Config.TownRestrictions = {
    { name = 'Annesburg',  allowed = false },
    { name = 'Armadillo',  allowed = false },
    { name = 'Blackwater', allowed = false },
    { name = 'Lagras',     allowed = false },
    { name = 'Rhodes',     allowed = false },
    { name = 'StDenis',    allowed = false },
    { name = 'Strawberry', allowed = false },
    { name = 'Tumbleweed', allowed = false },
    { name = 'Valentine',  allowed = false },
    { name = 'Vanhorn',    allowed = false },
}

-----------------------------------------------------------
--[[ Notification Functions  ]]--
-----------------------------------------------------------

-- @param source is always null when called from client.
-- @type returns "success" or "error" based on actions.
function SendNotification(source, message, type)
    local duration = 3000

    if not source then
        TriggerEvent('tpz_core:sendBottomTipNotification', message, duration)
    else
        TriggerClientEvent('tpz_core:sendBottomTipNotification', source, message, duration)
    end

end

