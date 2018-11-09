#pragma once

// DO NOT REMOVE, exists to avoid private/public headers mixing!
#ifndef UTILITY_UTILITY_HPP
#define UTILITY_UTILITY_HPP

#include <tacklelib.hpp>

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/type_traits.hpp>
#include <utility/assert.hpp>
#include <utility/debug.hpp>
#include <utility/math.hpp>

#include <tackle/path_string.hpp>
#include <tackle/file_handle.hpp>

#ifdef UTILITY_COMPILER_CXX_MSC
#include <intrin.h>
#else
#include <x86intrin.h>  // Not just <immintrin.h> for compilers other than icc
#endif

#include <type_traits>
#include <limits>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <memory>
#include <cfloat>
#include <cmath>
#include <string>
#include <stdexcept>

#if defined(UTILITY_PLATFORM_POSIX)
#include <termios.h>
#include <unistd.h>
#endif

#include <cstdio>
#include <memory.h>

#if defined(UTILITY_PLATFORM_WINDOWS)
#include <conio.h>
#elif defined(UTILITY_PLATFORM_POSIX)
#else
#error platform is not implemented
#endif


namespace utility
{

    enum SharedAccess
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        SharedAccess_DenyRW     = _SH_DENYRW,   // deny read/write mode
        SharedAccess_DenyWrite  = _SH_DENYWR,   // deny write mode
        SharedAccess_DenyRead   = _SH_DENYRD,   // deny read mode
        SharedAccess_DenyNone   = _SH_DENYNO,   // deny none mode
        SharedAccess_Secure     = _SH_SECURE    // secure mode
#elif defined(UTILITY_PLATFORM_POSIX)
        SharedAccess_DenyRW     = 0x10,         // deny read/write mode
        SharedAccess_DenyWrite  = 0x20,         // deny write mode
        SharedAccess_DenyRead   = 0x30,         // deny read mode
        SharedAccess_DenyNone   = 0x40,         // deny none mode
        SharedAccess_Secure     = 0x80          // secure mode
#else
#error platform is not implemented
#endif
    };

    uint64_t get_file_size(const tackle::FileHandleA & file_handle);
    uint64_t get_file_size(const tackle::FileHandleW & file_handle);

    bool is_files_equal(const tackle::FileHandleA & left_file_handle, const tackle::FileHandleA & right_file_handle);
    bool is_files_equal(const tackle::FileHandleW & left_file_handle, const tackle::FileHandleW & right_file_handle);

    tackle::FileHandleA recreate_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0);
    tackle::FileHandleW recreate_file(const tackle::path_wstring & file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0);

    tackle::FileHandleA create_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0);
    tackle::FileHandleW create_file(const tackle::path_wstring & file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t size = 0, uint32_t fill_by = 0);

    tackle::FileHandleA open_file(const tackle::path_string & file_path, const char * mode, SharedAccess share_flags,
        size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0);
    tackle::FileHandleW open_file(const tackle::path_wstring & file_path, const wchar_t * mode, SharedAccess share_flags,
        size_t creation_size = 0, size_t resize_if_existed = -1, uint32_t fill_by_on_creation = 0);

    bool is_directory_path(const tackle::path_string & path);
    bool is_directory_path(const tackle::path_wstring & path);

    bool is_regular_file(const tackle::path_string & path);
    bool is_regular_file(const tackle::path_wstring & path);

    bool is_symlink_path(const tackle::path_string & path);
    bool is_symlink_path(const tackle::path_wstring & path);

    bool is_path_exists(const tackle::path_string & path);
    bool is_path_exists(const tackle::path_wstring & path);

    bool create_directory(const tackle::path_string & path, bool throw_on_error);
    bool create_directory(const tackle::path_wstring & path, bool throw_on_error);

    bool create_directory_if_not_exist(const tackle::path_string & path, bool throw_on_error); // no exception if directory already exists
    bool create_directory_if_not_exist(const tackle::path_wstring & path, bool throw_on_error); // no exception if directory already exists

    void create_directory_symlink(const tackle::path_string & to, const tackle::path_string & from, bool throw_on_error);
    void create_directory_symlink(const tackle::path_wstring & to, const tackle::path_wstring & from, bool throw_on_error);

    bool create_directories(const tackle::path_string & path, bool throw_on_error);
    bool create_directories(const tackle::path_wstring & path, bool throw_on_error);

    bool remove_directory(const tackle::path_string & path, bool recursively, bool throw_on_error);
    bool remove_directory(const tackle::path_wstring & path, bool recursively, bool throw_on_error);

    bool remove_file(const tackle::path_string & path, bool throw_on_error);
    bool remove_file(const tackle::path_wstring & path, bool throw_on_error);

    bool remove_symlink(const tackle::path_string & path, bool throw_on_error);
    bool remove_symlink(const tackle::path_wstring & path, bool throw_on_error);

    bool is_relative_path(const tackle::path_string & path);
    bool is_relative_path(const tackle::path_wstring & path);

    bool is_relative_path(tackle::path_string && path);
    bool is_relative_path(tackle::path_wstring && path);

    bool is_absolute_path(const tackle::path_string & path);
    bool is_absolute_path(const tackle::path_wstring & path);

    bool is_absolute_path(tackle::path_string && path);
    bool is_absolute_path(tackle::path_wstring && path);

    tackle::path_string get_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path, bool throw_on_error);
    tackle::path_wstring get_relative_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path, bool throw_on_error);

    tackle::path_string get_absolute_path(const tackle::path_string & from_path, const tackle::path_string & to_path);
    tackle::path_wstring get_absolute_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path);

    tackle::path_string get_absolute_path(const tackle::path_string & path, bool throw_on_error);
    tackle::path_wstring get_absolute_path(const tackle::path_wstring & path, bool throw_on_error);

    tackle::path_string get_current_path(bool throw_on_error, string_identity = string_identity{});
    tackle::path_wstring get_current_path(bool throw_on_error, wstring_identity);

    std::string get_file_name(const tackle::path_string & path);
    std::wstring get_file_name(const tackle::path_wstring & path);

    std::string get_file_name_stem(const tackle::path_string & path);
    std::wstring get_file_name_stem(const tackle::path_wstring & path);

    tackle::path_string get_module_file_path(string_identity = string_identity{});
    tackle::path_wstring get_module_file_path(wstring_identity);

    tackle::path_string get_module_dir_path(string_identity = string_identity{});
    tackle::path_wstring get_module_dir_path(wstring_identity);

    tackle::path_string get_lexically_normal_path(const tackle::path_string & path);
    tackle::path_wstring get_lexically_normal_path(const tackle::path_wstring & path);

    tackle::path_string get_lexically_relative_path(const tackle::path_string & from_path, const tackle::path_string & to_path);
    tackle::path_wstring get_lexically_relative_path(const tackle::path_wstring & from_path, const tackle::path_wstring & to_path);

    tackle::path_string convert_to_uniform_path(const tackle::path_string & path);
    tackle::path_wstring convert_to_uniform_path(const tackle::path_wstring & path);

    tackle::path_string convert_to_native_path(const tackle::path_string & path);
    tackle::path_wstring convert_to_native_path(const tackle::path_wstring & path);

    template<typename T>
    FORCE_INLINE T str_to_int(const std::string & str, std::size_t * pos = nullptr, int base = 10, bool throw_on_error = false)
    {
        T i{}; // value initialization default construction is required in case if an error has happend and throw_on_error = false

        try {
            i = static_cast<T>(std::stoi(str, pos, base));
        }
        // by default suppress exceptions
        catch (const std::invalid_argument & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            DEBUG_BREAK_IN_DEBUGGER(true);
            if (throw_on_error) {
                throw;
            }
        }
        catch (const std::out_of_range & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            DEBUG_BREAK_IN_DEBUGGER(true);
            if (throw_on_error) {
                throw;
            }
        }
        catch (const std::exception & ex) {
            UTILITY_UNUSED_STATEMENT(ex);
            DEBUG_BREAK_IN_DEBUGGER(true);
            if (throw_on_error) {
                throw;
            }
        }
        catch (...) {
            DEBUG_BREAK_IN_DEBUGGER(true);
            if (throw_on_error) {
                throw;
            }
        }

        return i;
    }

    template<typename T>
    FORCE_INLINE std::string int_to_hex(T i, size_t padding = sizeof(T) * 2)
    {
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
        const std::string fmt_format = tackle::string_format(256, "{:%s%ux}", padding ? "0" : "", padding ? padding : 0); // faster than fmt format
        return fmt::format(fmt_format, int64_t(i));
#else
        std::stringstream stream;
        stream << std::setfill('0') << std::setw(padding) << std::hex << i;
        return stream.str();
#endif
    }

    template<typename T>
    FORCE_INLINE std::string int_to_dec(T i, size_t padding = sizeof(T) * 2)
    {
#if ERROR_IF_EMPTY_PP_DEF(USE_FMT_LIBRARY_INSTEAD_STD_STRINGSTREAMS)
        const std::string fmt_format = tackle::string_format(256, "{:%s%ud}", padding ? "0" : "", padding ? padding : 0); // faster than fmt format
        return fmt::format(fmt_format, int64_t(i));
#else
        std::stringstream stream;
        stream << std::setfill('0') << std::setw(padding) << std::dec << i;
        return stream.str();
#endif
    }

    template<typename T>
    FORCE_INLINE void int_to_bin_forceinline(std::string & ret, T i, bool first_bit_is_lowest_bit = false)
    {
        STATIC_ASSERT_TRUE(std::is_trivially_copyable<T>::value, "T must be a trivial copy type");

        CONSTEXPR const size_t num_bytes = sizeof(T);

        ret.resize(num_bytes * CHAR_BIT);

        char * data_ptr = &ret[0]; // faster than for-ed operator[] in the Debug

        size_t char_offset;
        const uint32_t * chunks_ptr = (const uint32_t *)&i;

        const size_t num_whole_chunks = num_bytes / 4;
        const size_t chunks_remainder = num_bytes % 4;

        if (first_bit_is_lowest_bit) {
            char_offset = 0;

            for (size_t i = 0; i < num_whole_chunks; i++, chunks_ptr++) {
                for (size_t j = 0; j < 32; j++, char_offset++) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }
            if (chunks_remainder) {
                for (size_t j = 0; j < chunks_remainder * CHAR_BIT; j++, char_offset++) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }

            data_ptr[char_offset] = '\0';
        }
        else {
            char_offset = num_bytes * CHAR_BIT;

            data_ptr[char_offset] = '\0';

            for (size_t i = 0; i < num_whole_chunks; i++, chunks_ptr++) {
                for (size_t j = 0; j < 32; j++, char_offset--) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }
            if (chunks_remainder) {
                for (size_t j = 0; j < chunks_remainder * CHAR_BIT; j++, char_offset--) {
                    data_ptr[char_offset] = (chunks_ptr[i] & (0x01U << j)) ? '1' : '0';
                }
            }
        }
    }

    template<typename T>
    inline std::string int_to_bin(T i, bool first_bit_is_lowest_bit = false)
    {
        std::string res;
        int_to_bin_forceinline(res, i, first_bit_is_lowest_bit);
        return res;
    }

    FORCE_INLINE_ALWAYS uint8_t reverse(uint8_t byte)
    {
        byte = (byte & 0xF0) >> 4 | (byte & 0x0F) << 4;
        byte = (byte & 0xCC) >> 2 | (byte & 0x33) << 2;
        byte = (byte & 0xAA) >> 1 | (byte & 0x55) << 1;
        return byte;
    }

    template <typename T>
    FORCE_INLINE T reverse(T value)
    {
        T res = 0;
        for (size_t i = 0; i < sizeof(value) * CHAR_BIT; i++) {
            if (value & (0x01U << i)) {
                res |= (0x01U << (sizeof(value) * CHAR_BIT - i - 1));
            }
        }
        return res;
    }

    template<typename T>
    FORCE_INLINE uint32_t t_rotl32(uint32_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint32_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint32_t)");
        const uint32_t byte_mask = uint32_t(-1) >> (CHAR_BIT * (sizeof(uint32_t) - sizeof(T)));
        const uint32_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & ((n << c) | ((byte_mask & n) >> (mask & math::negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint32_t t_rotr32(uint32_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint32_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint32_t)");
        const uint32_t byte_mask = uint32_t(-1) >> (CHAR_BIT * (sizeof(uint32_t) - sizeof(T)));
        const uint32_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & (((byte_mask & n) >> c) | (n << (mask & math::negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint64_t t_rotl64(uint64_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint64_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint64_t)");
        const uint64_t byte_mask = uint64_t(-1) >> (CHAR_BIT * (sizeof(uint64_t) - sizeof(T)));
        const uint64_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & ((n << c) | ((byte_mask & n) >> (mask & math::negate(c))));
    }

    template<typename T>
    FORCE_INLINE uint64_t t_rotr64(uint64_t n, unsigned int c)
    {
        STATIC_ASSERT_GE(sizeof(uint64_t), sizeof(T), "sizeof(T) must be less or equal to the sizeof(uint64_t)");
        const uint64_t byte_mask = uint64_t(-1) >> (CHAR_BIT * (sizeof(uint64_t) - sizeof(T)));
        const uint64_t mask = (CHAR_BIT * sizeof(T) - 1);
        c &= mask;
        return byte_mask & (((byte_mask & n) >> c) | (n << (mask & math::negate(c))));
    }

    FORCE_INLINE_ALWAYS uint32_t rotl8(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl8(unsigned char(n), unsigned char(c));
#else
        return t_rotl32<uint8_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t rotr8(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr8(unsigned char(n), unsigned char(c));
#else
        return t_rotr32<uint8_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t rotl16(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl16(unsigned short(n), unsigned char(c));
#else
        return t_rotl32<uint16_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t rotr16(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr16(unsigned short(n), unsigned char(c));
#else
        return t_rotr32<uint16_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t rotl32(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl(unsigned int(n), int(c));
#else
        return t_rotl32<uint32_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint32_t rotr32(uint32_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr(unsigned int(n), int(c));
#else
        return t_rotr32<uint32_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint64_t rotl64(uint64_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotl64(unsigned long long(n), int(c));
#else
        return t_rotl64<uint64_t>(n, c);
#endif
    }

    FORCE_INLINE_ALWAYS uint64_t rotr64(uint64_t n, unsigned int c)
    {
#if defined(UTILITY_COMPILER_CXX_MSC) && ERROR_IF_EMPTY_PP_DEF(ENABLE_INTRINSIC)
        return _rotr64(unsigned long long(n), int(c));
#else
        return t_rotr64<uint64_t>(n, c);
#endif
    }

    // reads from keypress, doesn't echo
    inline int getch()
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return ::_getch();
#elif defined(UTILITY_PLATFORM_POSIX)
        struct termios oldattr, newattr;
        int ch;
        tcgetattr(STDIN_FILENO, &oldattr);
        newattr = oldattr;
        newattr.c_lflag &= ~(ICANON | ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
        ch = getchar();
        tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
        return ch;
#endif
    }

    // reads from keypress, echoes
    inline int getche()
    {
#if defined(UTILITY_PLATFORM_WINDOWS)
        return ::_getche();
#elif defined(UTILITY_PLATFORM_POSIX)
        struct termios oldattr, newattr;
        int ch;
        tcgetattr(STDIN_FILENO, &oldattr);
        newattr = oldattr;
        newattr.c_lflag &= ~(ICANON);
        tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
        ch = getchar();
        tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
        return ch;
#endif
    }

    // reset std::stringstream object
    // Based on: https://stackoverflow.com/questions/7623650/resetting-a-stringstream
    //
    FORCE_INLINE void reset_stringstream(std::stringstream & ss)
    {
        const static std::stringstream initial;

        ss.str(std::string{});
        ss.clear();
        ss.copyfmt(initial);
    }

    FORCE_INLINE double modf(double d)
    {
        double whole;
        return std::modf(d, &whole);
    }


    FORCE_INLINE double calibrate_tick_step_to_closest_power_of_10(double min, double max, size_t ticks)
    {
        DEBUG_ASSERT_LT(min, max);
        DEBUG_ASSERT_LT(0U, ticks);

        const double distance = max - min;

        double tick_step = distance / ticks;

        int tick_step_exp;
        std::frexp(tick_step, &tick_step_exp);

        if (tick_step < 1.0) {
            size_t rounded_integer_part_numerator;
            size_t rounded_integer_part_denominator;

            const double tick_step_power_of_10 = tick_step_exp * std::log(2) / std::log(10);
            DEBUG_ASSERT_GE(0, tick_step_power_of_10);

            const size_t num_digits_in_power_of_10 = size_t(std::floor(tick_step_power_of_10 >= 0 ? tick_step_power_of_10 : -tick_step_power_of_10 + 1));
            const int signed_num_digits_in_power_of_10 = tick_step_power_of_10 >= 0 ? num_digits_in_power_of_10 : -int(num_digits_in_power_of_10);

            double closest_value_with_integer_part = tick_step * std::pow(10.0, double(num_digits_in_power_of_10));

            if (closest_value_with_integer_part >= 5) {
                rounded_integer_part_numerator = 5;
                rounded_integer_part_denominator = 1;
            }
            else {
                rounded_integer_part_numerator = 25;
                rounded_integer_part_denominator = 10;
            }

            tick_step = rounded_integer_part_numerator *
                std::pow(10.0, tick_step_power_of_10 >= 0 ?
                    double(num_digits_in_power_of_10) : -double(num_digits_in_power_of_10)) / rounded_integer_part_denominator; // drop the rest fraction

            // calibration through overflow/underflow

            double prev_tick_step;
            double next_tick_step = tick_step;
            size_t rounded_integer_part_next_numerator = rounded_integer_part_numerator;

            if (next_tick_step * ticks < 2 * distance) {
                do {
                    // step still not big enough, increase step in twice
                    rounded_integer_part_numerator = rounded_integer_part_next_numerator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_numerator *= 2;
                    next_tick_step = rounded_integer_part_next_numerator *
                        std::pow(10.0, double(signed_num_digits_in_power_of_10)) / rounded_integer_part_denominator;
                } while (next_tick_step * ticks < 2 * distance);

                next_tick_step = tick_step = prev_tick_step;
            }

            size_t rounded_integer_part_next_denominator = rounded_integer_part_denominator;

            if (next_tick_step * ticks >= distance) {
                do {
                    // step still not small enough, decrease step in twice
                    rounded_integer_part_denominator = rounded_integer_part_next_denominator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_denominator *= 2;
                    next_tick_step = rounded_integer_part_numerator *
                        std::pow(10.0, double(signed_num_digits_in_power_of_10)) / rounded_integer_part_next_denominator;
                } while (next_tick_step * ticks >= distance);

                tick_step = prev_tick_step;
            }
        }
        else {
            double closest_value_with_integer_part = std::floor(tick_step / 5) * 5;
            if (!closest_value_with_integer_part) {
                closest_value_with_integer_part = std::floor(tick_step);
            }

            double rounded_integer_part_numerator = size_t(closest_value_with_integer_part + 0.5);
            double rounded_integer_part_denominator = 1;

            // calibration through overflow/underflow

            double prev_tick_step;
            double next_tick_step = tick_step;
            double rounded_integer_part_next_numerator = rounded_integer_part_numerator;

            if (next_tick_step * ticks < 2 * distance) {
                do {
                    // step still not big enough, increase step in twice
                    rounded_integer_part_numerator = rounded_integer_part_next_numerator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_numerator *= 2;
                    next_tick_step = rounded_integer_part_next_numerator / rounded_integer_part_denominator;
                } while (next_tick_step * ticks < 2 * distance);

                next_tick_step = tick_step = prev_tick_step;
            }

            double rounded_integer_part_next_denominator = rounded_integer_part_denominator;

            if (next_tick_step * ticks >= distance) {
                do {
                    // step still not small enough, decrease step in twice
                    rounded_integer_part_denominator = rounded_integer_part_next_denominator;
                    prev_tick_step = next_tick_step;

                    rounded_integer_part_next_denominator *= 2;
                    next_tick_step = rounded_integer_part_numerator / rounded_integer_part_next_denominator;
                } while (next_tick_step * ticks >= distance);

                tick_step = prev_tick_step;
            }
        }

        return tick_step;
    }
}

#endif
