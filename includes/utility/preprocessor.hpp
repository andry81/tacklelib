#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_PREPROCESSOR_HPP
#define UTILITY_PREPROCESSOR_HPP

#include <tacklelib.hpp>


#define UTILITY_PP_STRINGIZE_(x) #x
#define UTILITY_PP_STRINGIZE(x) UTILITY_PP_STRINGIZE_(x)

#define UTILITY_PP_STRINGIZE_WIDE(x) UTILITY_PP_CONCAT(L, UTILITY_PP_STRINGIZE(x))

#define UTILITY_PP_CONCAT_(v1, v2) v1 ## v2
#define UTILITY_PP_CONCAT(v1, v2) UTILITY_PP_CONCAT_(v1, v2)
#define UTILITY_PP_CONCAT3(v1, v2, v3) UTILITY_PP_CONCAT(v1, UTILITY_PP_CONCAT(v2, v3))
#define UTILITY_PP_CONCAT4(v1, v2, v3, v4) UTILITY_PP_CONCAT(v1, UTILITY_PP_CONCAT3(v2, v3, v4))
#define UTILITY_PP_CONCAT5(v1, v2, v3, v4, v5) UTILITY_PP_CONCAT(v1, UTILITY_PP_CONCAT4(v2, v3, v4, v5))
#define UTILITY_PP_CONCAT6(v1, v2, v3, v4, v5, v6) UTILITY_PP_CONCAT(v1, UTILITY_PP_CONCAT5(v2, v3, v4, v5, v6))
#define UTILITY_PP_CONCAT7(v1, v2, v3, v4, v5, v6, v7) UTILITY_PP_CONCAT(v1, UTILITY_PP_CONCAT6(v2, v3, v4, v5, v6, v7))
#define UTILITY_PP_CONCAT8(v1, v2, v3, v4, v5, v6, v7, v8) UTILITY_PP_CONCAT(v1, UTILITY_PP_CONCAT7(v2, v3, v4, v5, v6, v7, v8))

#define UTILITY_PP_FILE_ __FILE__
#define UTILITY_PP_FILE UTILITY_PP_FILE_

#define UTILITY_PP_FILE_WIDE UTILITY_PP_CONCAT(L, UTILITY_PP_FILE)

#define UTILITY_PP_LINE_ __LINE__
#define UTILITY_PP_LINE UTILITY_PP_LINE_

#define UTILITY_PP_EMPTY_()
#define UTILITY_PP_EMPTY() UTILITY_PP_EMPTY_()

#define UTILITY_PP_IDENTITY(x) x
#define UTILITY_PP_IDENTITY_(x) UTILITY_PP_IDENTITY_(x)
#define UTILITY_PP_IDENTITY2_(v1, v2) v1, v2
#define UTILITY_PP_IDENTITY2(v1, v2) UTILITY_PP_IDENTITY2_(v1, v2)
#define UTILITY_PP_IDENTITY3_(v1, v2, v3) v1, v2, v3
#define UTILITY_PP_IDENTITY3(v1, v2, v3, v4) UTILITY_PP_IDENTITY3_(v1, v2, v3)
#define UTILITY_PP_IDENTITY4_(v1, v2, v3, v4) v1, v2, v3, v4
#define UTILITY_PP_IDENTITY4(v1, v2, v3, v4) UTILITY_PP_IDENTITY4_(v1, v2, v3, v4)
#define UTILITY_PP_IDENTITY5_(v1, v2, v3, v4, v5) v1, v2, v3, v4, v5
#define UTILITY_PP_IDENTITY5(v1, v2, v3, v4, v5) UTILITY_PP_IDENTITY5_(v1, v2, v3, v4, v5)
#define UTILITY_PP_IDENTITY6_(v1, v2, v3, v4, v5, v6) v1, v2, v3, v4, v5, v6
#define UTILITY_PP_IDENTITY6(v1, v2, v3, v4, v5, v6) UTILITY_PP_IDENTITY6_(v1, v2, v3, v4, v5, v6)
#define UTILITY_PP_IDENTITY7_(v1, v2, v3, v4, v5, v6, v7) v1, v2, v3, v4, v5, v6, v7
#define UTILITY_PP_IDENTITY7(v1, v2, v3, v4, v5, v6, v7) UTILITY_PP_IDENTITY7_(v1, v2, v3, v4, v5, v6, v7)
#define UTILITY_PP_IDENTITY8_(v1, v2, v3, v4, v5, v6, v7, v8) v1, v2, v3, v4, v5, v6, v7, v8
#define UTILITY_PP_IDENTITY8(v1, v2, v3, v4, v5, v6, v7, v8) UTILITY_PP_IDENTITY8_(v1, v2, v3, v4, v5, v6, v7, v8)

#define UTILITY_PP_LINE_TERMINATOR

#endif
