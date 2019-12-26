local ZMatch = require("ZMatch")

local zmatch


-- function ToStringEx(value)
--     if type(value)=='table' then
--         return TableToStr(value)
--     elseif type(value)=='string' then
--         return "\'"..value.."\'"
--     else
--         return tostring(value)
--     end
-- end

-- --使用的时候是这个
-- function TableToStr(t)
--     if t == nil then return "" end
--     local retstr= "{"

--     local i = 1
--     for key,value in pairs(t) do
--         local signal = ","
--         if i==1 then
--             signal = ""
--         end

--         if key == i then
--             retstr = retstr..signal..ToStringEx(value)
--         else
--             if type(key)=='number' or type(key) == 'string' then
--                 retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
--             else
--                 if type(key)=='userdata' then
--                     retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
--                 else
--                     retstr = retstr..signal..key.."="..ToStringEx(value)
--                 end
--             end
--         end

--         i = i+1
--     end

--     retstr = retstr.."}"
--     return retstr
-- end

-- local writeFile = function(key, strs)
-- 	local file = io.open(key, "w")
-- 	io.output(file)
-- 	io.write(strs)
-- 	io.close(file)
-- end

-- local cfgs = require("SensitiveMultiCfg")
-- local newCfg = {}
-- for i=1,20000 do
-- 	newCfg[i] = cfgs[i]
-- end
-- writeFile("SensitiveMultiCfg11.lua", TableToStr(newCfg))

function InitTestEnvironment()
	-- 预处理
	-- SensitiveMultiCfg()

	-- 初始化
	collectgarbage("collect")
	local c = collectgarbage("count")
	local cfgs = require("SensitiveMultiCfg")
	collectgarbage("collect")
	local c1 = collectgarbage("count")
	print("配置表内存:", c1 - c)
	local t1 = os.clock()
	zmatch = ZMatch.New()
	zmatch:ReBuildExtMultiTree(cfgs)
	local t2 = os.clock()
	collectgarbage("collect")
	local c2 = collectgarbage("count")
	print("构建Trie内存:", c2 - c1)
	cfgs = nil
	cfgs2 = nil
	collectgarbage("collect")
	local c3 = collectgarbage("count")
	print("常驻总内存:", c3 - c)
	print("构建时间:", t2 - t1)
	print("配置词条总量", zmatch.multiItemCount)
end
local printLine = function()
	print("----")
end

function TestCheck(text, count)
	printLine()
	print(string.format("\n开始对【%s】进行敏感词检测...", text))
	local t2 = os.clock()
	for i=1,count do
		r = zmatch:CheckText(text)
	end
	local t3 = os.clock()
	print(string.format("\t%d次模糊,时间%f,结果%s", count, t3 - t2, r and "true" or "false"))
	
end

-- 检测重复配置
function CheckRepetCfg()
	local strs = ""
	local appendLine = function (str)
		str = "\n"..str
		strs = strs..str
	end
	local count = 0
	local sensitiveFunc = function(text)
		return string.ConvertToCharArray(text)
	end
 	local checkAllByTraverse= function(k,text)
 		local isFirstPrint = false 
 		local firstPrint = function()
 			if not isFirstPrint then
 				isFirstPrint = true
 				local stes
 				print("\n----------------------------------------")
 				appendLine("\n----------------------------------------")
 				print(k, text, "已经涵盖了下面单词意思:")
 				appendLine(k.." "..text.." 已经涵盖了下面单词意思:")
 			end
 		end
		local sheet = require("SensitiveMultiCfg")
		local strings = sensitiveFunc(text)
		for k1, item in pairs(sheet) do
			if k1 ~= k then
				local m = true
				for _, w in ipairs(strings) do
					if not string.find(item.word, w, 1, true) then
						m = false
						break
					end
				end
				if m then
					firstPrint()
					print("冗余:", k1, item.word)
					appendLine("冗余: "..k1.." "..item.word)
					count = count + 1
				end
			end
		end
		return false
	end
	for k,v in pairs(require("SensitiveMultiCfg")) do
		checkAllByTraverse(k, v.word)
	end

	print(string.format("冗余配置:%d条", count))
	appendLine(string.format("冗余配置:%d条", count))

	local file = io.open("CheckResult.txt", "w")
	io.output(file)
	io.write(strs)
	io.close(file)
end


function TestFilter(text, newWayCount)
	local count = newWayCount
	local t2 = os.clock()
	for i=1,count do
		r = zmatch:FilterText(text)
	end
	local t3 = os.clock()
	print(string.format("\n\n%d次敏感词过滤,时间:%f,\n--源:【%s】\n--结果:【%s】", count, t3 - t2, text, r))
	local chars = string.ConvertToCharArray(text)
	t2 = os.clock()
	for i=1,count do
		chars = zmatch:_FilterSingleChars(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次常规词过滤,时间%f", count, t3 - t2))

	t2 = os.clock()
	for i=1,count do
		chars = zmatch:_FilterMultiChars(chars)
	end
	t3 = os.clock()
	print(string.format("\t%d次带&词过滤,时间%f", count, t3 - t2))
end

InitTestEnvironment()
-- CheckRepetCfg()
TestCheck("123六123四123要123平123反123", 100)
TestFilter("香港是中国的", 100)
TestCheck("苍井空", 100)
TestCheck("正常说一句话的内容大概这么长...", 100)
TestCheck("1111111111.1111111111.1111111111.1111111111.1111111111", 100)