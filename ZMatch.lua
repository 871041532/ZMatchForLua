-- 说明: 封装一下敏感词查找的接口
require("PreLoad")
require("SensitiveWordsCfg")
local Trie = require("Trie")
local FilterTrie = require("FilterTrie")
local MultiTrie = require("MultiTrie")
local MultiFilterTrie = require("MultiFilterTrie")

local ZMatch = class("ZMatch")

function ZMatch:ctor()
	-- 单个词验证
	self.singleTrie = Trie.New()
	self.singleCount = 0
	self.filterTrie = FilterTrie.New(self.singleTrie)
	-- 带有&符号的多词验证
	self._multiTrie = MultiTrie.New()
	-- 带有&符号的多词过滤
	self._multiFilterTrie = MultiFilterTrie.New(self._multiTrie)
	self.multiList = {}  -- item是数组
	-- 原始配置表
	self.originCfg = nil

	self._havenBuildTrie = false
	self._havenBuildAc = false
end

-- build check的data
function ZMatch:BuildTrie()
	if self._havenBuildTrie then
		return
	end
	self._havenBuildTrie = true

	self.originCfg = g_SensitiveWordsCfg
	for k,v in pairs(self.originCfg) do
		local strings = string.split(v.word, "&")
		if #strings > 1 then
			table.insert(self.multiList, strings)
			self._multiTrie:AddWordsItem(strings)
		else
			self.singleCount = self.singleCount + 1
			self.singleTrie:AddWord(strings[1])
		end
	end
end

-- build AC
function ZMatch:BuildAC()
	if self._havenBuildAc then
		return
	end
	if not self._havenBuildTrie then
		return
	end
	self._havenBuildAc = true
	-- BuildAC
	self.singleTrie:BuildAC()
end

-- &多词匹配:使用trie
function ZMatch:CheckMultiByTrie(chars)
	return self._multiTrie:CheckCharArrayMatched(chars)
end

-- &多词匹配:使用遍历 
function ZMatch:CheckMultiByTraverse(text)
	local list = self.multiList
	for _, item in ipairs(list) do
		local m = true
		for _, w in ipairs(item) do
			if not string.find(text, w, 1, true) then
				-- print("step 3")
				m = false
				break
			end
		end
		if m then
			return true
		end
	end
end

-- 单词匹配:使用Trie
function ZMatch:CheckSingleByTrie(chars)
	return self.singleTrie:CheckCharArrayMatched(chars)
end

-- 单词匹配:使用AC
function ZMatch:CheckSingleByAC(chars)
	return self.singleTrie:CheckCharArrayMatchedByAC(chars)
end

-- 通用的接口, 内部根据具体情况选择最优匹配算法
function ZMatch:CheckText(text)
	local chars = string.ConvertToCharArray(text)
	return self.singleTrie:CheckCharArrayMatchedByAC(chars) or self._multiTrie:CheckCharArrayMatched(chars)
end

-- 使用Trie替换敏感词(暂时只有单个词的检测替换, 带&的多词后续添加)
function ZMatch:FilterText(text)
	local chars = string.ConvertToCharArray(text)
	local chars, matched1 = self.filterTrie:FilterChars(chars)
	local chars, matched2 = self._multiFilterTrie:FilterChars(chars)
	local matched = matched1 or matched2
	if matched then
		return table.concat(chars), true
	end
	return text, false
end

-- 带&词过滤
function ZMatch:FilterMultiChars(chars)
	return self._multiFilterTrie:FilterChars(chars)
end

-- 非&词过滤
function ZMatch:FilterSingleChars(chars)
	return self.filterTrie:FilterChars(chars)
end

-- 直接使用遍历的方式匹配所有的
local sensitiveFunc = function(item)
	return string.split(item.word, "&")
end
function ZMatch:CheckAllByTraverse(text)
	local sheet = self.originCfg
	for _, item in pairs(sheet) do
		local m = true
		for _, w in ipairs(sensitiveFunc(item)) do
			if not string.find(text, w, 1, true) then
				m = false
				break
			end
		end
		if m then
			return true
		end
	end
	return false
end

------------------------------下面全是测试代码,正式使用的时候可以删掉----------------------------

local zmatch
local t1
local t2
local t3
local count
local r
function ZMatch.InitTestEnvironment()
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
function ZMatch.TestCheck(text, newWayCount, oldWayCOunt)
	print(string.format("\n\n开始对【%s】进行敏感词检测...", text))
	printLine()
	count = oldWayCOunt
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckAllByTraverse(text)
	end
	t3 = os.clock()
	print(string.format("老接口%d次全词检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	count = newWayCount
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckText(text)
	end
	t3 = os.clock()
	print(string.format("最终接口%d次全词检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	printLine()
	local chars = string.ConvertToCharArray(text)
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckSingleByTrie(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词Trie检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckSingleByAC(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词AC检测,时间:%f,结果:%s", count, t3 - t2, r and "true" or "false"))
	printLine()
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckMultiByTrie(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词Trie检测,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckMultiByTraverse(text)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词遍历检测,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
end

function ZMatch.TestFilter(text, newWayCount, oldWayCOunt)
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
		chars = zmatch:FilterSingleChars(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词过滤,时间%f", count, t3 - t2))

	t2 = os.clock()
	for i=1,count do
		chars = zmatch:FilterMultiChars(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词过滤,时间%f", count, t3 - t2))
end

return ZMatch