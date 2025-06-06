local Prompts     = GetRandomIntInRange(0, 0xffffff)
local PromptList = nil

--[[-------------------------------------------------------
 Base Events
]]---------------------------------------------------------

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Citizen.InvokeNative(0x00EDE88D4D13CF59, Prompts) -- UiPromptDelete
end)

-----------------------------------------------------------
--[[ Prompts ]]--
-----------------------------------------------------------

RegisterPromptAction = function()
    local str = Locales['HATCHET']

    local dPrompt = PromptRegisterBegin()

    PromptSetControlAction(dPrompt, Config.ActionKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(dPrompt, str)
    PromptSetEnabled(dPrompt, 1)
    PromptSetVisible(dPrompt, 1)
    PromptSetStandardMode(dPrompt, 1)
    PromptSetHoldMode(dPrompt, 1000)
    PromptSetGroup(dPrompt, Prompts)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, dPrompt, true)
    PromptRegisterEnd(dPrompt)

    PromptList = dPrompt
end

function GetPromptData()
    return Prompts, PromptList
end

-----------------------------------------------------------
--[[ Converts ]]--
-----------------------------------------------------------

function ConvertTreesToHash()
    local model_hashes = {}

    for _, model_name in pairs(Trees.List) do
        local model_hash = GetHashKey(model_name)
        model_hashes[model_hash] = model_name
    end

    return model_hashes
end

function ConvertTownRestrictionsToHash()

    local PlayerData = GetPlayerData()

    for _, town_restriction in pairs(Config.TownRestrictions) do
        if not town_restriction.allowed then
            local town_hash = GetHashKey(town_restriction.name)
            PlayerData.RestrictedTowns[town_hash] = town_restriction.name
        end
    end

    return PlayerData.RestrictedTowns
end

function IsInRestrictedTown(coords)
    local PlayerData = GetPlayerData()

    local x, y, z = table.unpack(coords)
    local town_hash = GetTown(x, y, z)

    if town_hash == false then
        return false
    end

    if PlayerData.RestrictedTowns[town_hash] then
        return true
    end

    return false
end

function GetTown(x, y, z)
    return Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, 1)
end

function GetTreeNearby(coords, radius, hash_filter)
    local itemSet = CreateItemset(true)
    local size    = Citizen.InvokeNative(0x59B57C4B06531E1E, coords, radius, itemSet, 3, Citizen.ResultAsInteger())
    local found_entity

    if size > 0 then
        for index = 0, size - 1 do
            local entity     = GetIndexedItemInItemset(index, itemSet)
            local model_hash = GetEntityModel(entity)

            if hash_filter[model_hash] then
                local tree_coords = GetEntityCoords(entity)
                local tree_x, tree_y, tree_z = table.unpack(tree_coords)

                found_entity = {
                    model_name = hash_filter[model_hash],
                    entity = entity,
                    model_hash = model_hash,
                    vector_coords = tree_coords,
                    x = tree_x,
                    y = tree_y,
                    z = tree_z,
                }

                break
            end
        end
    end

    if IsItemsetValid(itemSet) then
        DestroyItemset(itemSet)
    end

    return found_entity
end

function CoordsToString(coords)
    return round(coords[1], 1) .. '-' .. round(coords[2], 1) .. '-' .. round(coords[3], 1)
end


function round(num, decimals)
    if type(num) ~= "number" then
        return num
    end

    local multiplier = 10 ^ (decimals or 0)
    return math.floor(num * multiplier + 0.5) / multiplier
end

-----------------------------------------------------------
--[[ General ]]--
-----------------------------------------------------------

Anim = function(actor, dict, body, duration, flags, introtiming, exittiming)
    Citizen.CreateThread(function()
        RequestAnimDict(dict)
        local dur = duration or -1
        local flag = flags or 1
        local intro = tonumber(introtiming) or 1.0
        local exit = tonumber(exittiming) or 1.0
        timeout = 5
        while (not HasAnimDictLoaded(dict) and timeout>0) do
            timeout = timeout-1
            if timeout == 0 then 
                print("Animation Failed to Load")
            end
            Citizen.Wait(300)
        end
        TaskPlayAnim(actor, dict, body, intro, exit, dur, flag --[[1 for repeat--]], 1, false, false, false, 0, true)
    end)
end


LoadModel = function(inputModel)
    local model = joaat(inputModel)
 
    RequestModel(model)
 
    while not HasModelLoaded(model) do RequestModel(model)
        Citizen.Wait(10)
    end
 end

RemoveEntityProperly = function(entity, objectHash)
    DeleteEntity(entity)
    DeletePed(entity)
    SetEntityAsNoLongerNeeded( entity )

    if objectHash then
        SetModelAsNoLongerNeeded(objectHash)
    end
end

OnHatchetEquip = function()
    local PlayerData = GetPlayerData()
    local ped        = PlayerPedId()
    
    Citizen.InvokeNative(0x6A2F820452017EA2) -- Clear Prompts from Screen
    SetCurrentPedWeapon(ped, joaat("WEAPON_UNARMED"), true, 0, false, false)

    if PlayerData.ObjectEntity then
        RemoveEntityProperly(PlayerData.ObjectEntity, joaat(Config.ObjectModel) )
    end

    LoadModel(Config.ObjectModel)

    PlayerData.ObjectEntity = CreateObject(joaat(Config.ObjectModel), GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,0.0), true, true, true)

    AttachEntityToEntity(PlayerData.ObjectEntity, ped, GetPedBoneIndex(ped, 7966), 0.0,0.0,0.0,  0.0,0.0,0.0, 0, 0, 0, 0, 2, 1, 0, 0);

    Citizen.InvokeNative(0x923583741DC87BCE, ped, 'arthur_healthy')
    Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, "carry_pitchfork")
    Citizen.InvokeNative(0x2208438012482A1A, ped, true, true)
    ForceEntityAiAndAnimationUpdate(PlayerData.ObjectEntity, 1)
    Citizen.InvokeNative(0x3A50753042B6891B, ped, "PITCH_FORKS")
end

CanPlayerDoAction = function()

    local player = PlayerPedId()

    if IsPedOnMount(player) or IsPedInAnyVehicle(player) or IsPedDeadOrDying(player) or IsEntityInWater(player) or IsPedClimbing(player) or not IsPedOnFoot(player) then
        return false
    end

    return true
end
