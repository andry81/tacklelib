#include "test_common.hpp"

#include <utility/math.hpp>


TEST(FunctionsTest, ROTL)
{
    ASSERT_EQ(::utility::rotl8(0b11000000, 1), 0b10000001);
    ASSERT_EQ(::utility::rotl8(0b11000001, 2), 0b00000111);
    ASSERT_EQ(::utility::rotl8(0b01111110, 1), 0b11111100);
    ASSERT_EQ(::utility::rotl8(0b00111111, 1), 0b01111110);
    ASSERT_EQ(::utility::rotl16(0b1100000000000000, 1), 0b1000000000000001);
    ASSERT_EQ(::utility::rotl16(0b1100000000000001, 2), 0b0000000000000111);
    ASSERT_EQ(::utility::rotl32(0b11000000000000000000000000000000, 1), 0b10000000000000000000000000000001);
    ASSERT_EQ(::utility::rotl32(0b11000000000000000000000000000001, 2), 0b00000000000000000000000000000111);
    ASSERT_EQ(::utility::rotl64(0b1100000000000000000000000000000000000000000000000000000000000000, 1), 0b1000000000000000000000000000000000000000000000000000000000000001);
    ASSERT_EQ(::utility::rotl64(0b1100000000000000000000000000000000000000000000000000000000000001, 2), 0b0000000000000000000000000000000000000000000000000000000000000111);
}

TEST(FunctionsTest, ROTR)
{
    ASSERT_EQ(::utility::rotr8(0b00000011, 1), 0b10000001);
    ASSERT_EQ(::utility::rotr8(0b10000011, 2), 0b11100000);
    ASSERT_EQ(::utility::rotr8(0b01111110, 1), 0b00111111);
    ASSERT_EQ(::utility::rotr8(0b11111100, 1), 0b01111110);
    ASSERT_EQ(::utility::rotr16(0b0000000000000011, 1), 0b1000000000000001);
    ASSERT_EQ(::utility::rotr16(0b1000000000000011, 2), 0b1110000000000000);
    ASSERT_EQ(::utility::rotr32(0b00000000000000000000000000000011, 1), 0b10000000000000000000000000000001);
    ASSERT_EQ(::utility::rotr32(0b10000000000000000000000000000011, 2), 0b11100000000000000000000000000000);
    ASSERT_EQ(::utility::rotr64(0b0000000000000000000000000000000000000000000000000000000000000011, 1), 0b1000000000000000000000000000000000000000000000000000000000000001);
    ASSERT_EQ(::utility::rotr64(0b1000000000000000000000000000000000000000000000000000000000000011, 2), 0b1110000000000000000000000000000000000000000000000000000000000000);
}

TEST(FunctionsTest, int_log2_floor)
{
    for (int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_log2_floor(i), int(log2(i)));
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_log2_floor(i), unsigned int(log2(i)));
    }
}

TEST(FunctionsTest, int_log2_ceil)
{
    for (int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_log2_ceil(i), int(log2(i + i - 1)));
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_log2_ceil(i), unsigned int(log2(i + i - 1)));
    }
}

TEST(FunctionsTest, int_pof2_floor)
{
    for (int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_pof2_floor(i), pow(2, int(log2(i))));
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_pof2_floor(i), pow(2, unsigned int(log2(i))));
    }
}

TEST(FunctionsTest, int_pof2_ceil)
{
    for (int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_pof2_ceil(i), pow(2, int(log2(i + i - 1))));
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        ASSERT_EQ(::math::int_pof2_ceil(i), pow(2, unsigned int(log2(i + i - 1))));
    }
}

TEST(FunctionsTest, int_log2_pof2_floor)
{
    for (int i = 1; i < 1000000; i++) {
        int pof2_floor_value = -1;
        const int log2_floor_value_eta = int(log2(i));
        ASSERT_EQ(::math::int_log2_floor(i, &pof2_floor_value), log2_floor_value_eta);
        ASSERT_EQ(pof2_floor_value, pow(2, log2_floor_value_eta));
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        unsigned int pof2_floor_value = -1;
        const unsigned int log2_floor_value_eta = unsigned int(log2(i));
        ASSERT_EQ(::math::int_log2_floor(i, &pof2_floor_value), log2_floor_value_eta);
        ASSERT_EQ(pof2_floor_value, pow(2, log2_floor_value_eta));
    }
}

TEST(FunctionsTest, int_log2_pof2_ceil)
{
    for (int i = 1; i < 1000000; i++) {
        int pof2_ceil_value = -1;
        const int log2_ceil_value_eta = int(log2(i + i - 1));
        ASSERT_EQ(::math::int_log2_ceil(i, &pof2_ceil_value), log2_ceil_value_eta);
        ASSERT_EQ(pof2_ceil_value, pow(2, log2_ceil_value_eta));
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        unsigned int pof2_ceil_value = -1;
        const unsigned int log2_ceil_value_eta = unsigned int(log2(i + i - 1));
        ASSERT_EQ(::math::int_log2_ceil(i, &pof2_ceil_value), log2_ceil_value_eta);
        ASSERT_EQ(pof2_ceil_value, pow(2, log2_ceil_value_eta));
    }
}

TEST(FunctionsTest, int_log2_pof2_floor_time)
{
    for (int i = 1; i < 1000000; i++) {
        int pof2_floor_value = -1;
        const int log2_floor_value_eta = int(log2(i));
        ASSERT_EQ(::math::int_log2_floor(i, &pof2_floor_value), log2_floor_value_eta);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(pof2_floor_value);
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        unsigned int pof2_floor_value = -1;
        const unsigned int log2_floor_value_eta = unsigned int(log2(i));
        ASSERT_EQ(::math::int_log2_floor(i, &pof2_floor_value), log2_floor_value_eta);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(pof2_floor_value);
    }
}

TEST(FunctionsTest, int_log2_pof2_ceil_time)
{
    for (int i = 1; i < 1000000; i++) {
        int pof2_ceil_value = -1;
        const int log2_ceil_value_eta = int(log2(i + i - 1));
        ASSERT_EQ(::math::int_log2_ceil(i, &pof2_ceil_value), log2_ceil_value_eta);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(pof2_ceil_value);
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        unsigned int pof2_ceil_value = -1;
        const unsigned int log2_ceil_value_eta = unsigned int(log2(i + i - 1));
        ASSERT_EQ(::math::int_log2_ceil(i, &pof2_ceil_value), log2_ceil_value_eta);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(pof2_ceil_value);
    }
}

TEST(FunctionsTest, int_stdlib_log2_floor_time)
{
    for (int i = 1; i < 1000000; i++) {
        const int log2_floor_value = int(log2(i));
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_floor_value);
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        const unsigned int log2_floor_value = unsigned int(log2(i));
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_floor_value);
    }
}

TEST(FunctionsTest, int_thislib_log2_floor_time)
{
    for (int i = 1; i < 1000000; i++) {
        const int log2_floor_value = ::math::int_log2_floor(i);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_floor_value);
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        const unsigned int log2_floor_value = ::math::int_log2_floor(i);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_floor_value);
    }
}

TEST(FunctionsTest, int_stdlib_log2_ceil_time)
{
    for (int i = 1; i < 1000000; i++) {
        const int log2_ceil_value = int(log2(i + i - 1));
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_ceil_value);
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        const unsigned int log2_ceil_value = unsigned int(log2(i + i - 1));
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_ceil_value);
    }
}

TEST(FunctionsTest, int_thislib_log2_ceil_time)
{
    for (int i = 1; i < 1000000; i++) {
        const int log2_ceil_value = ::math::int_log2_ceil(i);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_ceil_value);
    }
    for (unsigned int i = 1; i < 1000000; i++) {
        const unsigned int log2_ceil_value = ::math::int_log2_ceil(i);
        UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(log2_ceil_value);
    }
}

TEST(FunctionsTest, unroll_copy)
{
    const int ref[16] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    int out[16];

    memset(out, 0, utility::static_size(out) * sizeof(out[0]));
    UTILITY_COPY(ref, out, 5, 5);
    ASSERT_TRUE(!memcmp(ref, out, 5) && !out[5]);

    memset(out, 0, utility::static_size(out) * sizeof(out[0]));
    UTILITY_COPY(ref, out, 3, 7);
    ASSERT_TRUE(!memcmp(ref, out, 3) && !out[3]);

    memset(out, 0, utility::static_size(out) * sizeof(out[0]));
    UTILITY_COPY(ref, out, 7, 3);
    ASSERT_TRUE(!memcmp(ref, out, 7) && !out[7]);
}

template <size_t t_out_ref_size, size_t t_ref_size>
void test_stride_copy(size_t stride_size, size_t stride_step,
    size_t ref_size, size_t from_buf_offset_, const int(&ref)[t_ref_size],
    size_t out_size, const int (& out_ref)[t_out_ref_size])
{
    ASSERT_GE(ref_size, out_size);
    ASSERT_GE(out_size, t_out_ref_size);
    int out[(std::max)(t_ref_size, t_out_ref_size) + 1];
    size_t to_buf_offset;

    memset(out, 0, utility::static_size(out) * sizeof(out[0]));
    const size_t from_buf_offset = UTILITY_STRIDE_COPY(to_buf_offset, ref, ref_size, stride_size, stride_step, out, out_size);
    ASSERT_TRUE(!memcmp(out_ref, out, utility::static_size(out_ref) * sizeof(out_ref[0])));
    if (out_size != t_out_ref_size) {
        ASSERT_FALSE(out[out_size]);
    }
    ASSERT_EQ(from_buf_offset, from_buf_offset_);
    ASSERT_EQ(to_buf_offset, utility::static_size(out_ref));
}

TEST(FunctionsTest, stride_copy)
{
    const int ref[16] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

    test_stride_copy(1, 1, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    test_stride_copy(1, 3, 16, 16, ref, 16, { 1, 4, 7, 10, 13, 16 });
    test_stride_copy(1, 4, 16, 16, ref, 16, { 1, 5, 9, 13 });
    test_stride_copy(1, 5, 16, 16, ref, 16, { 1, 6, 11, 16 });
    test_stride_copy(2, 2, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    test_stride_copy(2, 3, 16, 16, ref, 16, { 1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16 });
    test_stride_copy(2, 4, 16, 16, ref, 16, { 1, 2, 5, 6, 9, 10, 13, 14 });
    test_stride_copy(2, 5, 16, 16, ref, 16, { 1, 2, 6, 7, 11, 12, 16 });
    test_stride_copy(3, 3, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    test_stride_copy(3, 4, 16, 16, ref, 16, { 1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15 });
    test_stride_copy(3, 5, 16, 16, ref, 16, { 1, 2, 3, 6, 7, 8, 11, 12, 13, 16 });
    test_stride_copy(3, 6, 16, 16, ref, 16, { 1, 2, 3, 7, 8, 9, 13, 14, 15 });
    test_stride_copy(4, 4, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    test_stride_copy(4, 5, 16, 16, ref, 16, { 1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 16 });
    test_stride_copy(4, 6, 16, 16, ref, 16, { 1, 2, 3, 4, 7, 8, 9, 10, 13, 14, 15, 16 });
    test_stride_copy(5, 5, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    test_stride_copy(5, 6, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 13, 14, 15, 16 });
    test_stride_copy(5, 7, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 15, 16 });
    test_stride_copy(6, 6, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
    test_stride_copy(6, 7, 16, 16, ref, 16, { 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16 });

    test_stride_copy(1, 1, 16, 10, ref, 10, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    test_stride_copy(1, 3, 16, 16, ref, 10, { 1, 4, 7, 10, 13, 16 });
    test_stride_copy(1, 4, 16, 16, ref, 10, { 1, 5, 9, 13 });
    test_stride_copy(1, 5, 16, 16, ref, 10, { 1, 6, 11, 16 });
    test_stride_copy(2, 2, 16, 10, ref, 10, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    test_stride_copy(2, 3, 16, 15, ref, 10, { 1, 2, 4, 5, 7, 8, 10, 11, 13, 14 });
    test_stride_copy(2, 4, 16, 16, ref, 10, { 1, 2, 5, 6, 9, 10, 13, 14 });
    test_stride_copy(2, 5, 16, 16, ref, 10, { 1, 2, 6, 7, 11, 12, 16 });
    //test_stride_copy(3, 3, 16, 10, ref, 10, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    //test_stride_copy(3, 4, 16, 16, ref, 10, { 1, 2, 3, 5, 6, 7, 9, 10, 11, 13 });
    //test_stride_copy(3, 5, 16, 16, ref, 10, { 1, 2, 3, 6, 7, 8, 11, 12, 13, 16 });
    //test_stride_copy(3, 6, 16, 16, ref, 10, { 1, 2, 3, 7, 8, 9, 13, 14, 15 });
    //test_stride_copy(4, 4, 16, 10, ref, 10, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    //test_stride_copy(4, 5, 16, 16, ref, 10, { 1, 2, 3, 4, 6, 7, 8, 9, 11, 12 });
    //test_stride_copy(4, 6, 16, 16, ref, 10, { 1, 2, 3, 4, 7, 8, 9, 10, 13, 14 });
    //test_stride_copy(5, 5, 16, 10, ref, 10, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    //test_stride_copy(5, 6, 16, 16, ref, 10, { 1, 2, 3, 4, 5, 7, 8, 9, 10, 11 });
    //test_stride_copy(5, 7, 16, 16, ref, 10, { 1, 2, 3, 4, 5, 8, 9, 10, 11, 12 });
    //test_stride_copy(6, 6, 16, 10, ref, 10, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    //test_stride_copy(6, 7, 16, 16, ref, 10, { 1, 2, 3, 4, 5, 6, 8, 9, 10, 11 });
}

TEST(FunctionsTest, normalize_angle)
{
    //// 0..+360

    // 0..720 -> [0..+360)
    ASSERT_EQ(math::normalize_angle(  0, 0, +360, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle( 90, 0, +360, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(179, 0, +360, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(180, 0, +360, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(181, 0, +360, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(270, 0, +360, 360, -1),  270);
    ASSERT_EQ(math::normalize_angle(359, 0, +360, 360, -1),  359);
    ASSERT_EQ(math::normalize_angle(360, 0, +360, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(361, 0, +360, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(450, 0, +360, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(539, 0, +360, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(540, 0, +360, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(541, 0, +360, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(630, 0, +360, 360, -1),  270);
    ASSERT_EQ(math::normalize_angle(719, 0, +360, 360, -1),  359);
    ASSERT_EQ(math::normalize_angle(720, 0, +360, 360, -1),    0);

    // 0..-720 -> [0..+360)
    ASSERT_EQ(math::normalize_angle(   0, 0, +360, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, 0, +360, 360, -1),  270);
    ASSERT_EQ(math::normalize_angle(-179, 0, +360, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(-180, 0, +360, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(-181, 0, +360, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(-270, 0, +360, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(-359, 0, +360, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-360, 0, +360, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(-361, 0, +360, 360, -1),  359);
    ASSERT_EQ(math::normalize_angle(-450, 0, +360, 360, -1),  270);
    ASSERT_EQ(math::normalize_angle(-539, 0, +360, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(-540, 0, +360, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(-541, 0, +360, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(-630, 0, +360, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(-719, 0, +360, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-720, 0, +360, 360, -1),    0);

    // 0..720 -> [0..+360]
    ASSERT_EQ(math::normalize_angle(  0, 0, +360, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle( 90, 0, +360, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(179, 0, +360, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(180, 0, +360, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(181, 0, +360, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(270, 0, +360, 360, 0),  270);
    ASSERT_EQ(math::normalize_angle(359, 0, +360, 360, 0),  359);
    ASSERT_EQ(math::normalize_angle(360, 0, +360, 360, 0),  360);
    ASSERT_EQ(math::normalize_angle(361, 0, +360, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(450, 0, +360, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(539, 0, +360, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(540, 0, +360, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(541, 0, +360, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(630, 0, +360, 360, 0),  270);
    ASSERT_EQ(math::normalize_angle(719, 0, +360, 360, 0),  359);
    ASSERT_EQ(math::normalize_angle(720, 0, +360, 360, 0),    0);

    // 0..-720 -> [0..+360]
    ASSERT_EQ(math::normalize_angle(   0, 0, +360, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(- 90, 0, +360, 360, 0),  270);
    ASSERT_EQ(math::normalize_angle(-179, 0, +360, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(-180, 0, +360, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(-181, 0, +360, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(-270, 0, +360, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(-359, 0, +360, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-360, 0, +360, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(-361, 0, +360, 360, 0),  359);
    ASSERT_EQ(math::normalize_angle(-450, 0, +360, 360, 0),  270);
    ASSERT_EQ(math::normalize_angle(-539, 0, +360, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(-540, 0, +360, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(-541, 0, +360, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(-630, 0, +360, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(-719, 0, +360, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-720, 0, +360, 360, 0),    0);

    // 0..720 -> (0..+360]
    ASSERT_EQ(math::normalize_angle(  0, 0, +360, 360, +1),  360);
    ASSERT_EQ(math::normalize_angle( 90, 0, +360, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(179, 0, +360, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(180, 0, +360, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(181, 0, +360, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(270, 0, +360, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(359, 0, +360, 360, +1),  359);
    ASSERT_EQ(math::normalize_angle(360, 0, +360, 360, +1),  360);
    ASSERT_EQ(math::normalize_angle(361, 0, +360, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(450, 0, +360, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(539, 0, +360, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(540, 0, +360, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(541, 0, +360, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(630, 0, +360, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(719, 0, +360, 360, +1),  359);
    ASSERT_EQ(math::normalize_angle(720, 0, +360, 360, +1),  360);

    // 0..-720 -> (0..+360]
    ASSERT_EQ(math::normalize_angle(   0, 0, +360, 360, +1),  360);
    ASSERT_EQ(math::normalize_angle(- 90, 0, +360, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(-179, 0, +360, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(-180, 0, +360, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(-181, 0, +360, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(-270, 0, +360, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-359, 0, +360, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-360, 0, +360, 360, +1),  360);
    ASSERT_EQ(math::normalize_angle(-361, 0, +360, 360, +1),  359);
    ASSERT_EQ(math::normalize_angle(-450, 0, +360, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(-539, 0, +360, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(-540, 0, +360, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(-541, 0, +360, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(-630, 0, +360, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-719, 0, +360, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-720, 0, +360, 360, +1),  360);

    //// -90..+90

    // 0..720 -> (-90..+90]
    ASSERT_EQ(math::normalize_angle(  0, -90, +90, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle( 90, -90, +90, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(179, -90, +90, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(180, -90, +90, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(181, -90, +90, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(270, -90, +90, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(359, -90, +90, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(360, -90, +90, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(361, -90, +90, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(450, -90, +90, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(539, -90, +90, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(540, -90, +90, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(541, -90, +90, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(630, -90, +90, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(719, -90, +90, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(720, -90, +90, 360, +1),    0);

    // 0..-720 -> (-90..+90]
    ASSERT_EQ(math::normalize_angle(   0, -90, +90, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -90, +90, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -90, +90, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(-180, -90, +90, 360, +1), -180);
    ASSERT_EQ(math::normalize_angle(-181, -90, +90, 360, +1), -181);
    ASSERT_EQ(math::normalize_angle(-270, -90, +90, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-359, -90, +90, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-360, -90, +90, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(-361, -90, +90, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -90, +90, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -90, +90, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(-540, -90, +90, 360, +1), -180);
    ASSERT_EQ(math::normalize_angle(-541, -90, +90, 360, +1), -181);
    ASSERT_EQ(math::normalize_angle(-630, -90, +90, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-719, -90, +90, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-720, -90, +90, 360, +1),    0);

    // 0..720 -> [-90..+90]
    ASSERT_EQ(math::normalize_angle(  0, -90, +90, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle( 90, -90, +90, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(179, -90, +90, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(180, -90, +90, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(181, -90, +90, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(270, -90, +90, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(359, -90, +90, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(360, -90, +90, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(361, -90, +90, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(450, -90, +90, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(539, -90, +90, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(540, -90, +90, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(541, -90, +90, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(630, -90, +90, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(719, -90, +90, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(720, -90, +90, 360, 0),    0);

    // 0..-720 -> [-90..+90]
    ASSERT_EQ(math::normalize_angle(   0, -90, +90, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -90, +90, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -90, +90, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(-180, -90, +90, 360, 0), -180);
    ASSERT_EQ(math::normalize_angle(-181, -90, +90, 360, 0), -181);
    ASSERT_EQ(math::normalize_angle(-270, -90, +90, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(-359, -90, +90, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-360, -90, +90, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(-361, -90, +90, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -90, +90, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -90, +90, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(-540, -90, +90, 360, 0), -180);
    ASSERT_EQ(math::normalize_angle(-541, -90, +90, 360, 0), -181);
    ASSERT_EQ(math::normalize_angle(-630, -90, +90, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(-719, -90, +90, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-720, -90, +90, 360, 0),    0);

    // 0..720 -> [-90..+90)
    ASSERT_EQ(math::normalize_angle(  0, -90, +90, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle( 90, -90, +90, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(179, -90, +90, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(180, -90, +90, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(181, -90, +90, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(270, -90, +90, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(359, -90, +90, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(360, -90, +90, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(361, -90, +90, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(450, -90, +90, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(539, -90, +90, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(540, -90, +90, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(541, -90, +90, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(630, -90, +90, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(719, -90, +90, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(720, -90, +90, 360, -1),    0);

    // 0..-720 -> [-90..+90)
    ASSERT_EQ(math::normalize_angle(   0, -90, +90, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -90, +90, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -90, +90, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(-180, -90, +90, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(-181, -90, +90, 360, -1), -181);
    ASSERT_EQ(math::normalize_angle(-270, -90, +90, 360, -1), -270);
    ASSERT_EQ(math::normalize_angle(-359, -90, +90, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-360, -90, +90, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(-361, -90, +90, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -90, +90, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -90, +90, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(-540, -90, +90, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(-541, -90, +90, 360, -1), -181);
    ASSERT_EQ(math::normalize_angle(-630, -90, +90, 360, -1), -270);
    ASSERT_EQ(math::normalize_angle(-719, -90, +90, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-720, -90, +90, 360, -1),    0);

    //// -180..+180

    // 0..720 -> (-180..+180]
    ASSERT_EQ(math::normalize_angle(  0, -180, +180, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle( 90, -180, +180, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(179, -180, +180, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(180, -180, +180, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(181, -180, +180, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(270, -180, +180, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(359, -180, +180, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(360, -180, +180, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(361, -180, +180, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(450, -180, +180, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(539, -180, +180, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(540, -180, +180, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(541, -180, +180, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(630, -180, +180, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(719, -180, +180, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(720, -180, +180, 360, +1),    0);

    // 0..-720 -> (-180..+180]
    ASSERT_EQ(math::normalize_angle(   0, -180, +180, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -180, +180, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -180, +180, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(-180, -180, +180, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(-181, -180, +180, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(-270, -180, +180, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-359, -180, +180, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-360, -180, +180, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(-361, -180, +180, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -180, +180, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -180, +180, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(-540, -180, +180, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(-541, -180, +180, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(-630, -180, +180, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-719, -180, +180, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-720, -180, +180, 360, +1),    0);

    // 0..720 -> [-180..+180]
    ASSERT_EQ(math::normalize_angle(  0, -180, +180, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle( 90, -180, +180, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(179, -180, +180, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(180, -180, +180, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(181, -180, +180, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(270, -180, +180, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(359, -180, +180, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(360, -180, +180, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(361, -180, +180, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(450, -180, +180, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(539, -180, +180, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(540, -180, +180, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(541, -180, +180, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(630, -180, +180, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(719, -180, +180, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(720, -180, +180, 360, 0),    0);

    // 0..-720 -> [-180..+180]
    ASSERT_EQ(math::normalize_angle(   0, -180, +180, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -180, +180, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -180, +180, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(-180, -180, +180, 360, 0), -180);
    ASSERT_EQ(math::normalize_angle(-181, -180, +180, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(-270, -180, +180, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(-359, -180, +180, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-360, -180, +180, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(-361, -180, +180, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -180, +180, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -180, +180, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(-540, -180, +180, 360, 0), -180);
    ASSERT_EQ(math::normalize_angle(-541, -180, +180, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(-630, -180, +180, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(-719, -180, +180, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-720, -180, +180, 360, 0),    0);

    // 0..720 -> [-180..+180)
    ASSERT_EQ(math::normalize_angle(  0, -180, +180, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle( 90, -180, +180, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(179, -180, +180, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(180, -180, +180, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(181, -180, +180, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(270, -180, +180, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(359, -180, +180, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(360, -180, +180, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(361, -180, +180, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(450, -180, +180, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(539, -180, +180, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(540, -180, +180, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(541, -180, +180, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(630, -180, +180, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(719, -180, +180, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(720, -180, +180, 360, -1),    0);

    // 0..-720 -> [-180..+180)
    ASSERT_EQ(math::normalize_angle(   0, -180, +180, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -180, +180, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -180, +180, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(-180, -180, +180, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(-181, -180, +180, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(-270, -180, +180, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(-359, -180, +180, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-360, -180, +180, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(-361, -180, +180, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -180, +180, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -180, +180, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(-540, -180, +180, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(-541, -180, +180, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(-630, -180, +180, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(-719, -180, +180, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-720, -180, +180, 360, -1),    0);

    //// -270..+270

    // 0..720 -> (-270..+270]
    ASSERT_EQ(math::normalize_angle(  0, -270, +270, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle( 90, -270, +270, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(179, -270, +270, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(180, -270, +270, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(181, -270, +270, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(269, -270, +270, 360, +1),  269);
    ASSERT_EQ(math::normalize_angle(270, -270, +270, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(271, -270, +270, 360, +1), - 89);
    ASSERT_EQ(math::normalize_angle(359, -270, +270, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(360, -270, +270, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(361, -270, +270, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(450, -270, +270, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(539, -270, +270, 360, +1),  179);
    ASSERT_EQ(math::normalize_angle(540, -270, +270, 360, +1),  180);
    ASSERT_EQ(math::normalize_angle(541, -270, +270, 360, +1),  181);
    ASSERT_EQ(math::normalize_angle(629, -270, +270, 360, +1),  269);
    ASSERT_EQ(math::normalize_angle(630, -270, +270, 360, +1),  270);
    ASSERT_EQ(math::normalize_angle(631, -270, +270, 360, +1), - 89);
    ASSERT_EQ(math::normalize_angle(719, -270, +270, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(720, -270, +270, 360, +1),    0);

    // 0..-720 -> (-270..+270]
    ASSERT_EQ(math::normalize_angle(   0, -270, +270, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -270, +270, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -270, +270, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(-180, -270, +270, 360, +1), -180);
    ASSERT_EQ(math::normalize_angle(-181, -270, +270, 360, +1), -181);
    ASSERT_EQ(math::normalize_angle(-269, -270, +270, 360, +1), -269);
    ASSERT_EQ(math::normalize_angle(-270, -270, +270, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-271, -270, +270, 360, +1),   89);
    ASSERT_EQ(math::normalize_angle(-359, -270, +270, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-360, -270, +270, 360, +1),    0);
    ASSERT_EQ(math::normalize_angle(-361, -270, +270, 360, +1), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -270, +270, 360, +1), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -270, +270, 360, +1), -179);
    ASSERT_EQ(math::normalize_angle(-540, -270, +270, 360, +1), -180);
    ASSERT_EQ(math::normalize_angle(-541, -270, +270, 360, +1), -181);
    ASSERT_EQ(math::normalize_angle(-629, -270, +270, 360, +1), -269);
    ASSERT_EQ(math::normalize_angle(-630, -270, +270, 360, +1),   90);
    ASSERT_EQ(math::normalize_angle(-631, -270, +270, 360, +1),   89);
    ASSERT_EQ(math::normalize_angle(-719, -270, +270, 360, +1),    1);
    ASSERT_EQ(math::normalize_angle(-720, -270, +270, 360, +1),    0);

    // 0..720 -> [-270..+270]
    ASSERT_EQ(math::normalize_angle(  0, -270, +270, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle( 90, -270, +270, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(179, -270, +270, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(180, -270, +270, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(181, -270, +270, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(269, -270, +270, 360, 0),  269);
    ASSERT_EQ(math::normalize_angle(270, -270, +270, 360, 0),  270);
    ASSERT_EQ(math::normalize_angle(271, -270, +270, 360, 0), - 89);
    ASSERT_EQ(math::normalize_angle(359, -270, +270, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(360, -270, +270, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(361, -270, +270, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(450, -270, +270, 360, 0),   90);
    ASSERT_EQ(math::normalize_angle(539, -270, +270, 360, 0),  179);
    ASSERT_EQ(math::normalize_angle(540, -270, +270, 360, 0),  180);
    ASSERT_EQ(math::normalize_angle(541, -270, +270, 360, 0),  181);
    ASSERT_EQ(math::normalize_angle(629, -270, +270, 360, 0),  269);
    ASSERT_EQ(math::normalize_angle(630, -270, +270, 360, 0),  270);
    ASSERT_EQ(math::normalize_angle(631, -270, +270, 360, 0), - 89);
    ASSERT_EQ(math::normalize_angle(719, -270, +270, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(720, -270, +270, 360, 0),    0);

    // 0..-720 -> [-270..+270]
    ASSERT_EQ(math::normalize_angle(   0, -270, +270, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -270, +270, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -270, +270, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(-180, -270, +270, 360, 0), -180);
    ASSERT_EQ(math::normalize_angle(-181, -270, +270, 360, 0), -181);
    ASSERT_EQ(math::normalize_angle(-269, -270, +270, 360, 0), -269);
    ASSERT_EQ(math::normalize_angle(-270, -270, +270, 360, 0), -270);
    ASSERT_EQ(math::normalize_angle(-271, -270, +270, 360, 0),   89);
    ASSERT_EQ(math::normalize_angle(-359, -270, +270, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-360, -270, +270, 360, 0),    0);
    ASSERT_EQ(math::normalize_angle(-361, -270, +270, 360, 0), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -270, +270, 360, 0), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -270, +270, 360, 0), -179);
    ASSERT_EQ(math::normalize_angle(-540, -270, +270, 360, 0), -180);
    ASSERT_EQ(math::normalize_angle(-541, -270, +270, 360, 0), -181);
    ASSERT_EQ(math::normalize_angle(-629, -270, +270, 360, 0), -269);
    ASSERT_EQ(math::normalize_angle(-630, -270, +270, 360, 0), -270);
    ASSERT_EQ(math::normalize_angle(-631, -270, +270, 360, 0),   89);
    ASSERT_EQ(math::normalize_angle(-719, -270, +270, 360, 0),    1);
    ASSERT_EQ(math::normalize_angle(-720, -270, +270, 360, 0),    0);

    // 0..720 -> [-270..+270)
    ASSERT_EQ(math::normalize_angle(  0, -270, +270, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle( 90, -270, +270, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(179, -270, +270, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(180, -270, +270, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(181, -270, +270, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(269, -270, +270, 360, -1),  269);
    ASSERT_EQ(math::normalize_angle(270, -270, +270, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(271, -270, +270, 360, -1), - 89);
    ASSERT_EQ(math::normalize_angle(359, -270, +270, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(360, -270, +270, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(361, -270, +270, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(450, -270, +270, 360, -1),   90);
    ASSERT_EQ(math::normalize_angle(539, -270, +270, 360, -1),  179);
    ASSERT_EQ(math::normalize_angle(540, -270, +270, 360, -1),  180);
    ASSERT_EQ(math::normalize_angle(541, -270, +270, 360, -1),  181);
    ASSERT_EQ(math::normalize_angle(629, -270, +270, 360, -1),  269);
    ASSERT_EQ(math::normalize_angle(630, -270, +270, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(631, -270, +270, 360, -1), - 89);
    ASSERT_EQ(math::normalize_angle(719, -270, +270, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(720, -270, +270, 360, -1),    0);

    // 0..-720 -> [-270..+270)
    ASSERT_EQ(math::normalize_angle(   0, -270, +270, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(- 90, -270, +270, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(-179, -270, +270, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(-180, -270, +270, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(-181, -270, +270, 360, -1), -181);
    ASSERT_EQ(math::normalize_angle(-269, -270, +270, 360, -1), -269);
    ASSERT_EQ(math::normalize_angle(-270, -270, +270, 360, -1), -270);
    ASSERT_EQ(math::normalize_angle(-271, -270, +270, 360, -1),   89);
    ASSERT_EQ(math::normalize_angle(-359, -270, +270, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-360, -270, +270, 360, -1),    0);
    ASSERT_EQ(math::normalize_angle(-361, -270, +270, 360, -1), -  1);
    ASSERT_EQ(math::normalize_angle(-450, -270, +270, 360, -1), - 90);
    ASSERT_EQ(math::normalize_angle(-539, -270, +270, 360, -1), -179);
    ASSERT_EQ(math::normalize_angle(-540, -270, +270, 360, -1), -180);
    ASSERT_EQ(math::normalize_angle(-541, -270, +270, 360, -1), -181);
    ASSERT_EQ(math::normalize_angle(-629, -270, +270, 360, -1), -269);
    ASSERT_EQ(math::normalize_angle(-630, -270, +270, 360, -1), -270);
    ASSERT_EQ(math::normalize_angle(-631, -270, +270, 360, -1),   89);
    ASSERT_EQ(math::normalize_angle(-719, -270, +270, 360, -1),    1);
    ASSERT_EQ(math::normalize_angle(-720, -270, +270, 360, -1),    0);
}
