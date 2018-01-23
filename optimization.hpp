#pragma once

#define ENABLE_FORCE_INLINE
#define ENABLE_INTRINSIC
#define ENABLE_POF2_DEFINITIONS

// CAUTION:
//  1. The LTCG (Link Time Code Generation) can be 10x times longer than with lambdas!
//  2. Can be maximum 20% faster than with lambdas.
//#define USE_ASSERT_WITH_INPLACE_STRUCT_OPERATOR_INSTEAD_LAMBDAS
