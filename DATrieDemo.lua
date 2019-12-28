require("Preload")


--它的想法其实很简单，就是用两个数组来存储一棵trie树，这种存储方法不仅节省内存空间而且检索词语的速度也非常快。
-- base和check数组的索引表示一个状态 
local DAT = class("DAT")

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

function DAT:Test()
	-- self.base = {1,0,6,-17,2,1,2,6,-10,-1,1,0,-20,0,-24,0,0,0,-22,-13}
	-- self.check = {20,0,1,7,7,7,3,6,3,5,8,0,5,0,6,0,0,0,11,11}
	self.charSet = {
		a = 1,
		b = 2,
		c = 3,
		d = 4,
		e = 5,
		f = 6,
		g = 7,
		h = 8,
		i = 9,
		j = 10,
		k = 11,
		l = 12,
		m = 13,
		n = 14,
		o = 15,
		p = 16,
		q = 17,
		r = 18,
		s = 20,
		y = 21,
	}
	-- self.count = 20
	self.endCode = 19
	self.sliceCode = -1
	self.nilCode = -2

	-- self.tail = {
	-- 	[1] = self.charSet.e,
	-- 	[2] = self.charSet.l,
	-- 	[3] = self.charSet.o,
	-- 	[4] = self.charSet.r,
	-- 	[5] = self.endCode,
	-- 	[6] = self.sliceCode,
	-- 	[7] = 0,
	-- 	[8] = 0,
	-- 	[9] = 0,
	-- 	[10] = self.charSet.s,
	-- 	[11] = self.endCode,
	-- 	[12] = self.sliceCode,
	-- 	[13] = self.sliceCode,
	-- 	[14] = 0,
	-- 	[15] = 0,
	-- 	[16] = 0,
	-- 	[17] = self.charSet.y,
	-- 	[18] = self.endCode,
	-- 	[19] = self.sliceCode,
	-- 	[20] = self.endCode,
	-- 	[21] = self.sliceCode,
	-- 	[22] = self.endCode,
	-- 	[23] = self.sliceCode,
	-- 	[24] = self.charSet.e,
	-- 	[25] = self.charSet.s,
	-- 	[26] = self.charSet.s,
	-- 	[27] = self.endCode,
	-- 	[28] = self.sliceCode,
	-- }
	local test = function (text)
		local r = self:CheckText(text) and 'true' or 'false'
		local s = string.format("检测【%s】,结果%s",text, r)
		print(s)
	end
	-- test("badge")
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

function DAT:CheckText(text)
	local chars = string.ConvertToCharArray(text)
	local intputCode = self:_ConvertCharArrayToInputCode(chars)
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

function DAT:_ExpandBaseAndCheck(count)
	if count == nil or count < 0 then
		print("_ExpandBaseAndCheck错误的count参数：", count)
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
			self:_ExpandBaseAndCheck(targetIndex)
			if self.check[targetIndex] ~= 0 then
				ok = false
				break
			end
		end
		if ok then
			found = true
		else
			offset = offset + 1
		end
	end
	return offset
end

function function_name( ... )
	-- body
end
-- 左移，起始index，总长度，左移偏移量
function DAT:_LeftShiftTail(startIndex, length, offset)
	for i=startIndex, length-offset do
		self.tail[i] = self.tail[i + 1]
	end
end

function DAT:_GetChildren(fatherIndex)
	local children = {}
	for i,v in ipairs(self.check) do
		if v == fatherIndex then
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
function DAT:_AddSortingChars(chars, idx)
	-- self:Test()
	local intputCode = self:_ConvertCharArrayToInputCode(chars)
	-- 这个字符串本来就是屏蔽字，什么都不做
	if self:_TrieSearchByEncodeArray(intputCode) then
		return
	end
	if self.failType == 1 then
		-- 在base中失配
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
			if self.check[offset + code1] ~= 0 then
				self:_ResolvedCheckConflict(self.failR, offset + code1)
			end
			if self.check[offset + code2] ~= 0 then
				self:_ResolvedCheckConflict(self.failR, offset + code2)
			end
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
			print("发生错误：tail中有共同前缀，这种情况尚未处理！")
		end
	end

	self:_PrintBaseCheckTail()
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
			print("r h+1 t",r, h+1, t)
			print("false type:1")
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
		print("true1")
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
		print("true2")
	else
		-- 没有匹配到
		self.failType = 2
		self.failR = r    --失配字符leader在base中的索引
		self.failArrayIndex = h  -- 失败的最后那个leader节点，在数组中的索引
		self.failTailStartIndex = tailIndex  -- 失败的节点在tail中的起始位置
		self.failTailLength = lastLength2  -- 失败的节点在tail中的长度
		self.failTailOffsetIndex = i  -- 失败节点的偏移量，从1开始
		print(r, h, tailIndex, lastLength2, i)
		print("false type:2")
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
	print("结束符，分隔符，空符", self.endCode, self.sliceCode, self.nilCode)
	local sortFunc = function(char1, char2)
		return self.charTimes[char1] > self.charTimes[char2]
	end
	table.sort(self.charArray, sortFunc)
	for i,v in ipairs(self.charArray) do
		self.charSet[v] = i
		print(i,v)
	end
	print("\n")
	for i=1,#sortingStringCharArray do
		-- self:_AddSortingChars(sortingStringCharArray[i], i)
		while self:_AddSortingChars(sortingStringCharArray[i], i) do
		end
		print("\n")
	end
end


function table.SortStringArray(stringArray)
	local sortFunc = function(str1, str2)
		local chars1 = string.ConvertToCharArray(str1)
		local chars2 = string.ConvertToCharArray(str2)
		if #chars1 == #chars2 then
			return str1 < str2
		else
			return #chars1 < #chars2
		end
	end
	table.sort(stringArray, sortFunc)
end

local cfgs = require("SensitiveMultiCfg")
local dat = DAT.New()

cfgs = {
	"badge",
	"bachelor",
	-- "bcs",
	-- "baby",
	-- "back",
	-- "badger",
	-- "badness",
}
table.SortStringArray(cfgs)
dat:BuildBuyStrings(cfgs)
print("\n"..tostring(dat:CheckText("bachelor")))
-- print(dat.count)
return DAT