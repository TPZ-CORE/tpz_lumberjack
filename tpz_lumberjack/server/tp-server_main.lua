local TPZ    = {}
local TPZInv = exports.tpz_inventory:getInventoryAPI()

TriggerEvent("getTPZCore", function(cb) TPZ = cb end)


local ChoppedTrees = {}


-----------------------------------------------------------
--[[ Events ]]--
-----------------------------------------------------------

RegisterServerEvent("tpz_lumberjack:requestChoppedTrees")
AddEventHandler("tpz_lumberjack:requestChoppedTrees", function()
	local _source         = source
	local xPlayer         = TPZ.GetPlayer(_source)
    local charidentifier  = xPlayer.getCharacterIdentifier()

	if ChoppedTrees[charidentifier] then

		local newList  = {}
		local finished = false
		
		-- If char exists, we replace the source when requesting chopped trees (reconnected).
		ChoppedTrees[charidentifier].source = _source

		local tableLength = GetTableLength(ChoppedTrees[charidentifier].list)

		if tableLength > 0 then

			for index, tree in pairs (ChoppedTrees[charidentifier].list) do
				newList[tree.location] = true
	
				if next(ChoppedTrees[charidentifier].list, index) == nil then
					finished = true
				end
			end
	
			while not finished do
				Wait(250)
			end
	
			TriggerClientEvent("tpz_lumberjack:receiveChoppedTrees", _source, newList)

		end
	end
end)

RegisterServerEvent("tpz_lumberjack:onChoppingSuccessReward")
AddEventHandler("tpz_lumberjack:onChoppingSuccessReward", function(treeLocation)
	local _source         = source
	local xPlayer         = TPZ.GetPlayer(_source)

    local identifier      = xPlayer.getIdentifier()
    local charidentifier  = xPlayer.getCharacterIdentifier()
    local steamName       = GetPlayerName(_source)

    local webhookData     = Config.Webhooking
    local message         = "**Steam name: **`" .. steamName .. "`**\nIdentifier: **`" .. identifier .. " (Char: " .. charidentifier .. ") `"

	local foundText       = ""

	if ChoppedTrees[charidentifier] == nil then

		ChoppedTrees[charidentifier]        = {}

		ChoppedTrees[charidentifier].source = _source
		ChoppedTrees[charidentifier].list   = {}

		Wait(150)
	end

	ChoppedTrees[charidentifier].list[treeLocation]          = {}
	ChoppedTrees[charidentifier].list[treeLocation].location = treeLocation
	ChoppedTrees[charidentifier].list[treeLocation].cb       = true
	ChoppedTrees[charidentifier].list[treeLocation].cooldown = Config.ChopAgain

	-- Default Reward.

	if Config.DefaultReward.enabled then
		local defaultReward = Config.DefaultReward

		local quantity  = math.random(defaultReward.quantity[1], defaultReward.quantity[2])

		local canCarryItem = TPZInv.canCarryItem(_source, defaultReward.name, quantity)
	
		Wait(500)
	
		if canCarryItem then
	
			TPZInv.addItem(_source, defaultReward.name, quantity, nil)
			foundText = "X" .. quantity .. " " .. defaultReward.label
	
		else
			SendNotification(_source, Locales['CANNOT_CARRY'], "error")
		end

	end

	-- Random Rewards
	local reward = GetRandomReward()

	if reward.name ~= "nothing" then

		local rquantity  = math.random(reward.quantity[1], reward.quantity[2])

		if Config.tpz_leveling then
			TriggerEvent("tp_leveling:AddLevelExperience", _source, "lumberjack", tonumber(reward.exp))
		end
	
		local canCarryItem = TPZInv.canCarryItem(_source, reward.name, rquantity)
	
		Wait(500)
	
		if canCarryItem then
	
			TPZInv.addItem(_source, reward.name, rquantity, nil)
			foundText = foundText .. " & X" ..  rquantity .. " " .. reward.label
		else
			SendNotification(_source, Locales['CANNOT_CARRY'], "error")
		end

	end

	SendNotification(_source, string.format(Locales['SUCCESSFULLY_FOUND'] .. foundText), "success")
	
	if webhookData.Enable then
		local title = "🌳` The following player found " .. foundText .. ".`"
		TriggerEvent("tpz_core:sendToDiscord", webhookData.Url, title, message, webhookData.Color)
	end

end)

-- The following event is triggered to update the current pickaxe durability in client side for updating properly.
RegisterServerEvent("tpz_lumberjack:requestDurability")
AddEventHandler("tpz_lumberjack:requestDurability", function(itemId)
	local _source           = source

    local currentDurability = TPZInv.getItemDurability(_source, Config.HatchetItem, itemId)
    TriggerClientEvent('tpz_lumberjack:updateDurability', _source, currentDurability)
end)

-- The following event is triggered on every action in order to remove the requested durability.
RegisterServerEvent("tpz_lumberjack:removeDurability")
AddEventHandler("tpz_lumberjack:removeDurability", function(itemId)
	local _source           = source

    local currentDurability = TPZInv.getItemDurability(_source, Config.HatchetItem, itemId)

    if currentDurability <= 0 then
        return
    end

	local randomDurability = math.random(Config.DurabilityRemove[1], Config.DurabilityRemove[2])

	TPZInv.removeItemDurability(_source, Config.HatchetItem, randomDurability, itemId, false)

    -- We check if the amount we removed goes to 0, to remove the pickaxe from the player hands after finishing.
    if (currentDurability - randomDurability) <= 0 then
        TriggerClientEvent('tpz_lumberjack:onHatchetItemUse', _source, 0, 100)
    end

end)

-----------------------------------------------------------
--[[ Threads ]]--
-----------------------------------------------------------

if Config.ChopAgain then

	Citizen.CreateThread(function ()
		while true do
			Wait(60000)

			local tableLength = GetTableLength(ChoppedTrees)

			if tableLength > 0 then
				
				for _, choppedList in pairs (ChoppedTrees) do
					
					for _, tree in pairs (choppedList.list) do

						tree.cooldown = tree.cooldown - 1

						if tree.cooldown <= 0 then
							tree.cooldown = 0

							choppedList.list[tree.location] = nil

							if GetPlayerName(choppedList.source) then
								TriggerClientEvent("tpz_lumberjack:getRemovedChoppedTree", choppedList.source, tree.location)
							end

						end

					end

				end

			end

		end
	end)

end
-----------------------------------------------------------
--[[ Functions ]]--
-----------------------------------------------------------

-- @GetTableLength returns the length of a table.
function GetTableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function GetRandomReward()
	local rewards  = {}
    local chance   =  math.random(1, 100)
	local finished = false
	local added    = false

	for k,v in pairs(Config.RandomRewards) do 
		
		if v.chance >= chance then
			table.insert(rewards, v)
			added = true
		end

		if next(Config.RandomRewards, k) == nil then
			finished = true
		end
	end

	while not finished do
		Wait(10)
	end

	if added then
		chance   =  math.random(1, 100)
		local index, value = NearestValue(rewards, chance)
		return (value)
	else

		return ({name = "nothing"})
	end

end

function NearestValue(table, number)
    local smallestSoFar, smallestIndex
    for i, y in ipairs(table) do
        if not smallestSoFar or (math.abs(number-y.chance) < smallestSoFar) then
            smallestSoFar = math.abs(number-y.chance)
            smallestIndex = i
        end
    end
    return smallestIndex, table[smallestIndex]
end