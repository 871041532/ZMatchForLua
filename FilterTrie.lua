-- 说明: 类似王者荣耀那种敏感词替换, 目前只支持单个词, 带&词替换等待后续扩展
require("PreLoad")
local Trie = require("Trie")
local FilterTrie = class("FilterTrie")

function FilterTrie:ctor(trie)
	self._trie = Trie.New()
	self._trie:BuildFromOtherTrie(trie)
	self._onceContex = nil
	self:__Init()
end

function FilterTrie:__Init()
	self._trie:SetExtCheckFunc(function(i,j)
		if not self._onceContex then
			self._onceContex = {}
		end
		table.insert(self._onceContex, {i,j})
		return false  -- 返回false视为没有匹配到, 继续迭代
	end)
end

-- 返回值1替换后的newChars,和参数是同一数组,是浅拷贝; 返回值2是否是敏感词被替换过
function FilterTrie:FilterChars(chars)
	self._onceContex = nil
	self._trie:CheckCharArrayMatched(chars)
	local newChars = chars
	local matched = false  -- 默认没有匹配到
	if self._onceContex then
		-- 有匹配到
		matched = true
		for _,v in ipairs(self._onceContex) do
			for i=v[1],v[2] do
				chars[i] = "*"  -- 默认替换为‘*’
			end
		end
	end
	return newChars, matched
end

-- 返回值1替换后的字符串, 返回值2是否被替换过(如果存在敏感词就会被替换掉)
function FilterTrie:FilterText(text)
	local chars = string.ConvertToCharArray(text)
	local newChars, matched = self:FilterChars(chars)
	local newText = text
	if matched then
		newText = table.concat(newChars)
	end
	return newText, matched
end

return FilterTrie