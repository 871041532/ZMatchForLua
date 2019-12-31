require("Preload")


local DATTool = {}

-- 输入一个未排序的字符串cfgs，生成成charsArray，并且生成endCode, sliceCode, nilCode
function DATTool.GenerateCharSetByCfgs(cfgs, key)
    local endCode = 0
    local sliceCode = 0
    local nilCode = 0
    local charSet = {}
    local charsArray = {}  -- cfgs转成的charsArray
    local encodesArray = {}  -- cfgs转成的encodeArray

    local charTimes = {}  -- char:times
    local singleCharArray = {}  -- char

	for _, v in pairs(cfgs) do
		local chars = string.ConvertToCharArray(key and v[key] or v)
		table.insert(charsArray, chars)
		for i=1,#chars do
			local char = chars[i]
			if not charTimes[char] then
				table.insert(singleCharArray, char)
				charTimes[char] = 1
			else
				charTimes[char] = charTimes[char] + 1
			end
		end
	end

	endCode = #singleCharArray + 1
	sliceCode =  #singleCharArray + 2
	nilCode =  #singleCharArray + 3

    -- 按照使用次数逆序
	table.sort(singleCharArray, function(char1, char2)
		return charTimes[char1] > charTimes[char2]
	end)
    -- 设置charSet
	for i, v in ipairs(singleCharArray) do
		charSet[v] = i
	end
    -- 获取encodeArray
    for _, chars in ipairs(charsArray) do
        local encodes= DATTool.ConvertCharArrayToEncodeArray(charSet, chars, nilCode)
        table.insert(encodesArray, encodes)
    end

    -- 对encodeArray排序
    table.sort(encodesArray, function(encodes1, encodes2)
        if #encodes1 == #encodes2 then
            for i = 1, #encodes1 do
                if encodes1[i] < encodes2[i] then
                    return true
                elseif encodes1[i] > encodes2[i] then
                	return false
                end
            end
            return false
        else
            return #encodes1 < #encodes2
        end
    end)


    return {
        charSet = charSet,
        endCode = endCode,
        sliceCode = sliceCode,
        nilCode = nilCode,
        encodesArray = encodesArray,
    }
end

-- 将charArray，转为EncodeArray
function DATTool.ConvertCharArrayToEncodeArray(charSet, charArray, nilCode)
    local encodeArray = {}
    for _, v in ipairs(charArray) do
        local encode = charSet[v]
        if encode then
            table.insert(encodeArray, encode)
        else
            table.insert(encodeArray, nilCode)
        end
    end
    return encodeArray
end

local cfgs = require("SensitiveWordsCfg")
local data = DATTool.GenerateCharSetByCfgs(cfgs, "word")
return DATTool