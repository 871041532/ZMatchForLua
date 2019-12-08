说明:
	*纯lua实现的敏感词检测过滤功能库,基于Trie。
	*10000条非&敏感词, 1000次查找或过滤, 平均30ms.
	*当敏感词很少时, 直接遍历string.find查找效率较高; 当敏感词较多的时候, 使用Tri查找的方式效率高.
	*Index.lua是测试用例, 运行即可.
	
敏感词检测规则:
	(1) g_SensitiveWordsCfg中, 只要有不带&的word是text的子串, 则视为text含有敏感词
	(2) g_SensitiveWordsCfg中, 某个带&的word, 会先分割“&”为子串Array。如果Array中所有string都是text子串, 则视为text含有敏感词。

敏感词过滤规则:
	(1)text中的所有敏感词都会被替换为默认符号'*'.如 “苍井空是世界的” 会过滤为 “***是世界的”
	(后续实现)
	(2)上面的过滤替换, 只适用于配置表中不带&的单个word, 带&的替换等待后续补充。

敏感词配置重复冗余检测:
	(后续实现) 比如"苍井空"与"苍井空xxx"之间存在冗余, "咳咳&井空苍"与"咳咳&井空苍11"之间存在冗余。

使用:
(1)初始化:
	local ZMatch = require("ZMatch")
	local zmatch = ZMatch.New()
(2)一般情况下使用trie方式检:
	local result = zmatch:CheckByTrie(text) 
(3)敏感词较少时建议使用遍历检测:
	local result = zmatch:CheckByOldWay(text)
(4)非&的敏感词过滤:
	local newText = zmatch:FilterText(text)
(5)完整版敏感词过滤(包括带&词):
	等待后续添加。
