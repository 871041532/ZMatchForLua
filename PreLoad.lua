-- class函数
function class(name, super)
    if super ~= nil then
        if type(super) ~= "table" then
            return
        end
    end

    local class_type = nil
    if super then
        class_type = {}
        setmetatable(class_type, {__index = super})
        class_type.__super = super
        class_type.super = super
    else
        class_type = {}
    end
    class_type.__index = class_type
    class_type.__cname = name
    class_type.__ctype = 2

    class_type.New = function(...)
        local instance = setmetatable({}, class_type)
        instance.class = class_type
        instance:ctor(...)
        return instance
    end
    class_type.new = class_type.New
    return class_type
end

--不支持继承的class函数,构造函数只有一个参数
function finalClassParam1(name)
    local class_type = nil
    class_type = {}
    class_type.__index = class_type
    class_type.New = function(param)
        local instance = setmetatable({}, class_type)
        instance:ctor(param)
        return instance
    end
    return class_type
end

-- 字符串分割函数
function string.split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- 字符串转char数组函数
-- 将lua utf8 字符串转换为Char数组
function string.ConvertToCharArray(inputstr, reuseArray)
    local num = 0
	local array = reuseArray or {}
	if not inputstr or type(inputstr) ~= "string" or #inputstr <= 0 then
        return array, num
    end
    local length = 0  -- 字符的个数
    local i = 1
	while true do
        local curByte = string.byte(inputstr, i)
        local byteCount = 1
        if curByte > 239 then
            byteCount = 4  -- 4字节字符
        elseif curByte > 223 then
            byteCount = 3  -- 汉字
        elseif curByte > 128 then
            byteCount = 2  -- 双字节字符
        else
            byteCount = 1  -- 单字节字符
        end
        local char = string.sub(inputstr, i, i + byteCount - 1)
        num = num + 1
        if reuseArray then
            array[num] = char
        else
            table.insert(array, char)
        end
        i = i + byteCount
        length = length + 1
        if i > #inputstr then
            break
        end
    end
    return array, num
end

local logSwitch = true
-- 日志统一输出接口
function ZMatchPrint(param)
    if logSwitch then
        print(param)
    end
end

-- 获取table表排序后的数据
function table.getSortKeys(paramTable) 
    local sortKeys = {}
    local sortKeyFun = function(a,b)
        if type(a) ~= type(b) then
            return type(a) < type(b)
        end
        if type(a) == "number" then
            return a < b
        end
        return tostring(a) < tostring(b)
    end
    for k,v in pairs(paramTable) do
        table.insert(sortKeys, k)
    end
    table.sort(sortKeys, sortKeyFun)
    return sortKeys
end


-- 先按照长度排序，短的在前面，相同长度按照字符顺序排序
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