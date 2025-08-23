local TPZ = exports.tpz_core:getCoreAPI()
local ChoppedTrees = {}

-----------------------------------------------------------
--[[ Local Functions ]]--
-----------------------------------------------------------

local function NearestValue(table, number)
    local smallestSoFar, smallestIndex
    for i, y in ipairs(table) do
        if not smallestSoFar or (math.abs(number-y.Chance) < smallestSoFar) then
            smallestSoFar = math.abs(number-y.Chance)
            smallestIndex = i
        end
    end
    return smallestIndex, table[smallestIndex]
end

local function GetRandomReward()

	local rewardList  = {}
	local rewardAdded = false

	if TPZ.GetTableLength(Config.RandomRewards) > 0 then
		
		for k,v in pairs(Config.RandomRewards) do 
		
			local chance = math.random(1, 100)
	
			if v.Chance >= chance then
				table.insert(rewardList, v)
				rewardAdded = true
			end
	
		end

	end

	if rewardAdded then

		local chance = math.random(1, 100)
		local index, value = NearestValue(rewardList, chance)
		return (value)

	else
		return ({Item = "nothing"})
	end

end

local function GetPlayerData(source)
	local _source = source
    local xPlayer = TPZ.GetPlayer(_source)

	return {
        steamName      = GetPlayerName(_source),
        username       = xPlayer.getFirstName() .. ' ' .. xPlayer.getLastName(),
		identifier     = xPlayer.getIdentifier(),
        charIdentifier = xPlayer.getCharacterIdentifier(),
		job            = xPlayer.getJob(),
	}

end

local function HasRequiredJob(currentJob)

	if not Config.Jobs or Config.Jobs and TPZ.GetTableLength(Config.Jobs) <= 0 then
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
--[[ Functions ]]--
-----------------------------------------------------------

function GetChoppedTreeList()
	return ChoppedTrees
end

-----------------------------------------------------------
--[[ Base Events  ]]--
-----------------------------------------------------------
 
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
      
    ChoppedTrees = nil -- clearing all data
end)

-----------------------------------------------------------
--[[ Events ]]--
-----------------------------------------------------------

RegisterServerEvent("tpz_lumberjack:server:success")
AddEventHandler("tpz_lumberjack:server:success", function(treeLocation, targetItemId)
	local _source        = source
	local PlayerData     = GetPlayerData(_source)
    local xPlayer        = TPZ.GetPlayer(_source)

	local hasRequiredJob = HasRequiredJob(PlayerData.job) -- in case its job based, we also check if player has the correct job when receiving rewards.
	local charIdentifier = PlayerData.charIdentifier -- used frequently

	if ChoppedTrees[charIdentifier] == nil then
		ChoppedTrees[charIdentifier] = {}
	end

	if ChoppedTrees[charIdentifier][treeLocation] or not hasRequiredJob then

        if Config.Webhooks['DEVTOOLS_INJECTION_CHEAT'].Enabled then
            local _w, _c      = Config.Webhooks['DEVTOOLS_INJECTION_CHEAT'].Url, Config.Webhooks['DEVTOOLS_INJECTION_CHEAT'].Color

            if string.find(_w, "GetWebhookUrl") then local input = str:match("%((.-)%)") _w = TPZ.GetWebhookUrl(input) end

            local description = 'The specified user attempted to use devtools / injection or netbug cheat on lumberjack reward.'
            TPZ.SendToDiscordWithPlayerParameters(_w, Locales['DEVTOOLS_INJECTION_DETECTED_TITLE_LOG'], _source, PlayerData.steamName, PlayerData.username, PlayerData.identifier, PlayerData.charIdentifier, description, _c)
        end

        ListedPlayers[_source] = nil
        --xPlayer.disconnect(Locales['DEVTOOLS_INJECTION_DETECTED'])
        xPlayer.ban(Locales['DEVTOOLS_INJECTION_DETECTED'], -1)
		return
	end

	ChoppedTrees[charIdentifier][treeLocation] = {}
	ChoppedTrees[charIdentifier][treeLocation].cooldown = Config.ChopAgain

	-- Removing durability if enabled on action.
	if Config.Durability.Enabled and targetItemId then
		local randomValueRemove = math.random(Config.Durability.RemoveValue.min, Config.Durability.RemoveValue.max)
        xPlayer.removeItemDurability(Config.HatchetItem, randomValueRemove, targetItemId, false)
    end

	local foundText      = ""
	local cannotCarryAny = false -- required to check for default reward if received / not

	if Config.DefaultReward.Enabled then

		local DefaultRewardConfig = Config.DefaultReward

		local randomQuantity = math.random(DefaultRewardConfig.Quantity.min, DefaultRewardConfig.Quantity.max)
		local canCarryItem   = xPlayer.canCarryItem(DefaultRewardConfig.Item, randomQuantity)

		if Config.tpz_leveling then

			local LevelingAPI = exports.tpz_leveling:getAPI()
			LevelingAPI.AddPlayerLevelExperience(_source, 'lumberjack', DefaultRewardConfig.Experience)
		end

		Wait(500)
		if canCarryItem then

			xPlayer.addItem(DefaultRewardConfig.Item, randomQuantity, nil)

			foundText = "X" .. randomQuantity .. " " .. DefaultRewardConfig.Label
		else

			cannotCarryAny = true
			SendNotification(_source, Locales['CANNOT_CARRY'], "error")
		end

	else
		cannotCarryAny = true
	end

	-- Generate Random Reward (if available)
	local RewardItem = GetRandomReward()

	if RewardItem.Item ~= "nothing" then

		local randomQuantity = math.random(RewardItem.Quantity.min, RewardItem.Quantity.max)

		if Config.tpz_leveling then
			local LevelingAPI = exports.tpz_leveling:getAPI()
			LevelingAPI.AddPlayerLevelExperience(_source, 'lumberjack', RewardItem.Experience)
		end
	
		local canCarryItem = xPlayer.canCarryItem(RewardItem.Item, randomQuantity)

		Wait(500)
		if canCarryItem then
	
			xPlayer.addItem(RewardItem.Item, randomQuantity, nil)

			if cannotCarryAny then
				foundText = "X" ..  randomQuantity .. " " .. RewardItem.Label
			else
				foundText = foundText .. " & X" ..  randomQuantity .. " " .. RewardItem.Label
			end

			cannotCarryAny = false
		else
			SendNotification(_source, Locales['CANNOT_CARRY'], "error")
		end

	end

	if not cannotCarryAny then
		SendNotification(_source, string.format(Locales['SUCCESSFULLY_FOUND_REWARDS'], foundText), "success")
	end

end)

-----------------------------------------------------------
--[[ Threads ]]--
-----------------------------------------------------------

if Config.ChopAgain ~= false then

	Citizen.CreateThread(function ()

		while true do

			Wait(60000)

			if TPZ.GetTableLength(ChoppedTrees) > 0 then
				
				for charIdentifier, table in pairs (ChoppedTrees) do

					for index, tree in pairs (table) do

						tree.cooldown = tree.cooldown - 1

						if tree.cooldown <= 0 then
							tree.coodown = 0

							ChoppedTrees[charIdentifier][index] = nil
						end

					end

				end

			end

		end

	end)

end
