local TPZ = exports.tpz_core:getCoreAPI()

-----------------------------------------------------------
--[[ Callbacks  ]]--
-----------------------------------------------------------

exports.tpz_core:getCoreAPI().addNewCallBack("tpz_lumberjack:callbacks:canChopTreeLocation", function(source, cb, data)
    local _source        = source
	local xPlayer        = TPZ.GetPlayer(_source)

    local charIdentifier = xPlayer.getCharacterIdentifier()
	local ChoppedTrees   = GetChoppedTreeList()

	if ChoppedTrees[charIdentifier] then

		if ChoppedTrees[charIdentifier][data.location] then
			return cb(false)
		end

	end

	return cb(true)
end)
