-- 说明: 最原始的trie,提供不带&词的匹配。
require("PreLoad")

local Queue = require("Queue")
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

-- 下面是新增的AC自动机优化
-- 不影响上面逻辑，仍然可以使用上面接口进行朴素匹配, 酌情使用
-- 创建AC自动机, 要想使用AC相关接口，必须要先BuildAC
function Trie:BuildAC()
	local queue = Queue.New()
	self._root:SetFailNode(nil)
	queue:Enqueue(self._root)
	while queue:NotEmpty() do
		local node = queue:Dequeue()
		local children = node:GetChildren()
		if children then
			for _,child in pairs(children) do
				queue:Enqueue(child)  -- 这句是广度优先遍历树的通用模式
				if node == self._root then
					-- 根节点
					child:SetFailNode(node)
				else
					local failNode = node:GetFailNode()  -- 此处不必判空node必定有faileNode
					local matchNode = failNode:GetChild(child.char)
					if matchNode then
						child:SetFailNode(matchNode)
					else
						local search = true
						while search do
							failNode = failNode:GetFailNode()
							if failNode then
								matchNode = failNode:GetChild(child.char)
								if matchNode then
									child:SetFailNode(matchNode)
									search = false
								end
							else
								-- 一直找不到failNode
								child:SetFailNode(self._root)
								search = false
							end
						end
					end
				end
			end
		end
	end
end

-- 使用AC自动机检测文本
function Trie:CheckTextMatchedByAC(text)
	local chars = string.ConvertToCharArray(text)
	return self:CheckCharArrayMatchedByAC(chars)
end

-- 使用AC自动机检测数组
function Trie:CheckCharArrayMatchedByAC(chars)
	local node = self._root
	local i = 1
	local count = #chars
	while i <= count do
		if node:IsWord() then
			return true
		end
		local char = chars[i]
		local child = node:GetChild(char)
		if child then
			node = child
			i = i + 1
		else
			local failNode = node:GetFailNode()
			if failNode then
				node = failNode
			else
				i = i + 1
			end
		end
	end
	return false
end

return Trie