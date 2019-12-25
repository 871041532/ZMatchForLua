#ifndef __AC_CONFIG_H__
#define __AC_CONFIG_H__

#include "ac_define.h"

namespace AC
{
    class Config
    {
    public:
        Config()
            : switch_allow_overlaps_(true)
            , switch_only_whole_words_(false)
        {

        }

        inline bool IsAllowOverlaps() const { return switch_allow_overlaps_; }
        inline void SetAllowOverlaps(bool allow) { switch_allow_overlaps_ = allow; }
        inline bool IsAllowWholeWords() const { return switch_only_whole_words_; }
        inline void SetAllowWholeWords(bool allow) { switch_only_whole_words_ = allow; }
        
    private:
        bool switch_allow_overlaps_{false};
        bool switch_only_whole_words_{false};
    };
}

#endif /* __AC_CONFIG_H__ */
