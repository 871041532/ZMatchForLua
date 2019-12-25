#ifndef __AC_TRIE_TREE_H__
#define __AC_TRIE_TREE_H__

#include "ac_define.h"
#include "ac_basic_type.h"
#include "ac_config.h"
#include "ac_interval_tree.h"

namespace AC
{
    template <typename Char>
    class TrieTree
    {
        typedef std::basic_string<Char>     StringType;
        typedef std::basic_string<Char>&    StringTypeRef;
        typedef LongState<Char>             StateType;
        typedef LongState<Char>&            StateTypeRef;
        typedef LongState<Char>*            StateTypePointer;
        typedef LongInterval<Char>          IntervalType;
        typedef LongInterval<Char>&         IntervalTypeRef;
        typedef std::vector<IntervalType>   IntervalContainer;

    public:
        TrieTree() : TrieTree(Config()) 
        {

        }
        TrieTree(const Config& config) 
            : root_(new LongState<Char>())
            , config_(config)
            , failure_ac_state_(false)
        {

        }
        ~TrieTree()
        {
            delete root_;
            root_ = nullptr;
        }

        TrieTree& RemoveOverlaps()
        {
            config_.SetAllowOverlaps(false);
            return (*this);
        }
        TrieTree& AllowWholeWords()
        {
            config_.SetAllowWholeWords(true);
            return (*this);
        }

        void AddMatchString(StringType text)
        {
            if (text.empty())
            {
                return;
            }

            StateTypePointer now_state = root_;
            for (const auto& c : text)
            {
                now_state = now_state->AddState(c);
            }
            now_state->AddLongInterval(text, number_keywords_++);
            failure_ac_state_ = false;
        }

        IntervalContainer Match(StringType text) 
        {
            __CheckConstructFailureState();

            size_t pos = 0;
            StateTypePointer now_state = root_;
            IntervalContainer collect;
            for (auto const &c: text)
            {
                now_state = __GetState(now_state, c);
                __StoreLongIntervals(pos++, now_state, collect);
            }
            if (config_.IsAllowWholeWords())
            {
                __RemovePartialMatches(text, collect);
            }
            if (!config_.IsAllowOverlaps())
            {
                IntervalTree<IntervalType> tree(typename IntervalTree<IntervalType>::IntervalContainer(collect.begin(), collect.end()));
                auto tmp = tree.RemoveOverlaps(collect);
                collect.swap(tmp);
            }
            return IntervalContainer(collect);
        }

    private:
        StateTypePointer __GetState(StateTypePointer now_state, Char c) const 
        {
            StateTypePointer result = now_state->NextState(c);
            while (!result) 
            {
                now_state = now_state->GetFailure();
                result = now_state->NextState(c);
            }
            return result;
        }

        void __CheckConstructFailureState() 
        {
            if (!failure_ac_state_)
            {
                __ConstructFailureState();
            }
        }

        void __ConstructFailureState()
        {
            std::queue<StateTypePointer> q;
            for (auto &depth_one_state : root_->GetSuccess())
            {
                depth_one_state->SetFailure(root_);
                q.push(depth_one_state);
            }
            failure_ac_state_ = true;

            while (!q.empty())
            {
                auto now_state = q.front();
                for (const auto& success_char : now_state->GetSuccessChar())
                {
                    StateTypePointer target_state = now_state->NextState(success_char);
                    q.push(target_state);
                    
                    StateTypePointer failure_state = now_state->GetFailure();
                    while (!failure_state->NextState(success_char)) 
                    {
                        failure_state = failure_state->GetFailure();
                    }

                    StateTypePointer new_failure_state = failure_state->NextState(success_char);
                    target_state->SetFailure(new_failure_state);
                    target_state->AddLongInterval(new_failure_state->GetIntervals());
                }
                q.pop();
            }
        }

        void __RemovePartialMatches(StringTypeRef search_text, IntervalContainer& collects) const
        {
            size_t size = search_text.size();
            IntervalContainer removes;
            for (const auto &collect : collects)
            {
                if ( (collect.Start() == 0) && (collect.End() + 1 == size) )
                {
                    continue;
                }
                removes.emplace_back(collect);
            }

            for (auto &r : removes)
            {
                collects.erase( std::find(collects.begin(), collects.end(), r) );
            }
        }

        void __StoreLongIntervals(size_t pos, StateTypePointer now_state, IntervalContainer& container) const
        {
	    auto long_container = now_state->GetIntervals();
            if (!long_container.empty())
            {
                for (const auto& i : long_container)
                {
                    auto interval_string = typename IntervalType::StringType(i.first);
                    container.emplace_back(IntervalType(pos - interval_string.size() + 1, pos, interval_string, i.second));
                }
            }
        }
    private:
        StateTypePointer    root_{nullptr};
        Config              config_;
        bool                failure_ac_state_{false};
        uint32_t            number_keywords_{0};
    };
}

#endif /* __AC_TRIE_TREE_H__ */
