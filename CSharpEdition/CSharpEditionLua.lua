-- require("Preload")
local bit = require("bit")

local DirtyWordFilter = class("DirtyWordFilter")

local CharMaxValue = 65535
local IntMaxValue = 2147483647

function DirtyWordFilter:ctor()
	self.hash = {}  -- <string,int>
	self.fastCheck = {}	-- byte[char.MaxValue] 
	self.fastLength = {}	-- byte[char.MaxValue] 
	self.charCheck = {} 	-- BitArray[char.MaxValue]
	self.endCheck = {}  -- BitArray[char.MaxValue]
	for i=1,CharMaxValue do
		table.insert(self.fastCheck, 0)
		table.insert(self.fastLength, 0)
		table.insert(self.charCheck, false)
		table.insert(self.endCheck, false)
	end
	self.maxWordLength = 0  -- int
	self.minWordLength = IntMaxValue  -- int
	self._replaceString = "*"  -- string
	self._fastReplaces = {}  -- string[16]
	self:ResetMaxLength(16)
	self._newWord = ""  -- string
	self.cfgCount = 0
end

function DirtyWordFilter:ResetMaxLength(length)
	self._fastReplaces = {}  -- string[x]
	for i=1,length do
		table.insert(self._fastReplaces, {})
	end
end

function DirtyWordFilter:InitByCfgs(cfgs)
	for _,v in pairs(cfgs) do
		self:InitString(v.word)
		self.cfgCount = self.cfgCount + 1
	end
end
-- 初始化数据,将String[]类型敏感词放入HashSet中
function DirtyWordFilter:InitStringArray(strings)  --string[] int
	for _,s in ipairs(strings) do
		self:InitString(s)
	end
end

function DirtyWordFilter:InitString(s)
	local word = string.ConvertToCharArray(s)
	local wordLength = #word
	local cc = self._replaceString[1]
	local first = word[1]
	if #self._fastReplaces > wordLength and #self._fastReplaces[wordLength + 1] == 0 then
		for i=1,wordLength do
			table.insert(self._fastReplaces[wordLength + 1], cc)
		end
	end
	self.maxWordLength = math.max(self.maxWordLength, wordLength);
	self.minWordLength = math.min (self.minWordLength, wordLength);

	local i = 0
	while i < 7 and i < wordLength do
		local charEncode = string.byte(word[i+1], 1)
		local number = self.fastCheck[charEncode]
		self.fastCheck[charEncode] = bit.bor(number, bit.lshift(1, i))
		i = i + 1
	end

	local i = 7
	while i < wordLength do
		local charEncode = string.byte(word[i+1], 1)
		local number = self.fastCheck[charEncode]
		self.fastCheck[charEncode] = bit.bor(number, 0x80)
		i = i + 1
	end

	if wordLength == 1 then
		local charEncode = string.byte(first, 1)
		self.charCheck[charEncode] = true
	else
		local charEncode = string.byte(first, 1)
		local number = self.fastLength[charEncode]
		local shift = math.min (7, wordLength - 2)
		self.fastLength[charEncode] = bit.bor(number, bit.lshift(1, shift))

		local endCharEncode = string.byte(word[#word], 1)
		self.endCheck[endCharEncode] = true
	end

	if not self.hash[s] then
		self.hash[s] = 1
	end
end

-- 检查是否有敏感词
function DirtyWordFilter:HasBadWord(text)
	local result = self:SearchBadWord(text)
	return result ~= -1 and true or false
end

-- 查找敏感词的索引位置
function DirtyWordFilter:SearchBadWord(text)
	local index = 0
	local chars = string.ConvertToCharArray(text)
	while index < #chars do
		local count = 1

		local charEncode = string.byte(chars[index + 1], 1)
		local number = self.fastCheck[charEncode]
		if bit.band(number, 1) == 0 then
			local check = function()
				local s1 = index < #chars - 1
				if s1 then
					index = index + 1
					local charEncode2 = string.byte(chars[index + 1], 1)
					local number2 = self.fastCheck[charEncode2]
					return bit.band(number2, 1) == 0
				else
					return false
				end
			end
			while check() do
			end
		end

		local continue = false
		local begin = chars[index + 1]
		local charEncode = string.byte(begin, 1)
		if self.minWordLength == 1 and self.charCheck[charEncode] then
			if self.hash[begin] then
				return index
			else
				index = index + 1
				continue = true
			end
		end

		if not continue then
			local j = 1
			while j <= math.min(self.maxWordLength, #chars - index - 1) do
				local current = chars[index + j + 1]
				local charEncode = string.byte(current, 1)
				local number = self.fastCheck[charEncode]
				local shiftNumber = bit.lshift(1, math.min (j, 7))
				if bit.band(number, shiftNumber) == 0 then
					break
				end

				if (j + 1 >= self.minWordLength) then
					local charEncode2 = string.byte(begin, 1)
					local fastLengthNumber = self.fastLength[charEncode2]
					local shiftNumber = bit.lshift(1, math.min(j - 1, 7))
					local s1 = bit.band(fastLengthNumber, shiftNumber) > 0
					if s1 and self.endCheck[charEncode] then
						local sub = string.sub(text, index + 1, index + j + 1)
						if self.hash[sub] then
							return index
						end
					end
				end

				j = j + 1
			end
			index = index + 1
		end
	end
	return -1
end

return DirtyWordFilter