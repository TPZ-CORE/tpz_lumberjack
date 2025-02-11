local TPZ = exports.tpz_core:getCoreAPI()
local ListedPlayers = {}

-----------------------------------------------------------
--[[ Local Functions ]]--
-----------------------------------------------------------

-- @GetTableLength returns the length of a table.
local function GetTableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function NearestValue(table, number)
    local smallestSoFar, smallestIndex
    for i, y in ipairs(table) do
        if not smallestSoFar or (math.abs(number-y.chance) < smallestSoFar) then
            smallestSoFar = math.abs(number-y.chance)
            smallestIndex = i
        end
    end
    return smallestIndex, table[smallestIndex]
end

local function GetRandomReward(inputLocation)

	local rewardList  = {}
	local rewardAdded = false

	if GetTableLength(Config.Items[inputLocation]) > 0 then
		
		for k,v in pairs(Config.Items[inputLocation]) do 
		
			math.randomseed(os.time()) -- required to refresh the random.math for better results. 
			local chance = math.random(1, 100)
	
			if v.chance >= chance then
				table.insert(rewardList, v)
				rewardAdded = true
			end
	
		end

	end

	if rewardAdded then
		math.randomseed(os.time()) -- required to refresh the random.math for better results. 

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
--[[ Base Events  ]]--
-----------------------------------------------------------
 
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
      
    ListedPlayers = nil -- clearing all data
end)

-----------------------------------------------------------
--[[ Events ]]--
-----------------------------------------------------------

RegisterServerEvent("tpz_mining:server:success")
AddEventHandler("tpz_mining:server:success", function(targetMiningLocation, targetItemId)
	local _source    = source
	local PlayerData = GetPlayerData(_source)
	local xPlayer    = TPZ.GetPlayer(_source)

	math.randomseed(os.time())
	
	Wait( math.random(100, 250) )

	if (targetMiningLocation == nil) or (targetMiningLocation and Config.Items[targetMiningLocation] == nil) or (not hasRequiredJob) or (ListedPlayers[_source]) then

        if Config.Webhooks['DEVTOOLS_INJECTION_CHEAT'].Enabled then
            local _w, _c      = Config.Webhooks['DEVTOOLS_INJECTION_CHEAT'].Url, Config.Webhooks['DEVTOOLS_INJECTION_CHEAT'].Color
            local description = 'The specified user attempted to use devtools / injection or netbug cheat on mining reward.'
            TPZ.SendToDiscordWithPlayerParameters(_w, Locales['DEVTOOLS_INJECTION_DETECTED_TITLE_LOG'], _source, PlayerData.steamName, PlayerData.username, PlayerData.identifier, PlayerData.charIdentifier, description, _c)
        end

		ListedPlayers[_source] = nil
        xPlayer.disconnect(Locales['DEVTOOLS_INJECTION_DETECTED'])

		return
	end

	ListedPlayers[_source] = true

	-- Removing durability if enabled on action.
	if Config.Durability.Enabled and targetItemId then
		local randomValueRemove = math.random(Config.Durability.RemoveValue.min, Config.Durability.RemoveValue.max)
		xPlayer.removeItemDurability(Config.PickaxeItem, randomValueRemove, targetItemId, false)
	end

	local RewardItem = GetRandomReward(targetMiningLocation)

	if RewardItem.Item ~= "nothing" then

		math.randomseed(os.time()) -- required to refresh the random.math for better results. 
		local randomQuantity = math.random(RewardItem.quantity.min, RewardItem.quantity.max)

		if Config.tpz_leveling then

			local LevelingAPI = exports.tpz_leveling:getAPI()
			LevelingAPI.AddPlayerLevelExperience(_source, 'mining', RewardItem.experience )
		end

		local canCarryItem = xPlayer.canCarryItem(RewardItem.item, randomQuantity)

		Wait(500)
		if canCarryItem then

			xPlayer.addItem(RewardItem.item, randomQuantity, nil)

			SendNotification(_source, string.format(Locales['SUCCESSFULLY_FOUND_REWARD'], randomQuantity, RewardItem.label), "success")
			
		else
			SendNotification(_source, Locales['CANNOT_CARRY'], "error")
		end

	else
		SendNotification(_source, Locales['FOUND_NOTHING'], "error")
	end

	Wait(3000)
	ListedPlayers[_source] = nil

end)
