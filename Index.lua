local ZMatch = require("ZMatch")
ZMatch.InitTestEnvironment()
-- 测试敏感词检测
local textString = "12345678901234567890"
-- local textString = ""
ZMatch.TestCheck(textString, 1000, 10)
ZMatch.TestCheck("咳咳dasdad井空苍", 1000, 10)
ZMatch.TestCheck("苍井空1", 1000, 10)