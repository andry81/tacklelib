#pragma once


// Call `utility::Buffer::realloc` immediately after `utility::Buffer::realloc_get`.
// This will trigger builtin memory corruption checker.
//#define ENABLE_BUFFER_REALLOC_AFTER_ALLOC
