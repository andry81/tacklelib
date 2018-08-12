#include "test_common.hpp"

#include <utility/math.hpp>


void test_std_fmod(bool in_radians, double range_factor, size_t repeats)
{
    const double min_angle = -DEG_360_IN_RAD_IF(in_radians) * range_factor;
    const double max_angle = DEG_360_IN_RAD_IF(in_radians) * range_factor;
    const double step_angle = DEG_360_IN_RAD_IF(in_radians) / DEG_720_IN_RAD_IF(in_radians);

    for (size_t i = 0; i < repeats; i++) {
        for (double angle = min_angle; angle <= max_angle; angle += step_angle) {
            const double angle_norm = std::fmod(angle, DEG_360_IN_RAD_IF(in_radians));
            UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(angle_norm);
        }
    }
}

void test_c_fmod(bool in_radians, double range_factor, size_t repeats)
{
    const double min_angle = -DEG_360_IN_RAD_IF(in_radians) * range_factor;
    const double max_angle = DEG_360_IN_RAD_IF(in_radians) * range_factor;
    const double step_angle = DEG_360_IN_RAD_IF(in_radians) / DEG_720_IN_RAD_IF(in_radians);

    for (size_t i = 0; i < repeats; i++) {
        for (double angle = min_angle; angle <= max_angle; angle += step_angle) {
            const double angle_norm = fmod(angle, DEG_360_IN_RAD_IF(in_radians));
            UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(angle_norm);
        }
    }
}

void test_normalize_angle(bool in_radians, double range_factor, size_t repeats)
{
    const double min_angle = -DEG_360_IN_RAD_IF(in_radians) * range_factor;
    const double max_angle = DEG_360_IN_RAD_IF(in_radians) * range_factor;
    const double step_angle = DEG_360_IN_RAD_IF(in_radians) / DEG_720_IN_RAD_IF(in_radians);

    for (size_t i = 0; i < repeats; i++) {
        for (double angle = min_angle; angle <= max_angle; angle += step_angle) {
            const double angle_norm = math::normalize_angle(angle,
                -DEG_360_IN_RAD_IF(in_radians), +DEG_360_IN_RAD_IF(in_radians), DEG_360_IN_RAD_IF(in_radians), 0, true);
            UTILITY_SUPPRESS_OPTIMIZATION_ON_VAR(angle_norm);
        }
    }
}

//// std::fmod

TEST(FunctionsTest, test_std_fmod_rads_out_bounds_x10000)
{
    test_std_fmod(true, 10000, 1);
}

TEST(FunctionsTest, test_std_fmod_degrees_out_bounds_x10000)
{
    test_std_fmod(false, 10000, 1);
}

TEST(FunctionsTest, test_std_fmod_rads_180_x10000)
{
    test_std_fmod(true, 0.5, 20000);
}

TEST(FunctionsTest, test_std_fmod_degrees_180_x10000)
{
    test_std_fmod(false, 0.5, 20000);
}

TEST(FunctionsTest, test_std_fmod_rads_360_x10000)
{
    test_std_fmod(true, 1, 10000);
}

TEST(FunctionsTest, test_std_fmod_degrees_360_x10000)
{
    test_std_fmod(false, 1, 10000);
}

TEST(FunctionsTest, test_std_fmod_rads_540_x10000)
{
    test_std_fmod(true, 1.5, 6667);
}

TEST(FunctionsTest, test_std_fmod_degrees_540_x10000)
{
    test_std_fmod(false, 1.5, 6667);
}

TEST(FunctionsTest, test_std_fmod_rads_720_x10000)
{
    test_std_fmod(true, 2, 5000);
}

TEST(FunctionsTest, test_std_fmod_degrees_720_x10000)
{
    test_std_fmod(false, 2, 5000);
}

//// c fmod

TEST(FunctionsTest, test_c_fmod_rads_out_bounds_x10000)
{
    test_c_fmod(true, 10000, 1);
}

TEST(FunctionsTest, test_c_fmod_degrees_out_bounds_x10000)
{
    test_c_fmod(false, 10000, 1);
}

TEST(FunctionsTest, test_c_fmod_rads_180_x10000)
{
    test_c_fmod(true, 0.5, 20000);
}

TEST(FunctionsTest, test_c_fmod_degrees_180_x10000)
{
    test_c_fmod(false, 0.5, 20000);
}

TEST(FunctionsTest, test_c_fmod_rads_360_x10000)
{
    test_c_fmod(true, 1, 10000);
}

TEST(FunctionsTest, test_c_fmod_degrees_360_x10000)
{
    test_c_fmod(false, 1, 10000);
}

TEST(FunctionsTest, test_c_fmod_rads_540_x10000)
{
    test_c_fmod(true, 1.5, 6667);
}

TEST(FunctionsTest, test_c_fmod_degrees_540_x10000)
{
    test_c_fmod(false, 1.5, 6667);
}

TEST(FunctionsTest, test_c_fmod_rads_720_x10000)
{
    test_c_fmod(true, 2, 5000);
}

TEST(FunctionsTest, test_c_fmod_degrees_720_x10000)
{
    test_c_fmod(false, 2, 5000);
}

//// math::normalize_angle

TEST(FunctionsTest, test_normalize_angle_rads_out_bounds_x10000)
{
    test_normalize_angle(true, 10000, 1);
}

TEST(FunctionsTest, test_normalize_angle_degrees_out_bounds_x10000)
{
    test_normalize_angle(false, 10000, 1);
}

TEST(FunctionsTest, test_normalize_angle_rads_180_x10000)
{
    test_normalize_angle(true, 0.5, 20000);
}

TEST(FunctionsTest, test_normalize_angle_degrees_180_x10000)
{
    test_normalize_angle(false, 0.5, 20000);
}

TEST(FunctionsTest, test_normalize_angle_rads_360_x10000)
{
    test_normalize_angle(true, 1, 10000);
}

TEST(FunctionsTest, test_normalize_angle_degrees_360_x10000)
{
    test_normalize_angle(false, 1, 10000);
}

TEST(FunctionsTest, test_normalize_angle_rads_540_x10000)
{
    test_normalize_angle(true, 1.5, 6667);
}

TEST(FunctionsTest, test_normalize_angle_degrees_540_x10000)
{
    test_normalize_angle(false, 1.5, 6667);
}

TEST(FunctionsTest, test_normalize_angle_rads_720_x10000)
{
    test_normalize_angle(true, 2, 5000);
}

TEST(FunctionsTest, test_normalize_angle_degrees_720_x10000)
{
    test_normalize_angle(false, 2, 5000);
}
