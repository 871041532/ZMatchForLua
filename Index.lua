local ZMatch = require("ZMatch")
ZMatch.InitTestEnvironment()
-- 测试敏感词检测
-- local textString = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890苍井空123123"
local textString = "世界的苍井空！"
local textString = "12345678901234567890123456789012345678苍井空901234567890"
ZMatch.TestCheck(textString, 1000, 10)
-- ZMatch.TestCheck("苍井空", 1000, 10)
-- ZMatch.TestCheck("0.0空井苍0.0", 1000, 10)
-- ZMatch.TestCheck("咳咳1井空苍", 1000, 10)
-- -- 测试敏感词替换
-- ZMatch.TestFilter("今晚打老虎今晚打老虎今晚打老虎今晚打老虎今晚打老虎", 1000)
-- ZMatch.TestFilter("钓鱼岛是中国的, 苍井空是世界的", 1000)
ZMatch.TestCheckByAC("textString", 1000)