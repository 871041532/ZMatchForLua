require("Preload")
local LibraryFilter = require("CSharpEdition/CSharpEditionLua")

local dirtyFilter

function InitTestEnvironment()
	collectgarbage("collect")
	local c = collectgarbage("count")
	local cfgs = require("SensitiveWordsCfg")
	collectgarbage("collect")
	local c1 = collectgarbage("count")
	print("配置表内存:", c1 - c)
	local t1 = os.clock()
	dirtyFilter = LibraryFilter.New()
	dirtyFilter:InitByCfgs(cfgs)
	dirtyFilter:InitStringArray({"abcdefghijklmn"})
	dirtyFilter.aa = {}
	local t2 = os.clock()
	collectgarbage("collect")
	local c2 = collectgarbage("count")
	print("构建Trie内存:", c2 - c1)
	cfgs = nil
	collectgarbage("collect")
	local c3 = collectgarbage("count")
	print("常驻总内存:", c3 - c)
	print("构建时间:", t2 - t1)
	print("配置词条总量", dirtyFilter.cfgCount)
end
local printLine = function()
	print("----")
end

function TestCheck(text, count)
	printLine()
	print(string.format("\n开始对【%s】进行敏感词检测...", text))
	local t2 = os.clock()
	for i=1,count do
		local a = string.ConvertToCharArray(text)
	-- 	r = dirtyFilter:HasBadWord(text)
	end
	local t3 = os.clock()
	print(string.format("\t%d次,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
	
end


InitTestEnvironment()
-- CheckRepetCfg()
TestCheck("abcdefghijklmnopqrst", 1000)
TestCheck("苍井空", 1000)
TestCheck("正常说一句话的内容大概这么长...", 1000)
TestCheck("1111111111.1111111111.1111111111.1111111111.1111111111", 1000)