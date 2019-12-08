-- 说明: 最原始的trie,提供不带&词的匹配。
require("PreLoad")

local Node = require("Node")
local Trie = class("Trie")

function Trie:ctor()
	self._root = Node.New()
	self._extCheckFunc = nil
end

-- 使用otherTrie的检索数据作为自己的数据
function Trie:BuildFromOtherTrie(otherTrie)
	self._root = otherTrie._root
end

-- 当一个node匹配为word时, 可能需要额外check才能确认是敏感词
-- func两个参数i,j
function Trie:SetExtCheckFunc(func)
	self._extCheckFunc = func
end

function Trie:AddWord(word)
	local chars = string.ConvertToCharArray(word)
	local node = self._root
	for i, char in ipairs(chars) do
		local child = node:GetChild(char)
		if not child then
			child = node:AddChild(char)
		end
		if i == #chars then
			-- 单词的最后一个字标记为单词
			child:MarkAsWord(true)
		end
		node = child
	end
end

function Trie:CheckTextMatched(text)
	local chars = string.ConvertToCharArray(text)
	return self:CheckCharArrayMatched(chars)
end

function Trie:CheckCharArrayMatched(chars)
	local isSensitive = false
	-- 用双重循环代替初版的双重IterFunc，节省点堆栈调用
	for i=1,#chars do
		-- print("开始迭代子串,起始位置:",chars[i])
		local node = self._root
		local suiteded = false  -- 默认为false表示text遍历完,trie上还没有对应的word
		for j=i,#chars do	
			-- 内层循环
			local char = chars[j]
			local childNode = node:GetChild(char)
			-- print("开始判断字符:", char)
			if childNode then
				if childNode:IsWord() and (not self._extCheckFunc or self._extCheckFunc(i, j)) then
					-- print("在trie的叶节点或茎节点找到了子串", childNode.char)
					suiteded = true
					break
				else
					-- print("trie上存在下个匹配字:", childNode.char)
					node = childNode
				end
			else
				-- print("trie不存在下个匹配字", char)
				break
			end
		end
		-- 匹配到了
		if suiteded then
			-- print("suiteded 匹配到了")
			isSensitive = true
			break
		end
		-- print("not suiteded,开始下次迭代")
	end
	-- print(string.format("迭代完毕结果是:%s\n", isSensitive and "true" or "false"))
	return isSensitive
end

return Trie