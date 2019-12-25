collectgarbage("collect")
local c1 = collectgarbage("count")
local cfgs = require("SensitiveWordsCfg")
local c2 = collectgarbage("count")
print("加载SensitiveWordsCfg内存:", c2 - c1)
collectgarbage("collect")
local c3 = collectgarbage("count")
print("GC后内存:", c2 - c3)


collectgarbage("collect")
local c1 = collectgarbage("count")
local ZMatch = require("ZMatch")

local allConfig = require("SensitiveConfig/AllConfig")
local multiTrieRoot = require("SensitiveConfig/multiTrieRoot")
local multiWordTileMap = require("SensitiveConfig/multiWordTileMap")
local multiWordTileList = require("SensitiveConfig/multiWordTileList")

local singleCfgs = {}
for i = 1, allConfig.count do
    local cfg = require("SensitiveConfig/single_"..i)
    table.insert(singleCfgs, cfg)
end

local allCfg = {
    singleTrieRoot = {[1] = {}},
    multiTrieRoot = multiTrieRoot,
    multiWordTileMap = multiWordTileMap,
    multiWordTileList = multiWordTileList,
}


local patchFunc = function(cfg)
    for k, v in pairs(cfg) do
        allCfg.singleTrieRoot[1][k] = v
    end
end

for _, v in ipairs(singleCfgs) do
    patchFunc(v)
end

local zmatch = ZMatch.New()
zmatch:BuildTreeByOfflineData(allCfg)
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
local c2 = collectgarbage("count")
print("构建patch内存:", c2 - c1)

local c1 = collectgarbage("count")
local cfgs = require("SensitiveConfig/singleTrieRoot")
local zmatch = ZMatch.New()
zmatch:BuildTreeByOfflineData(cfgs)
collectgarbage("collect")
local c2 = collectgarbage("count")
print("构建非patch内存:", c2 - c1)