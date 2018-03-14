#pragma once


// Converts all FORCE_INLINE into `force no inline` both in debug and release.
//#define DEFINE_FORCE_INLINE_TO_FORCE_NO_INLINE

// Call `utility::Buffer::realloc` immediately after `utility::Buffer::realloc_get`.
// This will trigger builtin memory corruption checker.
//#define ENABLE_BUFFER_REALLOC_AFTER_ALLOC

// Enables builtin `utility::Buffer` guards even in release (by default it is enabled ONLY in the Debug)
//#define ENABLE_PERSISTENT_BUFFER_GUARD_CHECK

// Disables all verification and asserts.
//#define DISABLE_VERIFY_ASSERT

// increases chances to catch a memory corruption place.
//#define USE_MEMORY_REALLOCATION_IN_VERIFY_ASSERT
