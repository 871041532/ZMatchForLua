

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
local c = collectgarbage("count")
local ZMatch = require("ZMatch")
local function InitTestEnvironment()
	EvalCfg()
	zmatch = ZMatch.New()
	zmatch:BuildTrie()
	-- zmatch:BuildAC()
	-- print("构建AC内存:", c3 - c2)
	-- print("构建AC耗时:", t2 - t1)
end
require("SensitiveWordsCfg")
local c1 = collectgarbage("count")
print("构建SensitiveWordsCfg内存:", c1 - c)

collectgarbage("collect")

local c = collectgarbage("count")
--do handle
	InitTestEnvironment()
local c1 = collectgarbage("count")
print("构建SensitiveWordsCfg 2内存:", c1 - c)

