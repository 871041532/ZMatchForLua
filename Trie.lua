-- 说明: 最原始的trie,提供不带&词的匹配。
require("PreLoad")

local Queue = require("Queue")
local Node = require("Node")
local Trie = class("Trie")

function Trie:ctor()
	self._root = Node.New()
	self._extCheckFunc = nil
end

-- 拷贝构造函数
function Trie:CopyConstruction(otherTrie)
	self._root = otherTrie._root
	-- _extCheckFunc不设置，可以让本对象去定制
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
			local childNode = node._children and node._children[char]
			-- print("开始判断字符:", char)
			if childNode then
				if childNode._isWord and (not self._extCheckFunc or self._extCheckFunc(i, j)) then
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

------------------------ 下面是新增的AC自动机优化-----------------------------
-- 不影响上面逻辑，仍然可以使用上面接口进行朴素匹配
-- 创建AC自动机, 要想使用AC相关接口，必须要先BuildAC
-- BuildAC会有额外时间消耗，对于短字符串来说没必要使用AC
function Trie:BuildAC()
	local queue = Queue.New()
	local node
	local children
	self._root:SetFailNode(nil)
	queue:Enqueue(self._root)
	while queue:NotEmpty() do
		node = queue:Dequeue()
		-- 处理到某个node节点，所做操作是：将它的子节点一一设置FailNode
		children = node:GetChildren()
		if children then
			for _,child in pairs(children) do
				queue:Enqueue(child)  -- 此句广度优先遍历树的通用模式
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

-- 使用AC自动机检测数组：for循环法
-- 脚本语言没有内联，只能暴力手动内联了
function Trie:CheckCharArrayMatchedByAC(chars)
	local node = self._root
	local char
	local child
	for i=1,#chars do
		char = chars[i]
		child = node._children and node._children[char]
		if not child then
			-- 没有child则使用Fail指针回溯查找
			while not child and node do
				node = node._failNode
				child = node and node._children and node._children[char]
			end
		end
		-- 有child则将node设置为child，没有child则设为root
		node = child or self._root
		if child and child._isWord then
			return true
		end
	end
	return false
end

return Trie