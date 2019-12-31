require("Preload")
local Tool = require("DATTool")

local DAT = finalClass("DoubleArrayTrie")

function DAT:ctor()
	self.charSet = {}  -- 字符集编码
	self.base = {1}  -- base数组,存的数据称为offset,并不都是有效状态会有浪费
	self.check = {1}  -- check数组,存的数据是父状态的索引，即base中的索引
	self.tail = {}  -- tail数组存储公共后缀
	self.endCode = 0  -- 结束符 #  count+1
	self.sliceCode = 0  -- 分割符 $ count + 2
	self.nilCode = 0  -- 空的字符编码count + 3（字符集中不存在的字符都用这个编码）

	---------------------- 动态构建时用的,离线构建不用 ----------------------------
	self.charArray = {} -- 存放所有字的数组, 按照出现频率倒叙排序
	self.charTimes = {} -- k char v times charSet中char出现的频率，排序用的

	self.failType = 1 -- 1在leader中失配，2在tail中长度小于匹配字， 失败类型3，长度一致某个字符失配
	-- 失败类型1
	self.failR = 0  --失配字符leader在base中的索引
	self.failT = 0   -- 失配字符在base中的索引，base[leaderIndex] + 字符编码
	self.failCharIndex = 0  -- 失配的字符在char数组中的索引
	-- 失败类型2
	self.failArrayIndex = 0  -- 失败的最后那个leader节点，在数组中的索引
	self.failTailStartIndex = 0  -- 失败的节点在tail中的起始位置
	self.failTailLength = 0  -- 失败的节点在tail中的长度
	-- 失败类型3专用（类型2的那些字段也用到了）
	self.failTailOffsetIndex = 0  -- 失败节点的偏移量，从1开始
	-- 当前的inputstartIndex
end

function DAT:GetOfflineData()
	return {
		base = self.base,
		check = self.check,
		tail = self.tail,
		endCode = self.endCode,
		sliceCode = self.sliceCode,
		nilCode = self.nilCode,
		charSet = self.charSet,
	}
end

function DAT:BuildBuyOfflineData(offlineData)
	self.base = offlineData.base
	self.check = offlineData.check
	self.tail = offlineData.tail
	self.endCode = offlineData.endCode
	self.sliceCode = offlineData.sliceCode
	self.nilCode = offlineData.nilCode
	self.charSet = offlineData.charSet
end

-- 检测文本
function DAT:CheckText(text)
	local chars = string.ConvertToCharArray(text)
	local encodes = Tool.ConvertCharArrayToEncodeArray(self.charSet, chars, self.nilCode)
	return self:_MatchAllSubByEncodes(encodes)
end

-- 获取tail中start开始的字符串长度
function DAT:_getTailCodeLength(startIndex)
	local length = 0
	for i=startIndex, #self.tail do
		if self.tail[i] == self.sliceCode then
			break
		end
		length = length + 1
	end
	return length
end

-- 扩充Base数组和Check数组
function DAT:_ExpandBaseAndCheck(count)
	if count == nil or count < 0 then
		-- print("_ExpandBaseAndCheck错误的count参数：", count)
		return
	end
	if count > #self.base then
		for i=#self.base + 1,count do
			self.base[i] = 0
		end
	end
	if count > #self.check then
		for i=#self.check + 1,count do
			self.check[i] = 0
		end
	end
	-- self.check[1] = #self.base
end

-- 核心函数，获取可用的offset数组
function DAT:_GetVaildTailOffset(childrenCode)
	local offset = 1
	local found = false
	while not found do
		local ok = true
		for _,v in ipairs(childrenCode) do
			local targetIndex = offset + v
			self:_ExpandBaseAndCheck(targetIndex)
			if self.check[targetIndex] ~= 0 then
				ok = false
				break
			end
		end
		if ok then
			found = true
		else
			offset = offset + 20
		end
	end
	return offset
end

-- 左移，起始index，总长度，左移偏移量1 6 2
function DAT:_LeftShiftTail(startIndex, length, offset)
	for i = startIndex, startIndex + length - offset - 1 do
		local index = i + offset
		self.tail[i] = self.tail[i + offset]	
	end
	for i = startIndex + length - offset, startIndex + length - 1 do
		self.tail[i] = self.sliceCode
	end
end

-- 获取某Index的全部子节点
function DAT:_GetChildren(fatherIndex)
	local children = {}
	for i,v in ipairs(self.check) do
		if v == fatherIndex and i ~= 1 then
			table.insert(children, i)
		end
	end
	return children
end

-- 将某个节点的所有子节点的父节点都设置为新值
function DAT:_ChangeChildrenFather(oldFather, newFather)
	for i=1,#self.check do
		if self.check[i] == oldFather then
			self.check[i] = newFather
		end
	end
end

-- 处理冲突，自行移动。index位置将要插入新元素，需要解决冲突
function DAT:_ResolvedCheckConflict(leaderIndex, conflictIndex)
	-- 判断移动leader需要移动几个元素
	local newCode = conflictIndex - self.base[leaderIndex]
	local children = self:_GetChildren(leaderIndex)
	-- 判断移动冲突confiltcIndex需要移动几个元素
	local conflictLeader = self.check[conflictIndex]
	local conflictChildren = self:_GetChildren(conflictLeader)
	if #children < #conflictChildren then
	-- if false then
		-- 使用第一种移动方式, 移动当前节点的父节点，解决冲突
		local childrenCode = {}
		for _,v in ipairs(children) do
			local code = v - self.base[self.check[v]] 
			table.insert(childrenCode, code)
		end
		table.insert(childrenCode, newCode)
		local vaildOffset = self:_GetVaildTailOffset(childrenCode)
		self.base[leaderIndex] = vaildOffset
		for i=1,#children do
			-- 将当前节点移动位置
			local curIndex = children[i]
			local childCode = childrenCode[i]
			local baseValue1 = self.base[curIndex]
			local checkValue1 = self.check[curIndex]
			local targetIndex = vaildOffset + childCode
			self.base[targetIndex] = baseValue1
			self.check[targetIndex] = checkValue1
			self.base[curIndex] = 0
			self.check[curIndex] = 0
			-- 将当前节点的子节点的父节点，指向新位置
			self:_ChangeChildrenFather(curIndex, targetIndex)
		end
	else
		-- 使用第二种方式，移动conflictIndex所在节点index，兄弟节点index，以及父节点base值
		local conflictChildrenCode = {}
		for _,v in ipairs(conflictChildren) do
			local code = v - self.base[self.check[v]] 
			if code < 0 then
				print("发生错误，出现负数", v, self.base[self.check[v]])
			end
			table.insert(conflictChildrenCode, code)
		end
		local vaildOffset = self:_GetVaildTailOffset(conflictChildrenCode)
		self.base[conflictLeader] = vaildOffset
		for i=1,#conflictChildren do
			-- 将当前节点移动位置
			local curIndex = conflictChildren[i]
			local childCode = conflictChildrenCode[i]
			local baseValue1 = self.base[curIndex]
			local checkValue1 = self.check[curIndex]
			local targetIndex = vaildOffset + childCode
			self.base[targetIndex] = baseValue1
			self.check[targetIndex] = checkValue1
			self.base[curIndex] = 0
			self.check[curIndex] = 0
			-- 将当前节点的子节点的父节点指针，指向新位置
			self:_ChangeChildrenFather(curIndex, targetIndex)
		end

	end
end

-- 添加一个EncodesItem
function DAT:_AddEncodesItem(intputCode)
	-- 这个字符串本来就是屏蔽字，什么都不做
	if self:_MatchAllSubByEncodes(intputCode) then
		return
	end
	if self.failType == 1 then
		-- 在base中失配
		-- if self.failT < 0 then
		-- 	print("failT小于0：", self.failT)
		-- end
		self:_ExpandBaseAndCheck(self.failT)
		if self.check[self.failT] == 0 then
			-- 此处check是空的可以直接插入
			self.base[self.failT] = -(#self.tail + 1)
			self.check[self.failT] = self.failR
			for i=self.failCharIndex + 1, #intputCode + 1 do
				self.tail[#self.tail + 1] = intputCode[i] or self.endCode
			end
			self.tail[#self.tail + 1] = self.sliceCode
		else
			-- 此处check不为空，需要处理冲突
			-- print("此处check不为空，需要处理冲突")
			self:_ResolvedCheckConflict(self.failR, self.failT)
			return true
		end
	elseif self.failType == 2 then
		-- 在tail中因为长度太短失配
		-- 没有共同前缀
		local code1 = intputCode[self.failArrayIndex + 1] or self.endCode
		local code2 = self.tail[self.failTailStartIndex]
		-- print(code1, code2)
		if code1 ~= code2 then
			local offset = self:_GetVaildTailOffset({code1, code2})
			-- 设置父状态的offset
			self.base[self.failR] = offset
			-- 设置子状态的check
 			self.check[offset + code1] = self.failR
			self.check[offset + code2] = self.failR
			-- 修改tail数组
			self:_LeftShiftTail(self.failTailStartIndex, self.failTailLength + 1, 1)  -- 分割符$也要偏移
			local startIndex = #self.tail + 1
			for i=self.failArrayIndex + 2, #intputCode + 1 do
				self.tail[#self.tail + 1] = intputCode[i] or self.endCode
			end
			self.tail[#self.tail + 1] = self.sliceCode
			-- 设置子状态的offset
			self.base[offset + code1] = -startIndex
			self.base[offset + code2] = -self.failTailStartIndex
		else
			-- print("发生错误：tail中有共同前缀，这种情况尚未处理！")
			local curFather = self.failR
			for i=1,self.failTailOffsetIndex do
				local code1 = intputCode[self.failArrayIndex + i] or self.endCode
				local code2 = self.tail[self.failTailStartIndex + i -1]
				local offset = self:_GetVaildTailOffset({code1, code2})
				-- 设置父状态的offset
				self.base[curFather] = offset
				-- 设置子状态的check
 				self.check[offset + code1] = curFather
				self.check[offset + code2] = curFather
				curFather = offset + code1
				-- 设置子状态的offset
				local startIndex = #self.tail + 1	
				self.base[offset + code1] = -startIndex
				self.base[offset + code2] = -self.failTailStartIndex
			end
			-- 修改tail数组
			-- print("xxxx:",self.failTailStartIndex, self.failTailLength + 1, self.failTailOffsetIndex)
			self:_LeftShiftTail(self.failTailStartIndex, self.failTailLength + 1, self.failTailOffsetIndex)  -- 分割符$也要偏移
			-- 为新增数据设置tail
			for i=self.failArrayIndex + self.failTailOffsetIndex + 1, #intputCode + 1 do
				self.tail[#self.tail + 1] = intputCode[i] or self.endCode
			end
			self.tail[#self.tail + 1] = self.sliceCode
		end
	end

	-- self:_PrintBaseCheckTail()
end

-- 遍历检测所有的inputcode
function DAT:_MatchAllSubByEncodes(inputCode)
	for i=#inputCode,1,-1 do
		if self:_MatchByEncodes(inputCode, i) then
			return true
		end
	end
	return false
end

function DAT:_MatchByEncodes(intputCode, startIdx)
	self.failInputStartIndex = startIdx
	local r = 1
	local h = 0
	while true do
		local code = intputCode[h + startIdx] or self.endCode
		local t = self.base[r] + code  --intputCode[h + 1]
		if self.check[t] ~= r then
			self.failType = 1
			self.failR = r  --失配字符leader在base中的索引
			self.failCharIndex = h+1  -- 失配的字符在char数组中的索引
			self.failT = t   -- 失配字符在base中的索引，base[leaderIndex] + 字符编码
			-- print("r h+1 t",r, h+1, t)
			-- print("false type:1")
			return false
		else
			r = t
		end
		h = h + 1
		if not (self.base[r] > 0) then
			break
		end
	end
	-- print("rh:",r,h)
	-- 此时h表示当前的节点是带trie的蓝色节点
	local lastLength1 = #intputCode - startIdx + 2 - h
	local tailIndex = -self.base[r]
	local lastLength2 = self:_getTailCodeLength(tailIndex)
	-- print("length12",lastLength1, lastLength2)
	-- 生成时没有进行optimize优化，此处兼容一下
	if lastLength1 == 0 and lastLength2 ==0 then
		-- print("true1")
		return true
	end
	local i = 1
	local matched = true
	local optimize = true  -- 目前阶段optimize必须为true，false的情况还没编码
	while true do
		local char1 = intputCode[h + startIdx - 1 + i] or self.endCode
		local char2 = self.tail[tailIndex + i - 1]
		-- print("char1, char2", i, char1, char2)
		if char2 == self.endCode and optimize then
			break
		end
		if char1 ~= char2 then
			matched = false
			break
		end
		i = i + 1
		if i > lastLength1 or i > lastLength2 then
			print("严重错误，结束符不可以使用字库中任何符号!!!")
			break
		end
	end

	if matched then
		-- 已经匹配到了
		-- print("true2")
	else
		-- 没有匹配到
		self.failType = 2
		self.failR = r    --失配字符leader在base中的索引
		self.failArrayIndex = h  -- 失败的最后那个leader节点，在数组中的索引
		self.failTailStartIndex = tailIndex  -- 失败的节点在tail中的起始位置
		self.failTailLength = lastLength2  -- 失败的节点在tail中的长度
		self.failTailOffsetIndex = i  -- 失败节点的偏移量，从1开始
		-- print(r, h, tailIndex, lastLength2, i)
		-- print("false type:2")
	end
	return matched
end

function DAT:BuildBuyCfgs(cfgs, key)
	-- 排序后的全部数组
	local data = Tool.GenerateCharSetByCfgs(cfgs, key)
	local encodesArray = data.encodesArray
	self.charSet = data.charSet
	self.endCode = data.endCode
	self.sliceCode = data.sliceCode
	self.nilCode = data.nilCode

	for _,v in ipairs(encodesArray) do
		local count = 100
		while self:_AddEncodesItem(v) do
			count = count - 1
			if count <= 0 then
				print("while循环太多，请检查逻辑错误")
			end
		end
	end
end

return DAT