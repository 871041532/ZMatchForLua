-- 说明: 专门用于带&单词的检测, 带&的检测规则是split之后所有item都是text的子串

require("PreLoad")
local Trie = require("Trie")
local MultiTrie = class("MultiTrie")

-- 自增每次检测 +1
MultiTrie.checkIdx = 0

function MultiTrie:ctor()
	self._trie = nil
	self._wordTileMap = nil
	self._WordTileList = nil
	self._curCheckChars = nil
	self._curCheckKeyCache = nil  -- 当前查找key的cache
	self:Init()
end

function MultiTrie:Init()
	-- 每个item的数据结构, 
	-- singleWord = {
	-- 	{
	-- 		word1 = 0,
	-- 		word2 = 0, 
	-- 		word3 = 0, 
	-- 		word4 = 0,
	-- 		__num = 4,
	-- 		__curMatchNum = 0,
	-- 	}, 
	-- 	{
	-- 		word1 = 0, 
	-- 		word2 = 0, 
	-- 		word3 = 0,
	-- 		__num = 3,
	-- 		__curMatchNum = 0,
	-- 	}
	-- }
	-- 单个word对应的一个list
	self._wordTileMap = {} 
	self._WordTileList = {}
	self._trie = Trie.New()
	self._trie:SetExtCheckFunc(function(i,j)
		local key = nil
		local idx = i*100 + j
		key = self._curCheckKeyCache[idx]
		if not key then
			local chars = {}
			for p=i,j do
				table.insert(chars, self._curCheckChars[p])
			end
			key = table.concat(chars)
			self._curCheckKeyCache[idx] = key
		else
			print("复用key")
		end
		local setList = self._wordTileMap[key]
		for _,v in pairs(setList) do
			if v[key] ~= MultiTrie.checkIdx then
				v[key] = MultiTrie.checkIdx
				v.__curMatchNum = v.__curMatchNum + 1
				if v.__curMatchNum == v.__num then
					return true
				end
			end
		end
	end)
end

-- worldList是经过split之后的string数组, 视为一组数据
function MultiTrie:AddWordsItem(wordArray)
	local wordSet = {}
	local num = 0
	for _,v in ipairs(wordArray) do
		self._trie:AddWord(v)
		if not wordSet[v] then
			-- 去掉重复的词
			wordSet[v] = 0
			num = num + 1
		end
	end
	self:__AddToTiledMap(wordSet, num)
	table.insert(self._WordTileList, wordSet)
end

function MultiTrie:__AddToTiledMap(wordSet, num)
	for k,v in pairs(wordSet) do
		local temp = self._wordTileMap[k]
		if not temp then
			temp = {}
			self._wordTileMap[k] = temp
		end
		table.insert(temp, wordSet)
	end
	wordSet.__num = num
	wordSet.__curMatchNum = 0
end

function MultiTrie:__ResetTiledMap()
	for i=1,#self._WordTileList do
		self._WordTileList[i].__curMatchNum = 0
	end
end

function MultiTrie:CheckCharArrayMatched(chars)
	MultiTrie.checkIdx = MultiTrie.checkIdx + 1
	self._curCheckKeyCache = {}
	self._curCheckChars = chars
	local result = self._trie:CheckCharArrayMatched(chars)  -- 千次0.25
	self._curCheckChars = nil
	self:__ResetTiledMap()  -- 重置千次 0.041
	return result
end

function MultiTrie:CheckTextMatched(text)
	local chars = string.ConvertToCharArray(text)  -- 千次 0.028
	return self:CheckCharArrayMatched(chars)
end

return MultiTrie

