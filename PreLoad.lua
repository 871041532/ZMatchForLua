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