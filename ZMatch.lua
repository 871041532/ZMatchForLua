-- 说明: 封装一下敏感词查找的接口
require("PreLoad")
-- if not gdSensitiveWordsSensitiveWords then
-- 	require("SensitiveWordsCfg")
-- end
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
	self.originCfg = {}

	self._havenBuildTrie = false
	self._havenBuildAc = false
	self.multiItemCount = 0
end

-------------------外部Trie查找接口---------------------------
-- 必须先BuildTrie再check或filter才有效
function ZMatch:BuildTrie(cfgs)
	if self._havenBuildTrie then
		return
	end
	self._havenBuildTrie = true

	self.originCfg = cfgs or gdSensitiveWordsSensitiveWords
	for _,v in ipairs(self.originCfg) do
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

-- 根据新的规则重新构建构建MultiTree
function ZMatch:ReBuildExtMultiTree(cfgs)
	for _,v in ipairs(cfgs) do
		local chars = string.ConvertToCharArray(v)
		self._multiTrie:AddWordsItem(chars)
		self.multiItemCount = self.multiItemCount + 1
	end
end

function ZMatch:BuildTreeByOfflineData(offlineData)
	if self._havenBuildTrie then
		return
	end
	self._havenBuildTrie = true

	self.singleTrie = Trie.New()
	self.singleTrie._root = offlineData.singleTrieRoot
	self.filterTrie = FilterTrie.New(self.singleTrie)

	-- self._multiTrie = MultiTrie.New()
	-- self._multiTrie._trie._root = offlineData.multiTrieRoot
	-- self._multiTrie._wordTileMap = offlineData.multiWordTileMap
	-- self._multiTrie._WordTileList = offlineData.multiWordTileList
	-- self._multiFilterTrie = MultiFilterTrie.New(self._multiTrie)
end

function ZMatch:GetOffLineData()
	local singleTrieRoot = self.singleTrie._root
	local multiTrieRoot = self._multiTrie._trie._root
	local multiWordTileMap = self._multiTrie._wordTileMap
	local multiWordTileList = self._multiTrie._WordTileList
	local offlineData = {
		singleTrieRoot = singleTrieRoot,
		-- multiTrieRoot = multiTrieRoot,
		-- multiWordTileMap = multiWordTileMap,
		-- multiWordTileList = multiWordTileList,
	}
	return offlineData
end

-- 通用接口, 使用Trie检测屏蔽字
function ZMatch:CheckText(text)
	local chars = string.ConvertToCharArray(text)
	return self.singleTrie:CheckCharArrayMatched(chars) or self._multiTrie:CheckCharArrayMatched(chars)
end

-- 通用接口, 过滤敏感词
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
--------------------------------------------------------------------------------


--------------------------------外部AC查找接口------------------------------------
-- 必须在BuildTrie之后再调用BuildAC, 然后再CheckTextByAC才有效
-- 为什么要独立出来? AC构建的时候会消耗额外时间,短字符串查找没必要使用
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

-- 通用的接口, 使用AC检测屏蔽字
function ZMatch:CheckTextByAC(text)
	local chars = string.ConvertToCharArray(text)
	return self.singleTrie:CheckCharArrayMatchedByAC(chars) or self._multiTrie:CheckCharArrayMatched(chars)
end
----------------------------------------------------------------------------------


------------------------下面是一些方便测试用的接口,可有可无---------------------------
-- &多词匹配:使用trie
function ZMatch:_CheckMultiByTrie(chars)
	return self._multiTrie:CheckCharArrayMatched(chars)
end

-- &多词匹配:使用遍历 
function ZMatch:_CheckMultiByTraverse(text)
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
function ZMatch:_CheckSingleByTrie(chars)
	return self.singleTrie:CheckCharArrayMatched(chars)
end

-- 单词匹配:使用AC
function ZMatch:_CheckSingleByAC(chars)
	return self.singleTrie:CheckCharArrayMatchedByAC(chars)
end

-- 带&词过滤
function ZMatch:_FilterMultiChars(chars)
	return self._multiFilterTrie:FilterChars(chars)
end

-- 非&词过滤
function ZMatch:_FilterSingleChars(chars)
	return self.filterTrie:FilterChars(chars)
end

-- 直接使用遍历的方式匹配所有的
local sensitiveFunc = function(item)
	return string.split(item.word, "&")
end
function ZMatch:_CheckAllByTraverse(text)
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
-----------------------------------------------------------------

return ZMatch