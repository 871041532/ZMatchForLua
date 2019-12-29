require("Preload")


--它的想法其实很简单，就是用两个数组来存储一棵trie树，这种存储方法不仅节省内存空间而且检索词语的速度也非常快。
-- base和check数组的索引表示一个状态 
local DAT = finalClass("DoubleArrayTrie")

function DAT:ctor()
	self.charSet = {}  -- 字符集编码
	self.stateEmpty = 1
	self.base = {1}  -- base数组,存的数据称为offset,并不都是有效状态会有浪费
	self.check = {1}  -- check数组,存的数据是父状态的索引，即base中的索引
	self.tail = {}  -- tail数组存储公共后缀
	self.count = 0
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

function DAT:_getTailCodeLength(start)
	local length = 0
	for i=start, #self.tail do
		if self.tail[i] == self.sliceCode then
			break
		end
		length = length + 1
	end
	return length
end

-- 检测文本
function DAT:CheckText(text)
	local chars = string.ConvertToCharArray(text)
	local intputCode = self:_ConvertCharArrayToInputCode(chars)
	return self:_TrieSearchByEncodeArray(intputCode)
end

-- 检测charArray
function DAT:CheckCharArray(charArray)
	local intputCode = self:_ConvertCharArrayToInputCode(charArray)
	return self:_TrieSearchByEncodeArray(intputCode)
end

-- 检测字符串是否存在
function DAT:_ConvertCharArrayToInputCode(charArray)
	local intputCode = {}
	for _,v in ipairs(charArray) do
		local charEncode = self.charSet[v]
		if charEncode then
			table.insert(intputCode, charEncode)
		else
			table.insert(intputCode, self.nilCode)
		end
	end
	table.insert(intputCode, self.endCode)
	-- print(charArray[1], charArray[2],charArray[3],charArray[4], charArray[5], charArray[6], charArray[7],charArray[8],charArray[9])
	-- print(intputCode[1], intputCode[2],intputCode[3],intputCode[4], intputCode[5], intputCode[6], intputCode[7],intputCode[8],intputCode[9])
	return intputCode
end

function DAT:_PrintBaseCheckTail()
	local strs = "打印base、check、tail：\n"
	strs = strs.."base:"
	for i,v in ipairs(self.base) do
		strs = strs..v.." "
	end
	strs = strs .. "\ncheck:"
	for i,v in ipairs(self.check) do
		strs = strs..v.." "
	end
	strs = strs .. "\ntail:"
	for i,v in ipairs(self.tail) do
		strs = strs..v.." "
	end

	local convertEncodeToChar = function(code)
		for k,v in pairs(self.charSet) do
			if v == code then
				return k
			end
		end
		if code == self.endCode then
			return "#"
		end
		if code == self.sliceCode then
			return "$"
		end
		return "*"
	end
	strs = strs .. "\ntail:"
	for i,v in ipairs(self.tail) do
		strs = strs..convertEncodeToChar(v).." "
	end
	print(strs)
end

function DAT:_ExpandBaseAndCheck(count, source)
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
	self.check[1] = #self.base
end

function DAT:_GetVaildTailOffset(childrenCode)
	local offset = 1
	local found = false
	while not found do
		local ok = true
		for _,v in ipairs(childrenCode) do
			local targetIndex = offset + v
			-- if targetIndex < 0 then
			-- 	print("targetIndex小于0：", offset, v)
			-- end
			self:_ExpandBaseAndCheck(targetIndex)
			if self.check[targetIndex] ~= 0 then
				ok = false
				break
			end
		end
		if ok then
			found = true
		else
			offset = offset + 1  --self.count
		end
	end
	return offset
end

function function_name( ... )
	-- body
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
	-- if #children < #conflictChildren then
	if false then
		-- 使用第一种移动方式, 移动当前节点的父节点，解决冲突
		local childrenCode = {}
		for _,v in ipairs(children) do
			local code = v - self.base[self.check[v]] 
			table.insert(childrenCode, code)
		end
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

-- 参数必须是经过排序后的字符串数组，然后又转成二维字符数组
function DAT:_AddSortingChars(chars)
	-- self:Test()
	-- local charsArray = {}
	-- for i=2,#chars do
	-- 	local temp = {}
	-- 	for j=i,#chars do
	-- 		table.insert(temp, chars[j])
	-- 	end
	-- 	table.insert(charsArray, temp)
	-- end
	-- for _,v in ipairs(charsArray) do
	-- 	local tempCodes = self:_ConvertCharArrayToInputCode(v)
	-- 	if self:_TrieSearchByEncodeArray(tempCodes) then
	-- 		return
	-- 	end
	-- end
	if self.parent:CheckText(nil, chars) then
		return
	end

	local intputCode = self:_ConvertCharArrayToInputCode(chars)
	-- 这个字符串本来就是屏蔽字，什么都不做
	if self:_TrieSearchByEncodeArray(intputCode) then
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
			for i=self.failCharIndex + 1, #intputCode do
				self.tail[#self.tail + 1] = intputCode[i]
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
		local code1 = intputCode[self.failArrayIndex + 1]
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
			for i=self.failArrayIndex + 2, #intputCode do
				self.tail[#self.tail + 1] = intputCode[i]
			end
			self.tail[#self.tail + 1] = self.sliceCode
			-- 设置子状态的offset
			self.base[offset + code1] = -startIndex
			self.base[offset + code2] = -self.failTailStartIndex
		else
			-- print("发生错误：tail中有共同前缀，这种情况尚未处理！")
			local curFather = self.failR
			for i=1,self.failTailOffsetIndex do
				local code1 = intputCode[self.failArrayIndex + i]
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
			for i=self.failArrayIndex + self.failTailOffsetIndex + 1, #intputCode do
				self.tail[#self.tail + 1] = intputCode[i]
			end
			self.tail[#self.tail + 1] = self.sliceCode
		end
	end

	-- self:_PrintBaseCheckTail()
end

function DAT:_TrieSearchByEncodeArray(intputCode)
	local r = 1
	local h = 0
	while true do
		local t = self.base[r] + intputCode[h + 1]
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
	local lastLength1 = #intputCode - h
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
		local char1 = intputCode[h + i]
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

-- 这个stringArray必须是经过特别排序的
-- 动态构建性能较差，建议先构建生成离线数据，运行时直接加载离线数据
function DAT:BuildBuyStrings(sortingStringArray)
	-- 排序后的全部数组
	local sortingStringCharArray = {}
	for _,v in pairs(sortingStringArray) do
		local chars = string.ConvertToCharArray(v)
		table.insert(sortingStringCharArray, chars)
		for i=1,#chars do
			local char = chars[i]
			if not self.charTimes[char] then
				table.insert(self.charArray, char)
				self.charTimes[char] = 1
				self.count = self.count + 1
			else
				self.charTimes[char] = self.charTimes[char] + 1
			end
		end
	end
	-- 给nilCode和endCode赋值
	self.endCode = self.count + 1
	self.sliceCode = self.count + 2
	self.nilCode = self.count + 3
	-- print("结束符，分隔符，空符", self.endCode, self.sliceCode, self.nilCode)
	local sortFunc = function(char1, char2)
		return self.charTimes[char1] > self.charTimes[char2]
	end
	table.sort(self.charArray, sortFunc)
	for i,v in ipairs(self.charArray) do
		self.charSet[v] = i
		-- print(i,v)
	end
	-- print("\n")
	for i=1,#sortingStringCharArray do
		-- self:_AddSortingChars(sortingStringCharArray[i])
		local count = 100
		while self:_AddSortingChars(sortingStringCharArray[i]) do
			count = count - 1
			if count <= 0 then
				print("while循环太多，请检查")
			end
		end
		-- print("\n")
	end
end

local DATS = finalClass("DoubleArrayTries")

function DATS:ctor()
	self.sliceCount = 100000  -- 多少个词分割一组
	self.datList = {}  -- dat数组
end

function DATS:CheckText(text, paramChars)
	local chars = paramChars or string.ConvertToCharArray(text)
	local charsArray = {}
	for i=1,#chars do
		local temp = {}
		for j=i,#chars do
			table.insert(temp, chars[j])
		end
		for _,dat in ipairs(self.datList) do
			if dat:CheckCharArray(temp) then
				return true
			end
		end
	end
	return false
end

-- build的时候会根据字符集的数量分割成多个子DAT以节省内存
-- 参数必须是经过table.SortStringArray排序后的字符串数组
function DATS:BuildBuyStrings(strings)
	local count = 1
	local curDat = nil
	local usingStrings = {}
	for i,v in ipairs(strings) do
		-- if not self:CheckText() then
			if count == 1 then
				usingStrings[#usingStrings + 1] = {}
			end
			table.insert(usingStrings[#usingStrings], v)
			count = count + 1
			if count >= self.sliceCount or i >= #strings then
				count = 1
				local dat = DAT.New()
				table.insert(self.datList, dat)
				dat.parent = self
				dat:BuildBuyStrings(usingStrings[#usingStrings])
			end
		-- end
	end
	print("数量：",#usingStrings)
	-- for _,v in ipairs(usingStrings) do
	-- 	local dat = DAT.New()
	-- 	dat:BuildBuyStrings(v)
	-- 	table.insert(self.datList, dat)
	-- end
end

-- 返回一个DAT.OfflineData数组
function DATS:BuildBuyOfflineData(offlineData)
	self.datList = {}
	for _,data in ipairs(offlineData) do
		local dat = DAT.New()
		dat:BuildBuyOfflineData(data)
		table.insert(self.datList, dat)
	end
end

-- 获取DAT数据
function DATS:GetOfflineData()
	local offlineData = {}
	for _,dat in ipairs(self.datList) do
		local data = dat:GetOfflineData()
		table.insert(offlineData, data)
	end
	return offlineData
end

return DATS

-- return DAT