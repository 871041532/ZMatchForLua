require("Preload")


--它的想法其实很简单，就是用两个数组来存储一棵trie树，这种存储方法不仅节省内存空间而且检索词语的速度也非常快。
-- base和check数组的索引表示一个状态 
local DAT = class("DAT")

function DAT:ctor()
	self.charSet = {}  -- 字符集编码
	self.stateEmpty = 1
	self.base = {1}  -- base数组,存的数据称为offset,并不都是有效状态会有浪费
	self.check = {}  -- check数组,存的数据是父状态的索引，即base中的索引
	self.tail = {}  -- tail数组存储公共后缀
	self.count = 0
	self.endCode = 0  -- 结束符 #  count+1
	self.sliceCode = 0  -- 分割符 $ count + 2
	self.nilCode = 0  -- 空的字符编码count + 3（字符集中不存在的字符都用这个编码）

	---------------------- 动态构建时用的,离线构建不用 ----------------------------
	self.charArray = {} -- 存放所有字的数组, 按照出现频率倒叙排序
	self.charTimes = {} -- k char v times charSet中char出现的频率，排序用的
end

function DAT:Test()
	self.base = {1,0,6,-17,2,1,2,6,-10,-1,1,0,-20,0,-24,0,0,0,-22,-13}
	self.check = {20,0,1,7,7,7,3,6,3,5,8,0,5,0,6,0,0,0,11,11}
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
	self.tail = {
		[1] = self.charSet.e,
		[2] = self.charSet.l,
		[3] = self.charSet.o,
		[4] = self.charSet.r,
		[5] = self.endCode,
		[6] = self.sliceCode,
		[7] = 0,
		[8] = 0,
		[9] = 0,
		[10] = self.charSet.s,
		[11] = self.endCode,
		[12] = self.sliceCode,
		[13] = self.sliceCode,
		[14] = 0,
		[15] = 0,
		[16] = 0,
		[17] = self.charSet.y,
		[18] = self.endCode,
		[19] = self.sliceCode,
		[20] = self.endCode,
		[21] = self.sliceCode,
		[22] = self.endCode,
		[23] = self.sliceCode,
		[24] = self.charSet.e,
		[25] = self.charSet.s,
		[26] = self.charSet.s,
		[27] = self.endCode,
		[28] = self.sliceCode,
	}
	local test = function (text)
		local r = self:CheckText(text) and 'true' or 'false'
		local s = string.format("检测【%s】,结果%s",text, r)
		print(s)
	end
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
	return self:_doubleArrayTrieSearch(chars)
end

-- 检测字符串是否存在
function DAT:_doubleArrayTrieSearch(charArray)
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

	print(intputCode[1], intputCode[2],intputCode[3],intputCode[4], intputCode[5], intputCode[6], intputCode[7])

	local r = 1
	local h = 0
	while true do
		local t = self.base[r] + intputCode[h + 1]
		if self.check[t] ~= r then
			print("t r h+1",t, r, h+1)
			print("false1")
			return false
		else
			r = t
		end
		h = h + 1
		if not (self.base[r] > 0) then
			break
		end
	end
	print("rh:",r,h)
	-- 此时h表示当前的节点是带trie的蓝色节点
	local lastLength1 = #intputCode - h
	local tailIndex = -self.base[r]
	local lastLength2 = self:_getTailCodeLength(tailIndex)
	print("length12",lastLength1, lastLength2)
	if lastLength1 >= lastLength2 then
		for i=1,lastLength2 do
			local char1 = intputCode[h + i]
			local char2 = self.tail[tailIndex + i - 1]
			print("char1, char2", i, char1, char2)
			if char2 == self.endCode then
				break
			end
			if char1 ~= char2 then
				print("false2")
				return false
			end
		end
		print("true2")
		return true
	else
		print("false3")
		return false
	end
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

	local sortFunc = function(char1, char2)
		return self.charTimes[char1] > self.charTimes[char2]
	end
	table.sort(self.charArray, sortFunc)
	for i,v in ipairs(self.charArray) do
		self.charSet[v] = i
		-- print(i,v)
	end
end


-- 参数必须是经过排序后的字符串数组，然后又转成二维字符数组
function DAT:_BuildBaseAndCheck(sortingStringCharArray)
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
table.SortStringArray(cfgs)
dat:BuildBuyStrings(cfgs)
dat:Test()
-- print(dat.count)
return DAT