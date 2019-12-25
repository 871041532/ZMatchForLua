#ifndef __AC_INTERVAL_TREE_H__
#define __AC_INTERVAL_TREE_H__

#include "ac_define.h"

namespace AC
{
    enum class Direction
    {
        Left = 0,
        Right = 1,
    };

    template <typename T>
    class IntervalTreeNode
    {
    public:
        IntervalTreeNode(const std::vector<T>& intervals)
        {
            point_ = ChooseMedian(intervals);
            std::vector<T> left_container;
            std::vector<T> right_container;
            for (const auto& i : intervals)
            {
                if (i.End() < point_)
                {
                    left_container.emplace_back(i);
                }
                else if (i.Start() > point_)
                {
                    right_container.emplace_back(i);
                }
                else
                {
                    intervals_.emplace_back(i);
                }
            }

	    //TODO-FIX: 可能泄露
            if (left_container.size() > 0)
            {
		left_ = new IntervalTreeNode(left_container);
            }
            if (right_container.size() > 0)
            {
		right_ = new IntervalTreeNode(right_container);
            }
        }

        size_t ChooseMedian(const std::vector<T>& intervals) const 
        {
            auto from = std::numeric_limits<size_t>::max();
            auto to = std::numeric_limits<size_t>::max();
            for (const auto &i : intervals)
            {
                auto now_start = i.Start();
                auto now_end = i.End();
                if (from == std::numeric_limits<size_t>::max() || now_start < from)
                {
                    from = now_start;
                }
                if (to == std::numeric_limits<size_t>::max() || now_end > to)
                {
                    to = now_end;
                }
            }
            return (from + to) / 2;
        }

        std::vector<T> FindOverlaps(const T& i)
        {
            std::vector<T> overlaps;
            if (point_ < i.Start())
            {
                __AddOverlaps(i, overlaps, __FindOverlapRange(right_, i));
                __AddOverlaps(i, overlaps, __CheckOverlaps(i, Direction::Right));
            } 
            else if (point_ > i.End())
            {
                __AddOverlaps(i, overlaps, __FindOverlapRange(left_, i));
                __AddOverlaps(i, overlaps, __CheckOverlaps(i, Direction::Left));
            }
            else
            {
                __AddOverlaps(i, overlaps, intervals_);
                __AddOverlaps(i, overlaps, __FindOverlapRange(left_, i));
                __AddOverlaps(i, overlaps, __FindOverlapRange(right_, i));
            }
            return std::vector<T>(overlaps);
        }

    private:

        void __AddOverlaps(const T& i, std::vector<T>& overlaps, std::vector<T> new_overlaps) const
	{
            for (const auto &now : new_overlaps)
            {
                if (now != i)
                {
                    overlaps.emplace_back(now);
                }
            }
        }

        std::vector<T> __CheckOverlaps(const T& i, Direction dir) const
        {
            std::vector<T> overlaps;
            for (const auto& now : intervals_)
            {
                switch(dir)
                {
                    case Direction::Left:
                    {
                        if (now.Start() <= i.End())
                        {
                            overlaps.emplace_back(now);
                        }
                        break;
                    }
                    case Direction::Right:
                    {
                        if (now.End() >= i.Start())
                        {
                            overlaps.emplace_back(now);
                        }
                        break;
                    }
                }
            }
            return std::vector<T>(overlaps);
        }

        std::vector<T> __FindOverlapRange(IntervalTreeNode* node, const T& i) const
        {
            if (node)
            {
                return std::vector<T>(node->FindOverlaps(i));
            }
            return std::vector<T>();
        }

    private:
        size_t              point_{0};
        IntervalTreeNode*   left_{nullptr};
        IntervalTreeNode*   right_{nullptr};
        std::vector<T>      intervals_;
    };

    template <typename T>
    class IntervalTree
    {
    public:
        typedef std::vector<T>   IntervalContainer;

        IntervalTree(const std::vector<T>& intervals)
            : root_(intervals)
        {
        }

        std::vector<T> RemoveOverlaps(const std::vector<T>& intervals)
        {
            std::vector<T> result;
	    result.assign(intervals.begin(), intervals.end());

            std::sort(result.begin(), result.end(), [&](const T& a, const T& b) -> bool {
                if (b.Size() - a.Size() == 0) 
                {
                    return a.Start() > b.Start();
                }
                return a.Size() > b.Size();
            });

            std::set<T> remove_set;
            for (const auto& i : result)
            {
                if (remove_set.find(i) != remove_set.end()) 
                {
                    continue;
                }
                auto overlaps = FindOverlaps(i);
                for (const auto& overlap : overlaps)
                {
                    remove_set.insert(overlap);
                }
            }
            for (const auto& i : remove_set)
            {
                result.erase(std::find(result.begin(), result.end(), i));
            }

            std::sort(result.begin(), result.end(), [&](const T& a, const T& b) -> bool {
                return a.Start() < b.Start();
            });

            return std::vector<T>(result);
        }

        std::vector<T> FindOverlaps(const T& i)
        {
            return std::vector<T>(root_.FindOverlaps(i));
        }

    private:
        IntervalTreeNode<T> root_;
    };
}

#endif /* __AC_INTERVAL_TREE_H__ */
