#ifndef __AC_BASIC_TYPE_H__
#define __AC_BASIC_TYPE_H__

#include "ac_interval.h"
#include "ac_define.h"

namespace AC
{
#define DEFAULT_AC_START -1
#define DEFAULT_AC_END   -1

    template <typename Char>
    class LongInterval : public Interval 
    {
    public:
	typedef std::basic_string<Char> StringType;
	typedef std::basic_string<Char>& StringTypeRef;

        LongInterval() : Interval(DEFAULT_AC_START, DEFAULT_AC_END), keyword_() {}
        LongInterval(size_t start, size_t end, std::basic_string<Char> keyword, uint32_t index)
            : Interval(start, end), keyword_(keyword), index_(index) {}
        virtual ~LongInterval()
        {
            keyword_.clear();
            index_ = 0;
        }

        inline std::basic_string<Char> Keyword() const { return std::basic_string<Char>(keyword_); }
        inline uint32_t Index() const { return index_; }
        inline bool Empty() const { return (Start() == DEFAULT_AC_START && End() == DEFAULT_AC_END); }
    private:
        std::basic_string<Char>  keyword_;
        uint32_t index_{0};
    };

    template <typename Char>
    class LongState
    {
        typedef LongState<Char>* LongStatePointer;
        typedef std::basic_string<Char> StringType;
        typedef std::basic_string<Char>& StringTypeRef;

    public:
        LongState() : LongState(0) {}
        LongState(size_t depth)
            : depth_(depth)
            , root_(depth == 0 ? this : nullptr) {}

        inline size_t Depth() const { return depth_; }

        LongStatePointer NextState(Char c) const 
        { 
            return __Next(c, false);
        }
        LongStatePointer NextStateIgnoreRootState(Char c) const 
        { 
            return __Next(c, true);
        }

        LongStatePointer AddState(Char c)
        {
            auto n = NextStateIgnoreRootState(c);
            if (!n)
            {
                n = new LongState<Char>(depth_ + 1);
                //TODO 缺少一个自动释放
                success_[c] = n;
            }
            return n;
        }

        void AddLongInterval(StringTypeRef keyword, uint32_t index)
        {
            intervals_.insert(std::make_pair(keyword, index));
        }

        void AddLongInterval(const std::set<std::pair<StringType, uint32_t>>& intervals)
        {
            for (const auto &i : intervals)
            {
                StringType s(i.first);
                AddLongInterval(s, i.second);
            }
        }

        std::set<std::pair<StringType, uint32_t>> GetIntervals() const { return intervals_; }
        LongStatePointer GetFailure() const { return failure_; }
        void SetFailure(LongStatePointer fail) { failure_ = fail; }

        std::vector<LongStatePointer> GetSuccess() const 
        {
            std::vector<LongStatePointer> result;
            for (auto& success : success_)
            {
                result.emplace_back(success.second);
            }
            return std::vector<LongStatePointer>(result);
        }

        std::vector<Char> GetSuccessChar() const 
        {
            std::vector<Char> result;
            for (auto& success : success_)
            {
                result.emplace_back(success.first);
            }
            return std::vector<Char>(result);
        }

    private:
        LongStatePointer __Next(Char c, bool ignore) const 
        {
            LongStatePointer result = nullptr;
            auto find = success_.find(c);
            if (find != success_.end())
            {
                result = find->second;
            }
            else if (!ignore && root_) 
            {
                result = root_;
            }
            return result;
        }
            
    private:
        size_t              depth_{0};
        LongStatePointer    root_{nullptr};
        std::map<Char, LongStatePointer> success_;
        LongStatePointer    failure_{nullptr};
        std::set<std::pair<StringType, uint32_t>> intervals_;
    };
}

#endif /* __AC_BASIC_TYPE_H__ */
