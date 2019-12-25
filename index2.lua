

-- local c = collectgarbage("count")
-- require("GenerateTable")
-- local c1 = collectgarbage("count")
-- print("构建GenerateTable内存:", c1 - c)
local function EvalCfg()
	--整理一下配置表
	local cfgs = {}
	for _,v in ipairs(gdSensitiveWordsSensitiveWords) do
		table.insert(cfgs, v)
	end

	local sortFunc = function(v1, v2)
		local chars1 = string.ConvertToCharArray(v1.word)
		local chars2 = string.ConvertToCharArray(v2.word)
		return #chars1 < #chars2
	end
	table.sort(cfgs, sortFunc)
	gdSensitiveWordsSensitiveWords = cfgs
end



collectgarbage("collect")

local c = collectgarbage("count")
require("SensitiveWordsCfg")
local c1 = collectgarbage("count")
print("加载配置内存:", c1 - c)

-- EvalCfg()
-- collectgarbage("collect")

local c = collectgarbage("count")
local ZMatch = require("ZMatch")
zmatch = ZMatch.New()
zmatch:BuildTrie()
local c1 = collectgarbage("count")
print("动态构建内存:", c1 - c)

