#pragma once


// Call `utility::Buffer::realloc` immediately after `utility::Buffer::realloc_get`.
// This will trigger builtin memory corruption checker.
//#define ENABLE_BUFFER_REALLOC_AFTER_ALLOC

// Enables builtin `utility::Buffer` guards even in release (by default it is enabled ONLY in the Debug)
//#define ENABLE_PERSISTENT_BUFFER_GUARD_CHECK
