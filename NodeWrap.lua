-- 说明: Trie上的一个节点
require("PreLoad")

local NodeWrap = {}

function NodeWrap.New()
	-- [1] _children
	-- [2] _isWord
	local handle = {}
	return handle
end

function NodeWrap.AddChild(handle, char)
	if not handle[1] then
		handle[1] = {}
	end
	local child = NodeWrap.New()
	handle[1][char] = child
	return child
end

function NodeWrap.GetChild(handle, char)
	if handle[1] then
		return handle[1][char]
	end
end

function NodeWrap.GetChildren(handle)
	return handle[1]
end

function NodeWrap.MarkAsWord(handle, b)
	handle[2] = b
end

-- 是否为单词
function NodeWrap.IsWord(handle)
	return handle[2]
end

return NodeWrap