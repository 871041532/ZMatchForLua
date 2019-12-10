-- Lua好挫逼啊，队列这种基础数据结构也要自己撸
-- 不用C++的next指针形式。（都是基于lua表查找，达不到指针的性能）
-- FIFO队列

require("PreLoad")
local Queue = class("Queue")

function Queue:ctor()
	self._data = {}
	self._tailIndex = 1
	self._headIndex = 1
end

function Queue:IsEmpty()
	return self._headIndex == self._tailIndex
end

function Queue:NotEmpty()
	return self._headIndex ~= self._tailIndex
end

function Queue:Enqueue(item)
	self._headIndex = self._headIndex + 1
	self._data[self._headIndex] = item
end

function Queue:Dequeue()
	if self._headIndex == self._tailIndex then
		return nil
	else
		self._tailIndex = self._tailIndex + 1
		return self._data[self._tailIndex]
	end
end

-- local q = Queue.New()
-- print(q:IsEmpty())
-- q:Enqueue("w")
-- q:Enqueue("h")
-- print(q:IsEmpty())
-- print(q:Dequeue())
-- q:Enqueue("a")
-- q:Enqueue("t")
-- print(q:Dequeue())
-- print(q:Dequeue())
-- print(q:IsEmpty())
-- print(q:Dequeue())
-- print(q:Dequeue())
-- print(q:IsEmpty())

return Queue