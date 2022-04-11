#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_SYNC_SCOPEDLOCK_HPP
#define TACKLE_SYNC_SCOPEDLOCK_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/platform.hpp>

#include <tacklelib/tackle/sync/spinlock.hpp>


namespace tackle
{

    template<typename T>
    class scoped_lock
    {
    private:
        T * m_locker;   // T should have lock/unlock functions
        T * m_released;

    private:
        // not copyable
        scoped_lock(const scoped_lock &);
        void operator =(const scoped_lock &);

    public:
        FORCE_INLINE scoped_lock(T* locker) :
            m_locker(locker),
            m_released(NULL)
        {
            acquire();
        }
        
        FORCE_INLINE ~scoped_lock()
        {
            release(true);
        }

        FORCE_INLINE void acquire()
        {
            acquire(m_released);
        }

        FORCE_INLINE void acquire(T* locker)
        {
            if (locker != NULL && locker != m_locker) {
                release(true); // release previous object to acquire new one
            }
            if(locker) {
                locker->lock();
                m_locker = locker;
            }
        }

        FORCE_INLINE void release(bool dismiss = false) // dismiss released object (avoid reacquire it)
        {
            if(m_locker) {
                m_locker->unlock();
                if (!dismiss) {
                    m_released = m_locker; // to enable reacquire later
                }
                else {
                    m_released = NULL;
                }
                m_locker = NULL;
            }
        }
    };

}

#endif
