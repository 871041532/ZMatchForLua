-- 说明: Trie上的一个节点
require("PreLoad")

local Node = class("TrieNode")

function Node:ctor(char)
	self._isWord = false  
	self._children = nil  -- 是k,v结构 childChar = ChildNode
	self.char = char
end

function Node:AddChild(char)
	if not self._children then
		self._children = {}
	end
	local child = Node.New(char)
	self._children[char] = child
	return child
end

function Node:GetChild(char)
	if self._children then
		return self._children[char]
	end
end

function Node:MarkAsWord(b)
	self._isWord = b
end

-- 是否为单词
function Node:IsWord()
	return self._isWord
end

return Node