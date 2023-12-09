Config = {}

Config.DevMode   = false

Config.ActionKey = 0x760A9C6F --[G]

-----------------------------------------------------------
--[[ Discord Webhooking  ]]--
-----------------------------------------------------------

Config.Webhooking = { 
    Enable = true, 
    Url = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", -- The discord webhook url.
    Color = 10038562,
}

-----------------------------------------------------------
--[[ TPZ-LEVELING  ]]--
-----------------------------------------------------------

Config.tpz_leveling = true

-----------------------------------------------------------
--[[ General ]]--
-----------------------------------------------------------

Config.Job                          = "lumberjack"
Config.OnlyJob                      = false -- If set to true, only the players with the Config.Job will be able to work on the mining areas.

Config.HatchetItem                  = "hatchet"
Config.DurabilityRemove             = {0, 1} -- Set to false if you don't want to remove any durability. (100% is maximum)

Config.ChoppingTimer                = 10 -- Time in seconds.
Config.ChopAgain                    = 3 -- Time in minutes (Time before you can chop again in the same tree location). Set to false if you don't want them to chop again until the next restart.

Config.ActionDistance               = 1.1

Config.DisplayActionMarkers         = true
Config.DisplayActionMarkersDistance = 10.0
Config.DisplayActionMarkersRGBA     = {r = 240, g = 230, b = 140, a = 255}

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

Config.KeyControls = { -- IF PLAYER HAVE THE HATCHET EQUIPED, HE CANNOT USE THE CONTROLS BELOW.
    Disable = true,

    Controls = {
        [1] = 0x07CE1E61, -- MOUSE1
        [2] = 0xF84FA74F, -- MOUSE2
        [3] = 0xAC4BD4F1, -- TAB
        [4] = 0xCEFD9220, -- MOUNT
        [5] = 0x4CC0E2FE, -- B
        [6] = 0x8CC9CD42, -- X
        [7] = 0x26E9DC00, -- Z
        [8] = 0xDB096B85, -- CTRL       
    },

    InventoryControl = 0xC1989F95, -- The following control is disabled only while player is chopping to prevent bugs.
}

-----------------------------------------------------------
--[[ Rewards ]]--
-----------------------------------------------------------

-- @param exp : is the experience which will it give for tpz_leveling (lumberjack type).

Config.DefaultReward   = {enabled = true, name = "wooden_sticks", label = "Wooden Sticks", quantity = { 1, 2 }, exp = 2 }

Config.RandomRewards = {
  {name = "wood",          label = "Wooden Log",    chance = 50,   quantity = {1,2},  exp = 10},
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