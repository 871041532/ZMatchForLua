require("Preload")
local bit = require("bit")

-- 敏感词实体类
local BadWordEntity = {}
function BadWordEntity.New()
	return {
		BadWord = {}  --char数组
	}
end

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
end

function DirtyWordFilter:ResetMaxLength(length)
	self._fastReplaces = {}  -- string[x]
	for i=1,length do
		table.insert(self._fastReplaces, {})
	end
end

-- 初始化数据,将List集合类型敏感词放入HashSet中
function DirtyWordFilter:Init(badwords)  -- List<BadWordEntity>
	for _,word in ipairs(badwords) do
		self.maxWordLength = math.max (self.maxWordLength, #word.BadWord)
		self.minWordLength = math.min (self.minWordLength, #word.BadWord)

		for i=1,7 do
			if i > #word.BadWord then
				break
			end
			local charEncode = string.byte(word.BadWord[i], 1)
			local number = self.fastCheck[charEncode]
			self.fastCheck[charEncode] = bit.bor(number, bit.lshift(1, i-1))
		end

		for i=8,#word.BadWord do
			local charEncode = string.byte(word.BadWord[i], 1)
			local number = self.fastCheck[charEncode]
			self.fastCheck[charEncode] = bit.bor(number, IntMaxValue + 1)
		end
			
		if #word.BadWord == 1 then
			local charEncode = string.byte(word.BadWord[1], 1)
			local number = self.charCheck[charEncode]
			self.charCheck[charEncode] = true
		else
			local charEncode = string.byte(word.BadWord[1], 1)
			local number = self.fastLength[charEncode]
			local shift = math.min (7, #word.BadWord.Length - 2)
			self.fastLength[charEncode] = bit.bor(number, bit.lshift(1, shift))

			local endCharEncode = string.byte(word.BadWord[#word.BadWord], 1)
			self.endCheck[endCharEncode] = true
		end
	end
end

-- 初始化数据,将String[]类型敏感词放入HashSet中
function DirtyWordFilter:InitStringArray(strings, type)  --string[] int
	for _,s in ipairs(strings) do
		InitString(s, type)
	end
end

function DirtyWordFilter:InitString(s, type)
	local word = string.ConvertToCharArray(s)
	local wordLength = #word
	local cc = self._replaceString[1]
	local first = word[1]
	if #self._fastReplaces > wordLength and #self._fastReplaces[wordLength + 1] == 0 then
		for i=1,wordLength do
			table.insert(self._fastReplaces[wordLength + 1], cc)
		end
		self._fastReplaces[wordLength + 1] = 
	end
	self.maxWordLength = math.max(self.maxWordLength, wordLength);
	self.minWordLength = math.min (self.minWordLength, wordLength);

	for i=1,7 do
		if i > wordLength then
			break
		end
		local charEncode = string.byte(word[i], 1)
		local number = self.fastCheck[charEncode]
		self.fastCheck[charEncode] = bit.bor(number, bit.lshift(1, i-1))
	end

	for i=8,wordLength do
		local charEncode = string.byte(word[i], 1)
		local number = self.fastCheck[charEncode]
		self.fastCheck[charEncode] = bit.bor(number, IntMaxValue + 1)
	end

	if wordLength == 1 then
		local charEncode = string.byte(first, 1)
		local number = self.charCheck[charEncode]
		self.charCheck[charEncode] = true
	else
		local charEncode = string.byte(first, 1)
		local number = self.fastLength[charEncode]
		local shift = math.min (7, wordLength - 2)
		self.fastLength[charEncode] = bit.bor(number, bit.lshift(1, shift))

		local endCharEncode = string.byte(word[#word], 1)
		self.endCheck[endCharEncode] = true
	end

	if self.hash[s] == nil then
		self.hash[s] = type
	else
		self.hash[s] = bit.bor(self.hash[s], type)
	end
end

-- 检查是否有敏感词
function DirtyWordFilter:HasBadWord(text, types)
	local result = self:SearchBadWord(text, types)
	return result != -1
end

-- 查找敏感词的索引位置
function DirtyWordFilter:SearchBadWord(text, types)
end

-- 替换敏感词
function DirtyWordFilter:ReplaceBadWord(text, types)
end

public class DirtyWordFilter
{

	public int SearchBadWord (string text, int types)
	{
		int index = 0;
		int hashedType = 0;
		while (index < text.Length) {
			int count = 1;
			if ((fastCheck [text [index]] & 1) == 0) {
				while (index < text.Length - 1 && (fastCheck[text[++index]] & 1) == 0)
					;
			}
			
			char begin = text [index];
			if (minWordLength == 1 && charCheck [begin]) {
				if ((hash [begin.ToString ()] & types) > 0)
					return index;
				else {
					index++;
					continue;
				}
			}
			for (int j = 1; j <= Math.Min(maxWordLength, text.Length - index - 1); j++) {
				char current = text [index + j];
				
				if ((fastCheck [current] & (1 << Math.Min (j, 7))) == 0) {
					break;
				}
				
				if (j + 1 >= minWordLength) {
					if ((fastLength [begin] & (1 << Math.Min (j - 1, 7))) > 0 && endCheck [current]) {
						string sub = text.Substring (index, j + 1);
						if (hash.ContainsKey (sub)) {
							if ((hash [sub] & types) > 0)
								return index;
						}
					}
				}
			}
			index ++;
		}
		return -1;
	}
	
	
	public string ReplaceBadWord (string text, int types)
	{
		int index = 0;
		int hashedType = 0;
		char begin;
		for (index = 0; index < text.Length; index++) {
			if ((fastCheck [text [index]] & 1) == 0) {
				while (index < text.Length - 1 && (fastCheck[text[++index]] & 1) == 0)
					;
			}
			//单字节检测
			begin = text [index];
			if (minWordLength == 1 && charCheck [begin]) {
				if ((hash [begin.ToString ()] & types) > 0) {
					text = text.Replace (begin, _replaceString [0]);
					continue;
				}
			}
			
			//多字节检测
			for (int j = 1; j <= Math.Min(maxWordLength, text.Length - index - 1); j++) {
				//快速排除
				if ((fastCheck [text [index + j]] & (1 << Math.Min (j, 7))) == 0) {
					break;
				}
				
				if (j + 1 >= minWordLength && _fastReplaces.Length > j + 1) {
					string sub = text.Substring (index, j + 1);
					
					if (hash.ContainsKey (sub)) {
						if ((hash [sub] & types) > 0) {
							//替换字符操作
							text = text.Replace (sub, _fastReplaces [(j + 1)]);
							//记录新位置
							index += j;
							break;
						}
					}
				}
			}
		}
		_newWord = text;
		return text;
	}


