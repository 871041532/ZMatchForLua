-- 说明: 封装一下敏感词查找的接口
require("PreLoad")
require("SensitiveWordsCfg")
local Trie = require("Trie")
local FilterTrie = require("FilterTrie")
local MultiTrie = require("MultiTrie")
local ZMatch = class("ZMatch")

function ZMatch:ctor()
	-- 单个词验证
	self.singleTrie = Trie.New()
	self.singleCount = 0
	self.filterTrie = FilterTrie.New(self.singleTrie)
	-- 带有&符号的多词验证
	self._multiTrie = MultiTrie.New()
	self.multiList = {}  -- item是数组
	-- 原始配置表
	self.originCfg = nil
	self:__BuildCheckData()	
end

-- build check的data
function ZMatch:__BuildCheckData()
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
	-- BuildAC
	self.singleTrie:BuildAC()
end


-- &多词匹配方式使用
function ZMatch:__CheckMultiByTrie(text)
	return self._multiTrie:CheckTextMatched(text)
end

-- &多词匹配二,使用遍历法self._multiTrie:CheckTextMatched(text)
function ZMatch:__CheckMultiOld(text)
	-- print("step 2")
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

-- 单词匹配
function ZMatch:__CheckSingle(text)
	-- print("step 4")
	return self.singleTrie:CheckTextMatched(text)
end

-- 单词使用AC匹配
function ZMatch:__CheckSingleByAC(text)
	return self.singleTrie:CheckTextMatchedByAC(text)
end

-- 使用Trie匹配
function ZMatch:CheckByTrie(text)
	local chars = string.ConvertToCharArray(text)
	return self.singleTrie:CheckCharArrayMatched(chars) or self._multiTrie:CheckCharArrayMatched(chars)
end

-- 使用Tree

-- 使用Trie替换敏感词(暂时只有单个词的检测替换, 带&的多词后续添加)
function ZMatch:FilterText(text)
	return self.filterTrie:FilterText(text)
end

-- 遍历方式匹配
local sensitiveFunc = function(item)
	return string.split(item.word, "&")
end
function ZMatch:CheckByOldWay(text)
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
	t1 = os.clock()
	zmatch = ZMatch.New()
	t2 = os.clock()
	print("\n构建Trie耗时:", t2 - t1)
	local count = 0
	for _,_ in pairs(zmatch.originCfg) do
		count = count + 1
	end
	print("敏感词总量", count)
	print("常规词数量", zmatch.singleCount)
	print("带&词数量", #zmatch.multiList)
end

function ZMatch.TestCheck(text, newWayCount, oldWayCOunt)
	count = newWayCount  -- 此处输入新方式检测次数
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckByTrie(text)
	end
	t3 = os.clock()
	print(string.format("\n%d次trie查找【%s】总时间:%f,结果:%s", count, text, t3 - t2, r and "true" or "false"))
	t2 = os.clock()
	for i=1,count do
		r = zmatch:__CheckSingle(text)
	end
	t3 = os.clock()
	print(string.format("\t\t(1)常规单词数量%d, 查找时间:%f,结果:%s", zmatch.singleCount, t3 - t2, r and "true" or "false"))
	if r then
		print(string.format("\t\t(2)带&单词数量%d, 上步已确定是敏感词,不需要查找。", #zmatch.multiList))
	else
		t2 = os.clock()
		for i=1,count do
			r = zmatch:__CheckMultiByTrie(text)
		end
		t3 = os.clock()
		print(string.format("\t\t(2)带&词数量%d, MultiTrie查找时间:%f,结果:%s", #zmatch.multiList, t3 - t2, r and "true" or "false"))	
		t2 = os.clock()
		for i=1,count do
			r = zmatch:__CheckMultiOld(text)
		end
		t3 = os.clock()
		print(string.format("\t\t(3)带&词如用遍历方式, 查找时间:%f,结果:%s", t3 - t2, r and "true" or "false"))
	end

	count = oldWayCOunt  -- 此处输入遍历方式检测次数
	t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckByOldWay(text)
	end
	t3 = os.clock()
	print(string.format("%d次遍历查找【%s】时间:%f,结果:%s", count, text, t3 - t2, r and "true" or "false"))
end

function ZMatch.TestCheckByAC(text, count)
	count = count  -- 此处输入遍历方式检测次数
	t2 = os.clock()
	for i=1,count do
		r = zmatch:__CheckSingleByAC(text)
	end
	t3 = os.clock()
	print(string.format("%d次AC自动机查找【%s】时间:%f,结果:%s", count, text, t3 - t2, r and "true" or "false"))
end

function ZMatch.TestFilter(text, newWayCount, oldWayCOunt)
	count = newWayCount
	t2 = os.clock()
	for i=1,count do
		r = zmatch:FilterText(text)
	end
	t3 = os.clock()
	print(string.format("\n%d次trie过滤,时间:%f,源:【%s】结果:【%s】", count, t3 - t2, text, r))
end

return ZMatch