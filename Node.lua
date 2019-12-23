-- 说明: Trie上的一个节点
require("PreLoad")

local Node = {}
Node.__index = Node

function Node.New()
	local newObj = {}
	setmetatable(newObj, Node)
	return newObj
end

function Node:ctor()
	self._isWord = false  
	self._children = nil  -- 是k,v结构 childChar = ChildNode
	self._failNode = nil  -- 失败指针
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

function Node:GetChildren()
	return self._children
end

function Node:MarkAsWord(b)
	self._isWord = b
end

-- 是否为单词
function Node:IsWord()
	return self._isWord
end

-- 下面是新增的AC自动机接口
-- 设置失败指针，lua没有内联优化，后面考虑属性public
function Node:SetFailNode(node)
	self._failNode = node
end

-- 获取失败指针，如上，考虑属性public
function Node:GetFailNode()
	return self._failNode
end

-- BFS广度优先构建失败指针
function Node:BuildFailNode(root)
	if self == root then
		self:SetFailNode(nil)
		for _,v in pairs(self._children) do
			v:SetFailNode(root)
		end
	end
	for k,v in pairs(table_name) do
		print(k,v)
	end
end

return Node