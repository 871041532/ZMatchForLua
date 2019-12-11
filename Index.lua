local ZMatch = require("ZMatch")

local zmatch
local t1
local t2
local t3
local count
local r

function InitTestEnvironment()
	zmatch = ZMatch.New()
	t1 = os.clock()
	zmatch:BuildTrie()
	t2 = os.clock()
	print("构建Trie耗时:", t2 - t1)
	t1 = os.clock()
	zmatch:BuildAC()
	t2 = os.clock()
	print("构建AC耗时:", t2 - t1)
	local count = 0
	for _,_ in pairs(zmatch.originCfg) do
		count = count + 1
	end
	print("敏感词总量", count)
	print("常规词数量", zmatch.singleCount)
	print("带&词数量", #zmatch.multiList)
end
local printLine = function()
	print("----")
end

function TestCheck(text, newWayCount, oldWayCOunt)
	print(string.format("\n\n开始对【%s】进行敏感词检测...", text))
	printLine()
	count = oldWayCOunt
	t2 = os.clock()
	for i=1,count do
		r = zmatch:_CheckAllByTraverse(text)
	end
	t3 = os.clock()
	print(string.format("老接口%d次全词检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	count = newWayCount
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckTextByAC(text)
	end
	t3 = os.clock()
	print(string.format("最终接口%d次全词检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	printLine()
	local chars = string.ConvertToCharArray(text)
	t2 = os.clock()
	for i=1,count do
		r = zmatch:_CheckSingleByTrie(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词Trie检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	t2 = os.clock()
	for i=1,count do
		r = zmatch:_CheckSingleByAC(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词AC检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	printLine()
	t2 = os.clock()
	for i=1,count do
		r = zmatch:_CheckMultiByTrie(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词Trie检测,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
	t2 = os.clock()
	for i=1,count do
		r = zmatch:_CheckMultiByTraverse(text)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词遍历检测,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
end

function TestFilter(text, newWayCount, oldWayCOunt)
	count = newWayCount
	t2 = os.clock()
	for i=1,count do
		r = zmatch:FilterText(text)
	end
	t3 = os.clock()
	print(string.format("\n\n%d次敏感词过滤,时间:%f,\n--源:【%s】\n--结果:【%s】", count, t3 - t2, text, r))
	local chars = string.ConvertToCharArray(text)
	t2 = os.clock()
	for i=1,count do
		chars = zmatch:_FilterSingleChars(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词过滤,时间%f", count, t3 - t2))

	t2 = os.clock()
	for i=1,count do
		chars = zmatch:_FilterMultiChars(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词过滤,时间%f", count, t3 - t2))
end


InitTestEnvironment()
-- 测试敏感词检测
TestCheck("正常说一句话的内容,大概这么长", 1000, 10)
TestCheck("敏感词:苍井空-", 1000, 10)
TestCheck("带&敏感词:-咳咳井空苍-", 1000, 10)
local textString = [[长字符串: 苍天有井独自空, 星落天川遥映瞳。
小溪流泉映花彩, 松江孤岛一叶枫。
南海涟波潭边杏, 星空野尽明日辉
西塞山野雁自翔, 小桥水泽浸芳园。
武园枯藤空留兰, 李氏眉宇尽是春。]]
-- local textString = ""
TestCheck(textString, 1000, 10)
TestFilter("心如苍井空似水,意比松岛枫叶飞。窗外武藤兰花香, 情似饭岛爱相随。咳咳dasdad井空苍苍, 台台ott", 1000, 1)