-- 说明: 类似王者荣耀那种敏感词替换, 多词替换
require("PreLoad")
local MultiTrie = require("MultiTrie")

local MultiFilterTrie = class("MultiFilterTrie")

function MultiFilterTrie:ctor(multiTrie)
	self._trie = MultiTrie.New()
	self._trie:CopyConstruction(multiTrie)
	self._onceContex = nil
	self:__Init()
end

function MultiFilterTrie:__Init()
	self._trie:SetExtCheckFunc(function(indexArray)
		if not self._onceContex then
			self._onceContex = {}
		end
		table.insert(self._onceContex, indexArray)
		return false  -- 返回false视为没有匹配到, 继续迭代
	end)
end

-- 返回值1替换后的newChars,和参数是同一数组,是浅拷贝; 返回值2是否是敏感词被替换过
function MultiFilterTrie:FilterChars(chars)
	self._onceContex = nil
	self._trie:CheckCharArrayMatched(chars)
	local newChars = chars
	local matched = false  -- 默认没有匹配到
	if self._onceContex then
		-- 有匹配到
		matched = true
		for _,v in ipairs(self._onceContex) do
			local count = #v / 2
			for i=1,count do
				local v1 = v[2*i-1]
				local v2 = v[2*i]
				for j=v1,v2 do
					chars[j] = "*"  -- 默认替换为‘*’
				end
			end
		end
	end
	return newChars, matched
end

-- 返回值1替换后的字符串, 返回值2是否被替换过(如果存在敏感词就会被替换掉)
function MultiFilterTrie:FilterText(text)
	local chars = string.ConvertToCharArray(text)
	local newChars, matched = self:FilterChars(chars)
	local newText = text
	if matched then
		newText = table.concat(newChars)
	end
	return newText, matched
end

return MultiFilterTrie