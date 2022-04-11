#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef TACKLE_SYNC_NOOP_HPP
#define TACKLE_SYNC_NOOP_HPP

#include <tacklelib/tacklelib.hpp>

#include <cstdlib>


namespace utility
{
    FORCE_INLINE void noop_by_rand(int num)
    {
        while (num--) rand();
    }
}

#endif
