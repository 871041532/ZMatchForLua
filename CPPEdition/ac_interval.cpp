#include "ac_interval.h"

namespace AC
{
    Interval::Interval(size_t start, size_t end)
    {
        start_ = start;
        end_ = end;
    }

    Interval::~Interval()
    {
        start_ = 0;
        end_ = 0;
    }

    bool Interval::operator<(const Interval& other) const
    {
        return start_ < other.Start();
    }

    bool Interval::operator!=(const Interval& other) const
    {
        return start_ != other.Start()
                || end_ != other.End();
    }

    bool Interval::operator==(const Interval& other) const
    {
        return start_ == other.Start()
                && end_ == other.End();
    }

    bool Interval::IsOverlapToInterval(const Interval& interval) const
    {
        return Start() <= interval.End() && End() >= interval.Start();
    }

    bool Interval::IsOverlapToValue(const size_t value) const
    {
        return Start() <= value && value <= End();
    }

} // namespace AC
