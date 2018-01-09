#pragma once

#include <boost/smart_ptr.hpp>

namespace tackle
{
    typedef void ReleaseDeleterFunc(void *);

    // * not thread safe deleter with release support
    // * the deleter by user type together with the deleter by user value, deleter by user value has priority
    template <typename T, typename R = bool, typename Base = typename std::default_delete<T> >
    class ReleaseDeleter : private Base {
    public:
        // external release state:
        //  1. should be initialized before the deleter holder
        //  2. must be shared pointer to avoid delete of deleted memory
        //  3. if needs to avoid the deleter then must be true
        //  4. if needs to be thread safe with the holder, then must be either atomic or it's assignment should be
        //     strictly ordered before a call to the holder release function!
        typedef boost::shared_ptr<R> ReleaseStateSharedPtr;

    private:
        ReleaseStateSharedPtr release_state;
        ReleaseDeleterFunc * deleter;

    public:
        ReleaseDeleter(const ReleaseStateSharedPtr release_state_, ReleaseDeleterFunc deleter_ = nullptr) :
            release_state(release_state_),
            deleter(deleter_)
        {}

        void operator()(T* ptr)
        {
            if (*release_state.get()) return; // pointer has been released
            if (deleter) {
                deleter(ptr);
            }
            else {
                Base::operator()(ptr);
            }
        }
    };

    template<typename T>
    class SmartHandle
    {
        typedef boost::shared_ptr<bool> ReleaseStateSharedPtr;
        typedef boost::shared_ptr<void> SharedPtr;

        ReleaseStateSharedPtr   m_release; //at first because must be initialized before it's holder
        SharedPtr               m_pv;

    protected:
        SmartHandle(T * p = 0, ReleaseDeleterFunc deleter = nullptr);
    public:
        SmartHandle(const SmartHandle &) = default;
        ~SmartHandle();

    protected:
        void reset(T * p = 0, ReleaseDeleterFunc deleter = nullptr);
    public:
        operator bool() const;

        T * detach();
        T * get() const;
    };

    template<typename T>
    SmartHandle<T>::SmartHandle(T * p, ReleaseDeleterFunc deleter) :
        m_release(ReleaseStateSharedPtr(new bool(false))), // does not release by default
        m_pv(p, ReleaseDeleter<T>(m_release, deleter))
    {
    }

    template<typename T>
    SmartHandle<T>::~SmartHandle()
    {
    }

    template<typename T>
    void SmartHandle<T>::reset(T * p, ReleaseDeleterFunc deleter)
    {
        m_pv.reset(p, ReleaseDeleter<T>(m_release, deleter));
        *m_release.get() = false; // reset to default
    }

    template<typename T>
    SmartHandle<T>::operator bool() const
    {
        return !!m_pv.get();
    }

    template<typename T>
    T * SmartHandle<T>::detach()
    {
        *m_release.get() = true; // if needs to be thread safe, then this line must be either atomic or strictly ordered before the release call!
        T * p_detached = (T *)m_pv.get();
        m_pv.reset(); // call with release
        return p_detached;
    }

    template<typename T>
    T * SmartHandle<T>::get() const
    {
        return (T *)m_pv.get();
    }
}
