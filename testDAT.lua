collectgarbage("collect")
local c1 = collectgarbage("count")
local cfgs = require("SensitiveConfig/DoubleTrieData")
local c2 = collectgarbage("count")
local DATS = require("DATrie")
local dats = DATS.New()
dats:BuildBuyOfflineData(cfgs)
print("加载SensitiveWordsCfg内存:", c2 - c1)
collectgarbage("collect")
local c3 = collectgarbage("count")
print("GC后常驻内存:", c3 - c1)

function TestCheck(text, count)
	local printLine = function()
		print("----")
	end
	print(string.format("\n开始对【%s】进行敏感词检测...", text))
	local t2 = os.clock()
	for i=1,count do
		r = dats:CheckText(text)
	end
	local t3 = os.clock()
	print(string.format("\t%d次,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
end

-- TestCheck("苍井空", 1000)
-- TestCheck("苍1井空", 1000)
-- TestCheck("正常说一句话的内容大概这么长...", 1000)
-- TestCheck("11111111112222222222333333333344444444445555555555", 1000)
-- TestCheck("实拍李干三1次陈礼媛打胎实记1", 1000)

-- local cfgs = require("SensitiveWordsCfg")
-- local cfgs = require("SensitiveMultiCfg")
require("SensitiveWordsCfg")
local cfgs = gdSensitiveWordsSensitiveWords

for i,item in ipairs(cfgs) do
	v = item.word
	if not dats:CheckText(v) then
		print("严重错误，严重错误，结果不对", v)
	end
	if not dats:CheckText(v.."1") then
		print("严重错误，严重错误，结果不对", v.."1")
	end
	if not dats:CheckText("1"..v) then
		print("严重错误，严重错误，结果不对", "1"..v)
	end
end