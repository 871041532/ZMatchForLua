local ZMatch = require("ZMatch")
ZMatch.InitTestEnvironment()
-- 测试敏感词检测
ZMatch.TestCheck("今晚打老虎今晚打老虎今晚打老虎今晚打老虎今晚打老虎", 1000, 10)
ZMatch.TestCheck("苍井空", 1000, 10)
ZMatch.TestCheck("0.0空井苍0.0", 1000, 10)
ZMatch.TestCheck("咳咳1井空苍", 1000, 10)
-- 测试敏感词替换
ZMatch.TestFilter("今晚打老虎今晚打老虎今晚打老虎今晚打老虎今晚打老虎", 1000)
ZMatch.TestFilter("钓鱼岛是中国的, 苍井空是世界的", 1000)