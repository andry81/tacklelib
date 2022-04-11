#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_SYNC_SPINLOCK_HPP
#define TACKLE_SYNC_SPINLOCK_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>

#include <tacklelib/tackle/sync/noop.hpp>

#include <atomic>


namespace tackle
{

    class spinlock
    {
    public:
        typedef enum { Locked, Unlocked } lock_state_t;

    private:
        // not copyable
        spinlock(const spinlock &);
        void operator =(const spinlock &);

    public:
        FORCE_INLINE spinlock() :
            m_state(Unlocked)
        {
        }

        FORCE_INLINE bool try_lock()
        {
            return (m_state.exchange(Locked, std::memory_order_acquire) != Locked);
        }

        FORCE_INLINE void lock()
        {
            while (!try_lock())
            {
                // busy-wait
                ::utility::noop_by_rand(16);
            }
        }

        FORCE_INLINE void unlock()
        {
            m_state.store(Unlocked, std::memory_order_release);
        }
        
    private:
        std::atomic<lock_state_t> m_state;
    };

}

#endif
