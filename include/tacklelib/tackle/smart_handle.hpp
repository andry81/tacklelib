#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_SMART_HANDLE_HPP
#define TACKLE_SMART_HANDLE_HPP

#include <tacklelib/tacklelib.hpp>

#include <tacklelib/utility/preprocessor.hpp>
#include <tacklelib/utility/platform.hpp>
#include <tacklelib/utility/type_traits.hpp>

#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
#  include <fmt/format.h>
#else
#  include <tacklelib/utility/utility.hpp>
#endif

#include <memory>
#include <stdexcept>
#include <functional>
#include <utility>


namespace tackle
{
    template <typename T>
    class smart_handle;

    template <typename T, typename R = bool, typename Base = std::default_delete<T> >
    class release_deleter;

    using release_deleter_func = std::function<void(void *)>; // to pass everything behaving like a function

    // * not thread safe deleter with release support
    // * the deleter by user type together with the deleter by user value, the deleter by user value has priority
    template <typename T, typename R, typename Base>
    class release_deleter : private Base {
    public:
        // external release state:
        //  1. should be initialized before the deleter holder
        //  2. must be shared pointer to avoid delete of deleted memory
        //  3. must be constructed through the std::make_shared to reduce memory allocation calls
        //  4. if needs to avoid the deleter then must be true
        //  5. if needs to be thread safe with the holder, then must be either atomic or it's assignment should be
        //     strictly ordered before a call to the holder release function!
        using release_state_shared_ptr = std::shared_ptr<R>;

        FORCE_INLINE release_deleter(release_state_shared_ptr release_state_ptr, release_deleter_func deleter = nullptr) :
            m_release_state_ptr(std::move(release_state_ptr)),
            m_deleter(std::move(deleter))
        {}

        FORCE_INLINE release_deleter(const release_deleter &) = default;
        FORCE_INLINE release_deleter(release_deleter &&) = default;

        FORCE_INLINE release_deleter & operator =(const release_deleter &) = default;
        FORCE_INLINE release_deleter & operator =(release_deleter &&) = default;

        FORCE_INLINE void operator()(T * ptr)
        {
            if (*m_release_state_ptr.get()) return; // pointer has been released
            if (m_deleter) {
                m_deleter(ptr);
            }
            else {
                return Base::operator()(ptr);
            }
        }

        FORCE_INLINE const release_state_shared_ptr & get_state() const
        {
            return m_release_state_ptr;
        }

        FORCE_INLINE const release_deleter_func & get_deleter() const
        {
            return m_deleter;
        }

        FORCE_INLINE void set_state(bool state)
        {
            auto * p = m_release_state_ptr.get();
            if (!p) {
                DEBUG_BREAK_THROW(true) std::runtime_error(
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_FORMAT_INSTEAD_UTILITY_STRING_FORMAT)
                    fmt::format("{:s}({:d}): deleter state is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE)
#else
                    utility::string_format(256, "%s(%d): deleter state is not allocated",
                        UTILITY_PP_FUNCSIG, UTILITY_PP_LINE)
#endif
                );
            }

            *p = state;
        }

        // deleter can reset ONLY together with the state
        FORCE_INLINE void reset(release_state_shared_ptr release_state_ptr, release_deleter_func deleter)
        {
            m_release_state_ptr = std::move(release_state_ptr);
            m_deleter = std::move(deleter);
        }

    private:
        release_state_shared_ptr    m_release_state_ptr;
        release_deleter_func        m_deleter;
    };

    template <typename T>
    class smart_handle
    {
    private:
        using SharedPtr     = std::shared_ptr<void>;

    public:
        using deleter_type  = release_deleter<T>;

    protected:
        FORCE_INLINE smart_handle(T * p = nullptr, release_deleter_func deleter_func = nullptr);
        FORCE_INLINE smart_handle(T * p, deleter_type deleter); // to call from derived implementation

    public:
        FORCE_INLINE smart_handle(const smart_handle &) = default;
        FORCE_INLINE smart_handle(smart_handle &&) = default;

        FORCE_INLINE smart_handle & operator =(const smart_handle &) = default;
        FORCE_INLINE smart_handle & operator =(smart_handle &&) = default;

        FORCE_INLINE ~smart_handle();

    protected:
        FORCE_INLINE void reset(T * p = nullptr, release_deleter_func deleter = nullptr);
        FORCE_INLINE void reset(T * p, deleter_type deleter); // to call from derived implementation

    public:
        FORCE_INLINE operator bool() const;

        FORCE_INLINE T * detach();
        FORCE_INLINE T * get() const;

    protected:
        SharedPtr   m_pv;
    };

    template <typename T>
    FORCE_INLINE smart_handle<T>::smart_handle(T * p, release_deleter_func deleter_func) :
        // does not release (false) by default
        m_pv(p, deleter_type(std::make_shared<bool>(bool(false)), std::move(deleter_func)))
    {
    }

    template <typename T>
    FORCE_INLINE smart_handle<T>::smart_handle(T * p, deleter_type deleter) :
        m_pv(p, std::move(deleter))
    {
    }

    template <typename T>
    FORCE_INLINE smart_handle<T>::~smart_handle()
    {
    }

    template <typename T>
    FORCE_INLINE void smart_handle<T>::reset(T * p, release_deleter_func deleter_func)
    {
        // does not release (false) by default
        m_pv.reset(p, deleter_type(std::make_shared<bool>(bool(false)), std::move(deleter_func)));
    }

    template <typename T>
    FORCE_INLINE void smart_handle<T>::reset(T * p, deleter_type deleter)
    {
        m_pv.reset(p, std::move(deleter));
    }

    template <typename T>
    FORCE_INLINE smart_handle<T>::operator bool() const
    {
        return m_pv.get() ? true : false;
    }

    template <typename T>
    FORCE_INLINE T * smart_handle<T>::detach()
    {
        auto * deleter = std::get_deleter<deleter_type>(m_pv);
        if (deleter) {
            // if needs to be thread safe, then this line must be either atomic or strictly ordered before the release call!
            deleter->set_state(true);
        }

        T * p_detached = get();

        m_pv.reset(); // call with release

        return p_detached;
    }

    template <typename T>
    FORCE_INLINE T * smart_handle<T>::get() const
    {
        return static_cast<T *>(m_pv.get());
    }
}

#endif
