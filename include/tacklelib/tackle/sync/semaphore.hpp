#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_SYNC_SEMAPHORE_HPP
#define TACKLE_SYNC_SEMAPHORE_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>

#include <tacklelib/tackle/sync/spinlock.hpp>
#include <tacklelib/tackle/sync/scopedlock.hpp>


namespace tackle
{

    class semaphore
    {
        typedef scoped_lock<spinlock> scoped_spinlock_t;

        unsigned int              m_count;
        spinlock                  m_spinlock;
        std::condition_variable   m_condition;
        std::mutex                m_mutex;

    private:
        // not copyable
        semaphore(const semaphore&);
        void operator =(const semaphore &);

    public:
        FORCE_INLINE explicit semaphore(unsigned int count = 0) :
            m_count(count)
        {
        }

        FORCE_INLINE void reset(unsigned int count)
        {
            std::unique_lock<std::mutex> lock(m_mutex);
            {
                scoped_spinlock_t lock(&m_spinlock);
                m_count = count;
            }
            m_condition.notify_all();
        }

        FORCE_INLINE unsigned int get_count()
        {
            scoped_spinlock_t lock(&m_spinlock);
            return m_count;
        }

        FORCE_INLINE void release()
        {
            {
                // we have spinning only for the count, a condition variable has it's own synchronization
                scoped_spinlock_t lock(&m_spinlock);
                ++m_count;
            }
            std::unique_lock<std::mutex> lock(m_mutex);
            m_condition.notify_one();
        }

        FORCE_INLINE void acquire()
        {
            scoped_spinlock_t lock(&m_spinlock);
            while (m_count == 0)
            {
                // we have spinning only for the count, a condition variable has it's own synchronization
                lock.release();
                {
                    std::unique_lock<std::mutex> lock(m_mutex);
                    m_condition.wait(lock);
                }
                lock.acquire();
            }
            --m_count;
        }
    };

}

#endif
