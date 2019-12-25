#ifndef __AC_INTERVAL_H__
#define __AC_INTERVAL_H__

#include "ac_define.h"

namespace AC
{
    class Interval
    {
    public:
        Interval(size_t start, size_t end);
        virtual ~Interval();

        inline size_t Start() const { return start_; }
        inline size_t End() const { return end_; }
        inline size_t Size() const { return end_ - start_ + 1; }

        bool operator<(const Interval& other) const;
        bool operator!=(const Interval& other) const;
        bool operator==(const Interval& other) const;

        bool IsOverlapToInterval(const Interval& interval) const;
        bool IsOverlapToValue(const size_t value) const;

    private:
        size_t start_{0};
        size_t end_{0};
    };


}

#endif /*__AC_INTERVAL_H__*/
