

ClientData = {
    IsHoldingHatchet = false,
    HatchetTool      = nil,

    IsBusy           = false,
    
    ItemId           = 0,
    Durability       = 100,

    Job              = "unemployed",

    ChoppedTrees     = {},

    RestrictedTowns  = {},
}

-----------------------------------------------------------
--[[ Base Events ]]--
-----------------------------------------------------------

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if ClientData.IsHoldingHatchet then

        ClearPedTasks(PlayerPedId())
        Citizen.InvokeNative(0xED00D72F81CF7278, ClientData.HatchetTool, 1, 1)
        DeleteObject(ClientData.HatchetTool)
        Citizen.InvokeNative(0x58F7DB5BD8FA2288, PlayerPedId()) -- Cancel Walk Style

        ClientData.IsHoldingHatchet = false

        ClearPedTasks(PlayerPedId())
    end

end)

-- Gets the player job when devmode set to false and character is selected.
AddEventHandler("tpz_core:isPlayerReady", function()

    TriggerEvent("tpz_core:ExecuteServerCallBack", "tpz_core:getPlayerData", function(data)
        ClientData.Job = data.job
    end)

    TriggerServerEvent("tpz_lumberjack:requestChoppedTrees")
    
end)

-- Updates the player job.
RegisterNetEvent("tpz_core:getPlayerJob")
AddEventHandler("tpz_core:getPlayerJob", function(data)
    ClientData.Job = data.job
end)

-- Gets the player job when devmode set to true.
if Config.DevMode then
    Citizen.CreateThread(function ()

        Wait(2000)

        TriggerEvent("tpz_core:ExecuteServerCallBack", "tpz_core:getPlayerData", function(data)
            ClientData.Job = data.job
        end)

    end)
end

-- The following event is triggered only for receiveing all the chopped trees data when someone tried to relog.
RegisterNetEvent("tpz_lumberjack:receiveChoppedTrees")
AddEventHandler("tpz_lumberjack:receiveChoppedTrees", function(data)
    ClientData.ChoppedTrees = data
end)

-- Update a chopped tree for removing
RegisterNetEvent("tpz_lumberjack:getRemovedChoppedTree")
AddEventHandler("tpz_lumberjack:getRemovedChoppedTree", function(treeLocation)

    print("removed")
    ClientData.ChoppedTrees[treeLocation] = nil
end)


-----------------------------------------------------------
--[[ Events ]]--
-----------------------------------------------------------

-- When following event is triggered, if the player is not holding any pickaxe, we attach it, otherwise we detach the pickaxe.
RegisterNetEvent("tpz_lumberjack:onHatchetItemUse")
AddEventHandler("tpz_lumberjack:onHatchetItemUse", function(itemId, durability)
    local playerPed    = PlayerPedId()

    if not ClientData.IsHoldingHatchet then

        ClientData.IsHoldingHatchet = true

        OnHatchetEquip('p_axe02x')

        ClientData.ItemId     = itemId
        ClientData.Durability = durability

    else

        ClearPedTasks(playerPed)
        Citizen.InvokeNative(0xED00D72F81CF7278, ClientData.HatchetTool, 1, 1)
        DeleteObject(ClientData.HatchetTool)
        Citizen.InvokeNative(0x58F7DB5BD8FA2288, playerPed) -- Cancel Walk Style

        ClientData.IsHoldingHatchet = false
    end
end)

-- The following event is triggered to update the current durability during changes (actions).
RegisterNetEvent('tpz_lumberjack:updateDurability')
AddEventHandler('tpz_lumberjack:updateDurability', function(cb)
    ClientData.Durability = cb
end)

---------------------------------------------------------------
-- Threads
---------------------------------------------------------------


-- check job
-- add tree to server
Citizen.CreateThread(function()
    RegisterPrompts()

    ClientData.AllowedTrees    = ConvertTreesToHash()
    ClientData.RestrictedTowns = ConvertTownRestrictionsToHash()

    while true do
        Citizen.Wait(0)

        local sleep        = true

        local player       = PlayerPedId()
        local coords       = GetEntityCoords(player)
        local isPlayerDead = IsEntityDead(player)

        if not isPlayerDead and ClientData.IsHoldingHatchet and not ClientData.IsBusy then

            if (Config.OnlyJob and ClientData.Job == Config.Job) or (not Config.OnlyJob) then

                local canDoAction        = CanPlayerDoAction(player)
                local isInRestrictedTown = IsInRestrictedTown(coords)
    
                if not isInRestrictedTown and canDoAction then
    
                    local nearbyTree = GetUnChoppedNearbyTree(ClientData.AllowedTrees, coords)
    
                    if nearbyTree and not IsTreeAlreadyChopped(nearbyTree.vector_coords) then
                        sleep = false
    
                        local label = CreateVarString(10, 'LITERAL_STRING', Locales['HATCHET_NAME'] .. " | " .. ClientData.Durability .. "%")
                        PromptSetActiveGroupThisFrame(Prompt, label)
        
                        if Citizen.InvokeNative(0xC92AC953F0A982AE, PromptList) then
    
                            local treeCoords = CoordsToString(nearbyTree.vector_coords)
    
                            ClientData.ChoppedTrees[treeCoords] = true
                            ClientData.IsBusy = true
        
                            SetCurrentPedWeapon(player, joaat("WEAPON_UNARMED"), true, 0, false, false)
        
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
            
                            TriggerServerEvent("tpz_lumberjack:onChoppingSuccessReward", treeCoords)
                                    
                            ClearPedTasks(player)
                    
                            if Config.DurabilityRemove then
    
                                TriggerServerEvent("tpz_lumberjack:removeDurability", ClientData.ItemId)
                    
                                Wait(500)
                                TriggerServerEvent("tpz_lumberjack:requestDurability", ClientData.ItemId)
                    
                            end
    
                            isChopping = false
                            ClientData.IsBusy = false
        
                        end
    
                    end

                end

            end
        end

        -- In case the player dies, we detach the shovel and all current data.
        if ClientData.IsHoldingHatchet and isPlayerDead then
            TriggerEvent('tpz_lumberjack:onHatchetItemUse')
        end

        if sleep then
            Citizen.Wait(1000)
        end

    end
end)

-- The following thread is disabling control actions while player has a hatchet attached.
if Config.KeyControls.Disable then

    Citizen.CreateThread(function()
        while true do
            Wait(0)

            if ClientData.IsHoldingHatchet then

                for index, control in pairs (Config.KeyControls.Controls) do
                    DisableControlAction(0, control)
                end

                if ClientData.IsBusy then
                    DisableControlAction(0, Config.KeyControls.InventoryControl)
                end

            else
                Wait(1000)
            end
        end
    end)

end
