#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_UTILITY_HPP
#define UTILITY_UTILITY_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>

#define if_break(x) if(!(x)); else switch(0) case 0: default:
#define if_break2(label, x) if(!(x)) label:; else switch(0) case 0: default:

#define SCOPED_TYPEDEF(type_, typedef_) using typedef_ = struct { typedef type_ type; }

#endif
