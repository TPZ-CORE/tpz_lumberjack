

local PlayerData = {
    IsHoldingHatchet = false,
    ObjectEntity     = nil,

    IsBusy           = false,
    
    ItemId           = nil,
    Job              = "unemployed",

    RestrictedTowns  = {},
}

-----------------------------------------------------------
--[[ Functions ]]--
-----------------------------------------------------------

function GetPlayerData()
    return PlayerData
end

-----------------------------------------------------------
--[[ Local Functions ]]--
-----------------------------------------------------------

-- @GetTableLength returns the length of a table.
local function GetTableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function HasRequiredJob(currentJob)

	if not Config.Jobs or Config.Jobs and GetTableLength(Config.Jobs) <= 0 then
		return true
	end

	for _, job in pairs (Config.Jobs) do

		if job == currentJob then
			return true
		end
		
	end

	return false

end

-----------------------------------------------------------
--[[ Base Events ]]--
-----------------------------------------------------------

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if PlayerData.IsHoldingHatchet then

        ClearPedTasks(PlayerPedId())

        Citizen.InvokeNative(0xED00D72F81CF7278, PlayerData.ObjectEntity, 1, 1) -- DetachCarriableEntity

        RemoveEntityProperly(PlayerData.ObjectEntity, joaat(Config.ObjectModel) )
        Citizen.InvokeNative(0x58F7DB5BD8FA2288, PlayerPedId()) -- Cancel Walk Style

        PlayerData.IsHoldingHatchet = false
    end

end)

-----------------------------------------------------------
--[[ General Events ]]--
-----------------------------------------------------------

-- Gets the player job when devmode set to false and character is selected.
AddEventHandler("tpz_core:isPlayerReady", function()
    Wait(2000)
    
    local data = exports.tpz_core:getCoreAPI().GetPlayerClientData()

    if data == nil then
        return
    end

    PlayerData.Job = data.job

end)

-- Updates the player job.
RegisterNetEvent("tpz_core:getPlayerJob")
AddEventHandler("tpz_core:getPlayerJob", function(data)
    PlayerData.Job = data.job
end)

-- When following event is triggered, if the player is not holding any pickaxe, we attach it, otherwise we detach the pickaxe.
RegisterNetEvent("tpz_lumberjack:client:onHatchetItemUse")
AddEventHandler("tpz_lumberjack:client:onHatchetItemUse", function(itemId)
    local playerPed = PlayerPedId()

    if not PlayerData.IsHoldingHatchet then

        PlayerData.IsHoldingHatchet = true

        OnHatchetEquip()

        PlayerData.ItemId = itemId

        TriggerEvent('tpz_lumberjack:client:start_thread')
    else

        ClearPedTasks(playerPed)
        Citizen.InvokeNative(0xED00D72F81CF7278, PlayerData.ObjectEntity, 1, 1)
        DeleteObject(PlayerData.ObjectEntity)
        Citizen.InvokeNative(0x58F7DB5BD8FA2288, playerPed) -- Cancel Walk Style

        PlayerData.IsHoldingHatchet = false
    end
end)

---------------------------------------------------------------
-- Threads
---------------------------------------------------------------

-- Gets the player job when devmode set to true.
if Config.DevMode then

    Citizen.CreateThread(function ()
        
        Wait(2000)

        local data = exports.tpz_core:getCoreAPI().GetPlayerClientData()

        if data == nil then
            return
        end
    
        PlayerData.Job = data.job
    
    end)

end

Citizen.CreateThread(function()
    RegisterPromptAction()

    PlayerData.AllowedTrees    = ConvertTreesToHash()
    PlayerData.RestrictedTowns = ConvertTownRestrictionsToHash()

    while true do

        local sleep        = 1000
        local player       = PlayerPedId()
        local isPlayerDead = IsEntityDead(player)

        if isPlayerDead or not PlayerData.IsHoldingHatchet or PlayerData.IsBusy then
            Wait(1000)
            goto END
        end

        local canDoAction        = CanPlayerDoAction()
            
        local coords             = GetEntityCoords(player)
        local isInRestrictedTown = IsInRestrictedTown(coords)

        if not isInRestrictedTown and canDoAction then

            local nearbyTree = GetTreeNearby(coords, 1.4, PlayerData.AllowedTrees)

            if nearbyTree then

                sleep = 0

                local promptGroup, promptList = GetPromptData()

                local label = CreateVarString(10, 'LITERAL_STRING', Locales['HATCHET_NAME'] )
                PromptSetActiveGroupThisFrame(promptGroup, label)

                if PromptHasHoldModeCompleted(promptList) then

                    local treeCoords = CoordsToString(nearbyTree.vector_coords)

                    TriggerEvent("tpz_core:ExecuteServerCallBack", "tpz_lumberjack:callbacks:canChopTreeLocation", function(isPermitted)

                        if isPermitted then

                            local getRequiredJob = HasRequiredJob(PlayerData.Job)

                            if getRequiredJob then

                                PlayerData.IsBusy = true
            
                                SetCurrentPedWeapon(player, GetHashKey("WEAPON_UNARMED"), true, 0, false, false)
            
                                Citizen.Wait(500)
            
                                local isChopping = true
                                        
                                Citizen.CreateThread(function() 
                                    while isChopping do 
                                        Wait(0) 
                                        Anim(player,"amb_work@world_human_tree_chop_new@working@pre_swing@male_a@trans", "pre_swing_trans_after_swing", -1,0)
        
                                        Wait(2000)
                                    end
                                end)
            
                                Citizen.Wait(1000 * Config.ChoppingTimer)
                
                                TriggerServerEvent("tpz_lumberjack:server:success", treeCoords, PlayerData.ItemId)
                                        
                                ClearPedTasks(player)
                                RemoveAnimDict("amb_work@world_human_tree_chop_new@working@pre_swing@male_a@trans") -- must remove the dict of animation
                        
                                isChopping = false
                                PlayerData.IsBusy = false

                                goto END

                            else
                                SendNotification(nil, Locales['NOT_REQUIRED_JOB'], "error")
                            end

                        else
                            SendNotification(nil, Locales['ALREADY_CHOPPED'], "error")
                        end

                    end, { location = treeCoords })

                    Wait(1000)

                end

            end

        end

        ::END::
        Wait(sleep)

    end
end)

-- The following thread is disabling control actions while player has a hatchet attached.
AddEventHandler('tpz_lumberjack:client:start_thread', function()
    
    while PlayerData.IsHoldingHatchet do
        Wait(0)

        DisableControlAction(0, 0xCC1075A7, true) -- MWUP
        DisableControlAction(0, 0xDB096B85, true) -- MWDOWN

        DisableControlAction(0, 0x07CE1E61) -- MOUSE1
        DisableControlAction(0, 0xF84FA74F) -- MOUSE2
        DisableControlAction(0, 0xAC4BD4F1) -- TAB
        DisableControlAction(0, 0xCEFD9220) -- MOUNT
        DisableControlAction(0, 0x4CC0E2FE) -- B
        DisableControlAction(0, 0x8CC9CD42) -- X
        DisableControlAction(0, 0x26E9DC00) -- Z
        DisableControlAction(0, 0xDB096B85) -- CTRL       

        if PlayerData.IsBusy then
            TriggerEvent('tpz_inventory:closePlayerInventory')
        end

        -- In case the player dies, we detach the shovel and all current data.
        if PlayerData.IsHoldingHatchet and IsEntityDead(PlayerPedId()) then
			local player = PlayerPedId()
            
            ClearPedTasks(player)
            Citizen.InvokeNative(0xED00D72F81CF7278, PlayerData.ObjectEntity, 1, 1)
            DeleteObject(PlayerData.ObjectEntity)
            Citizen.InvokeNative(0x58F7DB5BD8FA2288, player) -- Cancel Walk Style
    
            PlayerData.IsHoldingHatchet = false
				
        end

    end

end)

