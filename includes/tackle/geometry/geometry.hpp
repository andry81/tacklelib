#pragma once

#include <tackle/geometry/vector.hpp>

#include <utility/math.hpp>

#include <float.h>
#include <math.h>


// enable if needs debug with zero epsilon
#define TACKLE_GEOM_ENABLE_DEBUG_WITH_ZERO_EPSILON 0

#if TACKLE_GEOM_ENABLE_DEBUG_WITH_ZERO_EPSILON
#define TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(x)
#else
#define TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(x) x
#endif


namespace tackle {
namespace geometry {

    //// vector arithmetic

    inline real vector_square_length(const Vector3d & vec)
    {
        return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z;
    }

    inline real vector_length(const Vector3d & vec)
    {
        return sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
    }

    inline real vector_length(const Normal3d & vec)
    {
        return sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
    }

    inline Vector4d vector_with_length(const Vector3d & vec)
    {
        return Vector4d{ vec, vector_length(vec) };
    }

    inline real vector_normalize(Normal3d & vec_out, const Vector3d & vec_to_normalize, real * sqr_len_ptr = nullptr)
    {
        const real sqr_len =
            vec_to_normalize.x * vec_to_normalize.x + vec_to_normalize.y * vec_to_normalize.y + vec_to_normalize.z * vec_to_normalize.z;
        if (sqr_len_ptr) {
            *sqr_len_ptr = sqr_len;
        }

        const real sqrt_len = sqrt(sqr_len);
        DEBUG_ASSERT_NE(sqrt_len, 0);

        vec_out = Normal3d{
            vec_to_normalize.x / sqrt_len,
            vec_to_normalize.y / sqrt_len,
            vec_to_normalize.z / sqrt_len
        };

        return sqrt_len;
    }

    inline real vector_normalize(Normal3d & vec_out, const Vector3d & vec_to_normalize, const real & vec_to_normalize_len)
    {
        DEBUG_ASSERT_NE(vec_to_normalize_len, 0);

        vec_out = Normal3d{
            vec_to_normalize.x / vec_to_normalize_len,
            vec_to_normalize.y / vec_to_normalize_len,
            vec_to_normalize.z / vec_to_normalize_len
        };

        return vec_to_normalize_len;
    }

    inline real vector_normalize(Normal3d & vec_out, const Vector4d & vec_to_normalize)
    {
        DEBUG_ASSERT_NE(vec_to_normalize.w, 0);

        vec_out = Normal3d{
            vec_to_normalize.x / vec_to_normalize.w,
            vec_to_normalize.y / vec_to_normalize.w,
            vec_to_normalize.z / vec_to_normalize.w
        };

        return vec_to_normalize.w;
    }

    inline real vector_dot_product(const Vector3d & vec_first, const Vector3d & vec_second)
    {
        return vec_first.x * vec_second.x + vec_first.y * vec_second.y + vec_first.z * vec_second.z;
    }

    inline real vector_dot_product(const Normal3d & vec_first, const Normal3d & vec_second)
    {
        return vec_first.x * vec_second.x + vec_first.y * vec_second.y + vec_first.z * vec_second.z;
    }

    inline void vector_cross_product(Vector3d & vec_out, const Vector3d & vec_first, const Vector3d & vec_second)
    {
        vec_out = Vector3d{
            vec_first[1] * vec_second[2] - vec_first[2] * vec_second[1],
            vec_first[2] * vec_second[0] - vec_first[0] * vec_second[2],
            vec_first[0] * vec_second[1] - vec_first[1] * vec_second[0]
        };
    }

    inline void vector_cross_product(Vector3d & vec_out, const Vector4d & vec_first, const Vector4d & vec_second)
    {
        vec_out = Vector3d{
            vec_first[1] * vec_second[2] - vec_first[2] * vec_second[1],
            vec_first[2] * vec_second[0] - vec_first[0] * vec_second[2],
            vec_first[0] * vec_second[1] - vec_first[1] * vec_second[0]
        };
    }

    inline bool vector_is_equal(const Vector3d & l, const Vector3d & r, const real & vec_square_epsilon)
    {
        const real vec_square_len = vector_square_length(r - l);
        return vec_square_epsilon >= vec_square_len;
    }

    // A.B = |A||B|cos(a), where |A||B| >= 0 and cos(a) >< 0, so A.B represents the sign of direction
    //
    inline int vector_is_codir(const Vector4d & vec_from, const Vector4d & vec_to, const real & vec_from_epsilon, const real & vec_to_epsilon)
    {
        // all epsilons must be positive
        DEBUG_ASSERT_GT(vec_from_epsilon, 0);
        DEBUG_ASSERT_GT(vec_to_epsilon, 0);

        const real denominator = vec_from.w * vec_to.w; // always positive
        DEBUG_ASSERT_GE(denominator, 0);

        DEBUG_ASSERT_LT(vec_from_epsilon * vec_to_epsilon, denominator);

        const real sign_product = vector_dot_product(vec_from.basis(), vec_to.basis()); // we need only the sign of the result
        return math::sign_to_int(sign_product);
    }

    // A.B = |A||B|cos(a), where |A||B| >= 0 and cos(a) >< 0, so A.B represents the sign of direction
    //
    inline int vector_is_codir(const Vector3d & vec_from, const Vector3d & vec_to, const real & vec_from_square_epsilon, const real & vec_to_square_epsilon)
    {
        // all epsilons must be positive
        DEBUG_ASSERT_GT(vec_from_square_epsilon, 0);
        DEBUG_ASSERT_GT(vec_to_square_epsilon, 0);

        const real denominator = vector_square_length(vec_from) * vector_square_length(vec_to); // always positive
        DEBUG_ASSERT_GE(denominator, 0);

        DEBUG_ASSERT_LT(vec_from_square_epsilon * vec_to_square_epsilon, denominator);

        const real sign_product = vector_dot_product(vec_from, vec_to); // we need only the sign of the result
        return math::sign_to_int(sign_product);
    }

    inline real vector_length_projection(const Vector3d & vec_from, const Normal3d & vec_to)
    {
        return vec_from.x * vec_to.x + vec_from.y * vec_to.y + vec_from.z * vec_to.z;
    }

    inline real vector_length_projection(const Vector4d & vec_from, const Normal3d & vec_to)
    {
        return vec_from.x * vec_to.x + vec_from.y * vec_to.y + vec_from.z * vec_to.z;
    }

    // Vector rotation around another vector by Rodrigues' rotation formula.
    // See for details: https://stackoverflow.com/questions/42421611/3d-vector-rotation-in-c
    //
    // CAUTION:
    //  `vec_to_rotate` must be not parallel with `around_norm`
    //
    inline void vector_rotate(Vector3d & vec_out, const Vector3d & vec_to_rotate, const real & vec_to_rotate_len, const Normal3d & around_norm,
        const real & angle_rad, const real & around_norm_unit_epsilon, const real & vec_to_rotate_epsilon)
    {
        // all epsilons must be positive
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(around_norm_unit_epsilon, 0));
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(vec_to_rotate_epsilon, 0));
        DEBUG_ASSERT_LT(vec_to_rotate_epsilon, vec_to_rotate_len);
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GE(around_norm_unit_epsilon, fabs(vector_length(around_norm) - 1.0)));

        const real cos_theta = cos(angle_rad);
        const real sin_theta = sin(angle_rad);

        const real vec_to_rotate_projection = vector_dot_product(vec_to_rotate, around_norm);

        if (fabs(vec_to_rotate_projection) < vec_to_rotate_len - vec_to_rotate_epsilon) {
            Vector3d cross_vec;
            vector_cross_product(cross_vec, around_norm, vec_to_rotate);
            vec_out = vec_to_rotate * cos_theta + cross_vec * sin_theta + around_norm * vec_to_rotate_projection * (1 - cos_theta);
            return;
        }

        vec_out = vec_to_rotate; // return the same vector
    }

    inline void vector_rotate(Vector4d & vec_out, const Vector4d & vec_to_rotate, const Normal3d & around_norm,
        const real & angle_rad, const real & around_norm_unit_epsilon, const real & vec_to_rotate_epsilon)
    {
        Vector3d vec_out_;
        vector_rotate(vec_out_, vec_to_rotate.basis(), vec_to_rotate.w, around_norm, angle_rad,
            around_norm_unit_epsilon, vec_to_rotate_epsilon);
        vec_out = Vector4d{ vec_out_, vec_to_rotate.w };
    }

    inline void vector_rotate(Normal3d & vec_out, const Normal3d & vec_to_rotate, const Normal3d & around_norm, const real & angle_rad,
        const real & around_norm_unit_epsilon, const real & vec_to_rotate_unit_epsilon)
    {
        Vector3d vec_out_;
        vector_rotate(vec_out_, vec_to_rotate, 1.0, around_norm, angle_rad, around_norm_unit_epsilon, vec_to_rotate_unit_epsilon);
        vec_out = Normal3d{ vec_out_ };
    }

    inline void vector_2d_rotate_around_z_on_90_deg(Vector3d & vec_out, const Vector3d & vec_to_rotate, bool positive_angle)
    {
        vec_out = positive_angle ? Vector3d{ vec_to_rotate.y, -vec_to_rotate.x, 0 } : Vector3d{ -vec_to_rotate.y, vec_to_rotate.x, 0 };
    }

    inline void vector_2d_rotate_around_z_on_90_deg(Normal3d & vec_out, const Normal3d & vec_to_rotate, bool positive_angle)
    {
        vec_out = positive_angle ? Normal3d{ vec_to_rotate.y, -vec_to_rotate.x, 0 } : Normal3d{ -vec_to_rotate.y, vec_to_rotate.x, 0 };
    }

    enum CoordYOrientation
    {
        CoordYOrient_None                   = 0,
        CoordYOrient_ClosestToZ             = 1,    // Closest to Z-axis, use with CAUTION because a function can return different results for 2
                                                    // different points on the same track on a sphere if a track intersects the sphere equator!

        CoordYOrient_ToPositiveZ            = 2,    // codirection with Z-axis
        CoordYOrient_ToNegativeZ            = 3,    // opposite direction with Z-axis

        // exceptional output only cases, must be processed separately!
        CoordYOrient_MaxZ                   = -1,
        CoordYOrient_MinZ                   = -2,
    };

    // Makes normalized vector (normal) on the ellipsoid surface for right handed coordinate system with center in the center of an ellipsoid.
    //
    inline void make_normal_on_ellipsoid_surface(Normal3d & norm_out, const Vector4d & radius_vec,
        const real & semimajor_len, const real & semiminor_len, const real & radius_vec_epsilon)
    {
        DEBUG_ASSERT_LT(radius_vec_epsilon, radius_vec.w);
        DEBUG_ASSERT_GT(semimajor_len, 0);
        DEBUG_ASSERT_GT(semiminor_len, 0);
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(radius_vec_epsilon, 0));
        DEBUG_ASSERT_GE(semimajor_len, semiminor_len);
        DEBUG_ASSERT_LT(radius_vec_epsilon, semiminor_len);

        // calculate regular vector projection to Z-axis
        const real radius_vec_z_projected_len = vector_length_projection(radius_vec, Normal3d{ 0, 0, 1 });

        const real unit_epsilon = radius_vec_epsilon / semimajor_len;

        // check radius vector projection with tolerance on Z-axis=0 and Z-axis=semimajor_len (special edge cases)

        const real radius_vec_z_projected_abs_len = fabs(radius_vec_z_projected_len);
        if (radius_vec_z_projected_abs_len < radius_vec.w - radius_vec_epsilon) {
            // calculate normalized vector projection to Z-axis
            Normal3d radius_vec_norm;
            vector_normalize(radius_vec_norm, radius_vec);

            if (radius_vec_epsilon < radius_vec_z_projected_abs_len) {
                // Use as basis X-axis vector the cross product of the basis Z-axis and the radius vector.

                Vector3d coord_x_vec;
                Normal3d coord_x_axis;

                // use nearest z-axis vector
                if (radius_vec_z_projected_len >= 0) {
                    vector_cross_product(coord_x_vec, Vector4d{ 0, 0, 1, 0 }, radius_vec);
                }
                else {
                    vector_cross_product(coord_x_vec, Vector4d{ 0, 0, -1, 0 }, radius_vec);
                }

                vector_normalize(coord_x_axis, coord_x_vec);

                // Do correct the basis Z-axis vector as it must be perpendicular to the ellipsoid surface.
                //  1. Use ellipse first derivative formula:
                //      y'(x) = -b*x/(a^2 * sqrt(1 - (x^2/a^2))) = -(b^2/a^2)*(x0/y0) = tan(alpha);
                //      , where:
                //          alpha - negative angle between tangent vector and the ellipsoid equator plane.
                //          a - semimajor ellipsoid axis
                //          b - semiminor ellipsoid axis
                //
                //  2. Use angle `phi` between the ellipsoid equator plane and a radius vector from the ellipsoid center to a surface point:
                //      tan(phi) = y0/x0;
                //      -> alpha = arctan(-b^2/(a^2 * tan(phi)))
                //
                //  3. Use angle `betta` between the ellipsoid Z-axis and radius vector.
                //      phi = Pi/2 - betta
                //
                //  4. Use angle of inclination `delta` between orthogonal to the radius vector plane has formed by previously calculated X/Y basis vectors and
                //     resulted tangent plane to the ellipsoid surface in the end point of the radius vector.
                //      delta = Pi/2 - |alpha| - phi = Pi/2 - |alpha| - (Pi/2 - betta) - Pi/2 = betta - |alpha|
                //
                //  Resulted correction formula:
                //     delta = betta - |arctan(-b^2/(a^2 * tan(Pi/2 - betta)))| = betta - arctan(b^2/(a^2 * tan(Pi/2 - betta)))
                //

                // calculate `betta` angle
                real radius_vec_cos_betta_to_z = vector_dot_product(radius_vec_norm,
                    (radius_vec_z_projected_len >= 0 ? Normal3d{ 0, 0, 1 } : Normal3d{ 0, 0, -1 })); // reduction to [0..PI/2]

                // fix to avoid the trigonometric functions return NAN
                radius_vec_cos_betta_to_z = math::fix_float_trigonometric_range(radius_vec_cos_betta_to_z);

                const real betta_angle_rad = acos(radius_vec_cos_betta_to_z);

                const real betta_angle_rad_abs = fabs(betta_angle_rad);
                DEBUG_ASSERT_LT(betta_angle_rad_abs, DEG_90_IN_RAD);
                //DEBUG_ASSERT_NE(betta_angle_rad_abs, 0);

                const real alpha_angle_rad = (betta_angle_rad_abs != 0.0) ?
                    atan(-semiminor_len * semiminor_len / (semimajor_len * semimajor_len * tan(DEG_90_IN_RAD - betta_angle_rad_abs))) :
                    0;
                DEBUG_ASSERT_GE(DEG_180_IN_RAD, fabs(alpha_angle_rad));
                const real alpha_angle_rad_abs = fabs(alpha_angle_rad);

                // TODO: fix documentation/comments

                const real delta_angle_rad = betta_angle_rad_abs - alpha_angle_rad_abs;
                DEBUG_ASSERT_GE(delta_angle_rad, 0);

                // rotate basis Z-axis vectors around X-axis vector to make Z-axis perpendicular to the ellipsoid surface
                vector_rotate(norm_out, radius_vec_norm, coord_x_axis, -delta_angle_rad, unit_epsilon, radius_vec_epsilon);
            }
            else {
                // Radius vector too close to the ellipsoid equator (Z value is near 0).
                norm_out = radius_vec_norm;
            }

            // fix to avoid the trigonometric functions return NAN
            norm_out.fix_float_trigonometric_range();
        }
        else {
            // Radius vector is too close to the semiminor ellipsoid axis (the basis Z-axis vector)
            if (radius_vec_z_projected_len >= 0) {
                norm_out = Normal3d{ 0, 0, 1 };
            }
            else {
                norm_out = Normal3d{ 0, 0, -1 };
            }
        }
    }

    // Makes right handed coordinate system (basis) on the ellipsoid surface from right handed coordinate system with center in the center of an ellipsoid.
    // If coord_y_pole_orient=CoordYOrient_ClosestToZ, then may return different results for 2 different points on the same track if a track intersects the equator!
    //
    inline CoordYOrientation make_coordinate_system_on_ellipsoid_surface(NormalMatrix3d & vec_mat_out, CoordYOrientation coord_y_pole_orient,
        const Vector4d & radius_vec, const real & semimajor_len, const real & semiminor_len, const real & radius_vec_epsilon)
    {
        DEBUG_ASSERT_NE(coord_y_pole_orient, CoordYOrient_None);
        DEBUG_ASSERT_LT(radius_vec_epsilon, radius_vec.w);
        DEBUG_ASSERT_GT(semimajor_len, 0);
        DEBUG_ASSERT_GT(semiminor_len, 0);
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(radius_vec_epsilon, 0));
        DEBUG_ASSERT_GE(semimajor_len, semiminor_len);
        DEBUG_ASSERT_LT(radius_vec_epsilon, semiminor_len);

        CoordYOrientation ret_pole_orient = CoordYOrient_None;

        // calculate regular vector projection to Z-axis
        const real radius_vec_z_projected_len = vector_length_projection(radius_vec, Normal3d{ 0, 0, 1 });

        const real unit_epsilon = radius_vec_epsilon / semimajor_len;

        // check radius vector projection with tolerance on Z-axis=0 and Z-axis=semimajor_len (special edge cases)

        const real radius_vec_z_projected_abs_len = fabs(radius_vec_z_projected_len);
        if (radius_vec_z_projected_abs_len < radius_vec.w - radius_vec_epsilon) {
            // calculate normalized vector projection to Z-axis
            Normal3d radius_vec_norm;
            vector_normalize(radius_vec_norm, radius_vec);

            if (radius_vec_epsilon < radius_vec_z_projected_abs_len) {
                // Use as basis X-axis vector the cross product of the basis Z-axis and the radius vector. For basis Y-axis vector use
                // rotated basis X-axis vector around radius vector (not tangent to the ellipsoid surface, so must be corrected later).

                Vector3d coord_x_vec;
                Normal3d coord_x_axis;
                Vector3d coord_y_vec;
                Normal3d coord_y_axis;
                Vector3d coord_z_vec;
                Normal3d coord_z_axis;

                switch (coord_y_pole_orient) {
                case CoordYOrient_ClosestToZ:
                {
                    if (radius_vec_z_projected_len >= 0) {
                        vector_cross_product(coord_x_vec, Vector4d{ 0, 0, 1, 0 }, radius_vec);
                        ret_pole_orient = CoordYOrient_ToPositiveZ;
                    }
                    else {
                        vector_cross_product(coord_x_vec, Vector4d{ 0, 0, -1, 0 }, radius_vec);
                        ret_pole_orient = CoordYOrient_ToNegativeZ;
                    }
                } break;

                case CoordYOrient_ToPositiveZ:
                {
                    vector_cross_product(coord_x_vec, Vector4d{ 0, 0, 1, 0 }, radius_vec);
                    ret_pole_orient = CoordYOrient_ToPositiveZ;
                } break;

                case CoordYOrient_ToNegativeZ:
                {
                    vector_cross_product(coord_x_vec, Vector4d{ 0, 0, -1, 0 }, radius_vec);
                    ret_pole_orient = CoordYOrient_ToNegativeZ;
                } break;
                }

                vector_normalize(coord_x_axis, coord_x_vec);

                const real coord_x_vec_len = vector_length(coord_x_vec);
                vector_rotate(coord_y_vec, coord_x_vec, coord_x_vec_len, radius_vec_norm, DEG_90_IN_RAD, unit_epsilon, radius_vec_epsilon);

                // Do correct the basis Y-axis vector as it is tangent to the ellipsoid surface.
                //  1. Use ellipse first derivative formula:
                //      y'(x) = -b*x/(a^2 * sqrt(1 - (x^2/a^2))) = -(b^2/a^2)*(x0/y0) = tan(alpha);
                //      , where:
                //          alpha - negative angle between tangent vector and ellipsoid equator plane.
                //          a - semimajor ellipsoid axis
                //          b - semiminor ellipsoid axis
                //
                //  2. Use angle `phi` between ellipsoid equator plane and radius vector from ellipsoid center to a surface point:
                //      tan(phi) = y0/x0;
                //      -> alpha = arctan(-b^2/(a^2 * tan(phi)))
                //
                //  3. Use angle `betta` between ellipsoid Z-axis and radius vector.
                //      phi = Pi/2 - betta
                //
                //  4. Use angle of inclination `delta` between orthogonal to the radius vector plane has formed by previously calculated X/Y basis vectors and
                //     resulted tangent plane to the ellipsoid surface in the end point of the radius vector.
                //      delta = Pi/2 - |alpha| - phi = Pi/2 - |alpha| - (Pi/2 - betta) - Pi/2 = betta - |alpha|
                //
                //  Resulted correction formula:
                //     delta = betta - |arctan(-b^2/(a^2 * tan(Pi/2 - betta)))| = betta - arctan(b^2/(a^2 * tan(Pi/2 - betta)))
                //

                // calculate `betta` angle
                real radius_vec_cos_betta_to_z = vector_dot_product(radius_vec_norm,
                    (radius_vec_z_projected_len >= 0 ? Normal3d{ 0, 0, 1 } : Normal3d{ 0, 0, -1 })); // reduction to [0..PI/2]

                // fix to avoid the trigonometric functions return NAN
                radius_vec_cos_betta_to_z = math::fix_float_trigonometric_range(radius_vec_cos_betta_to_z);

                const real betta_angle_rad = acos(radius_vec_cos_betta_to_z);

                const real betta_angle_rad_abs = fabs(betta_angle_rad);
                DEBUG_ASSERT_LT(betta_angle_rad_abs, DEG_90_IN_RAD);
                //DEBUG_ASSERT_NE(betta_angle_rad_abs, 0);

                const real alpha_angle_rad = (betta_angle_rad_abs != 0.0) ?
                    atan(-semiminor_len * semiminor_len / (semimajor_len * semimajor_len * tan(DEG_90_IN_RAD - betta_angle_rad_abs))) :
                    0;
                DEBUG_ASSERT_GE(DEG_180_IN_RAD, fabs(alpha_angle_rad));
                const real alpha_angle_rad_abs = fabs(alpha_angle_rad);

                // TODO: fix documentation/comments

                const real delta_angle_rad = betta_angle_rad_abs - alpha_angle_rad_abs;
                DEBUG_ASSERT_GE(delta_angle_rad, 0);

                // rotate basis Y-axis and Z-axis vectors around X-axis vector to make vector basis tangent to the ellipsoid surface
                const real coord_y_vec_len = vector_length(coord_y_vec);
                vector_rotate(coord_y_vec, coord_y_vec, coord_y_vec_len, coord_x_axis,
                    ((ret_pole_orient == CoordYOrient_ToPositiveZ) ^ (radius_vec_z_projected_len >= 0)) ? delta_angle_rad : -delta_angle_rad,
                    unit_epsilon, radius_vec_epsilon);
                vector_rotate(coord_z_vec, coord_y_vec, coord_y_vec_len, coord_x_axis, DEG_90_IN_RAD, unit_epsilon, radius_vec_epsilon);

                vector_normalize(coord_y_axis, coord_y_vec);
                vector_normalize(coord_z_axis, coord_z_vec);

                vec_mat_out = NormalMatrix3d{ coord_x_axis, coord_y_axis, coord_z_axis };

                // fix to avoid the trigonometric functions return NAN
                vec_mat_out.fix_float_trigonometric_range();
            }
            else {
                // Radius vector too close to the ellipsoid equator (Z-axis value is near 0), then
                // use rotated basis Z-axis around the radius vector as basis X-axis vector and basis Z-axis as basis Y-axis vector.

                Normal3d coord_x_axis;
                vector_rotate(coord_x_axis, Normal3d{ 0, 0, 1 }, 1.0, radius_vec_norm, -DEG_90_IN_RAD, unit_epsilon, radius_vec_epsilon);

                switch (coord_y_pole_orient) {
                case CoordYOrient_ClosestToZ:
                {
                    if (radius_vec_z_projected_len >= 0) {
                        vec_mat_out = NormalMatrix3d{
                            coord_x_axis, Normal3d{ 0, 0, 1 }, radius_vec_norm
                        };
                        ret_pole_orient = CoordYOrient_ToPositiveZ;
                    }
                    else {
                        vec_mat_out = NormalMatrix3d{
                            -coord_x_axis, Normal3d{ 0, 0, -1 }, radius_vec_norm
                        };
                        ret_pole_orient = CoordYOrient_ToNegativeZ;
                    }
                } break;

                case CoordYOrient_ToPositiveZ:
                {
                    vec_mat_out = NormalMatrix3d{
                        coord_x_axis, Normal3d{ 0, 0, 1 }, radius_vec_norm
                    };
                    ret_pole_orient = CoordYOrient_ToPositiveZ;
                } break;

                case CoordYOrient_ToNegativeZ:
                {
                    vec_mat_out = NormalMatrix3d{
                        -coord_x_axis, Normal3d{ 0, 0, -1 }, radius_vec_norm
                    };
                    ret_pole_orient = CoordYOrient_ToNegativeZ;
                } break;
                }

                // fix to avoid the trigonometric functions return NAN
                vec_mat_out.m[0].fix_float_trigonometric_range();
                vec_mat_out.m[2].fix_float_trigonometric_range();
            }
        }
        else {
            // Radius vector is too close to the semiminor ellipsoid axis (the basis Z-axis vector), then
            // use the basis X-axis and the basis Y-axis as a vector basis.

            switch (coord_y_pole_orient) {
            case CoordYOrient_ClosestToZ:
            {
                if (radius_vec_z_projected_len >= 0) {
                    vec_mat_out = NormalMatrix3d{
                        Normal3d{ 1, 0, 0 }, Normal3d{ 0, 1, 0 }, Normal3d{ 0, 0, 1 }
                    };
                    ret_pole_orient = CoordYOrient_MaxZ;
                }
                else {
                    vec_mat_out = NormalMatrix3d{
                        Normal3d{ 1, 0, 0 }, Normal3d{ 0, -1, 0 }, Normal3d{ 0, 0, -1 }
                    };
                    ret_pole_orient = CoordYOrient_MinZ;
                }
            } break;

            case CoordYOrient_ToPositiveZ:
            {
                if (radius_vec_z_projected_len >= 0) {
                    vec_mat_out = NormalMatrix3d{
                        Normal3d{ 1, 0, 0 }, Normal3d{ 0, 1, 0 }, Normal3d{ 0, 0, 1 }
                    };
                    ret_pole_orient = CoordYOrient_MaxZ;
                }
                else {
                    vec_mat_out = NormalMatrix3d{
                        Normal3d{ 1, 0, 0 }, Normal3d{ 0, -1, 0 }, Normal3d{ 0, 0, -1 }
                    };
                    ret_pole_orient = CoordYOrient_MinZ;
                }
            } break;

            case CoordYOrient_ToNegativeZ:
            {
                if (radius_vec_z_projected_len >= 0) {
                    vec_mat_out = NormalMatrix3d{
                        Normal3d{ -1, 0, 0 }, Normal3d{ 0, -1, 0 }, Normal3d{ 0, 0, 1 }
                    };
                    ret_pole_orient = CoordYOrient_MaxZ;
                }
                else {
                    vec_mat_out = NormalMatrix3d{
                        Normal3d{ -1, 0, 0 }, Normal3d{ 0, 1, 0 }, Normal3d{ 0, 0, -1 }
                    };
                    ret_pole_orient = CoordYOrient_MinZ;
                }
            } break;
            }
        }

        // self test matrix on consistency
#if DEBUG_ASSERT_VERIFY_ENABLED
        NormalMatrix3d vec_mat_test;
        vector_cross_product(vec_mat_test.m[2], vec_mat_out.m[0], vec_mat_out.m[1]);
        vector_cross_product(vec_mat_test.m[0], vec_mat_out.m[1], vec_mat_out.m[2]);
        vector_cross_product(vec_mat_test.m[1], vec_mat_out.m[2], vec_mat_out.m[0]);

        const real unit_square_epsilon =
#if TACKLE_GEOM_ENABLE_DEBUG_WITH_ZERO_EPSILON
            FLT_EPSILON; // just something not zero
#else
            unit_epsilon * unit_epsilon;
#endif

        DEBUG_ASSERT_TRUE(vector_is_equal(vec_mat_test.m[0], vec_mat_out.m[0], unit_square_epsilon));
        DEBUG_ASSERT_TRUE(vector_is_equal(vec_mat_test.m[1], vec_mat_out.m[1], unit_square_epsilon));
        DEBUG_ASSERT_TRUE(vector_is_equal(vec_mat_test.m[2], vec_mat_out.m[2], unit_square_epsilon));
#endif

        return ret_pole_orient;
    }

    inline void rotate_coordinate_system_around_z(NormalMatrix3d & vec_mat_out, const NormalMatrix3d & vec_mat_in,
        const real & angle_rad, const real & unit_epsilon)
    {
        Normal3d basis_x_axis;
        Normal3d basis_y_axis;
        const Normal3d & basis_z_axis = vec_mat_in.m[2];

        vector_rotate(basis_y_axis, vec_mat_in.m[1], 1.0, basis_z_axis, angle_rad, unit_epsilon, unit_epsilon);
        vector_rotate(basis_x_axis, basis_y_axis, 1.0, basis_z_axis, -DEG_90_IN_RAD, unit_epsilon, unit_epsilon);

        vec_mat_out = NormalMatrix3d{
            basis_x_axis, basis_y_axis, basis_z_axis
        };
    }

    inline void transform_vector_into_coordinate_system(Vector3d & vec_out, const NormalMatrix3d & vec_mat, const Vector3d & vec_to_transform)
    {
        vec_out = Vector3d{
            vector_length_projection(vec_to_transform, vec_mat.m[0]),
            vector_length_projection(vec_to_transform, vec_mat.m[1]),
            vector_length_projection(vec_to_transform, vec_mat.m[2])
        };
    }

    // points_distance_epsilon - line distance beetween points on the track curve
    // radius_vector_length - length of a vector from site to the track curve point
    inline real points_distance_epsilon_to_support_angle_rad_epsilon(const real & points_distance_epsilon, const real & radius_vector_length)
    {
        // all epsilons must be positive
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(points_distance_epsilon, 0));
        DEBUG_ASSERT_GE(2 * radius_vector_length, points_distance_epsilon);

        real angle_sin = points_distance_epsilon / (2.0 * radius_vector_length);

        // fix to avoid the trigonometric functions return NAN
        angle_sin = math::fix_float_trigonometric_range(angle_sin);

        return 2.0 * asin(angle_sin);
    }

    // points_distance_epsilon - line distance beetween points on the track curve
    // radius_vector_length - length of a vector from site to the track curve point
    inline real points_distance_epsilon_to_radius_vector_epsilon(const real & points_distance_epsilon, const real & radius_vector_length)
    {
        // all epsilons must be positive
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(points_distance_epsilon, 0));

#if TACKLE_GEOM_ENABLE_DEBUG_WITH_ZERO_EPSILON
        return points_distance_epsilon != 0.0 ? (sqrt(radius_vector_length * radius_vector_length + points_distance_epsilon * points_distance_epsilon / 4) - radius_vector_length) : 0;
#else
        return sqrt(radius_vector_length * radius_vector_length + points_distance_epsilon * points_distance_epsilon / 4) - radius_vector_length;
#endif
    }

    // points_distance_epsilon - line distance beetween points on the track curve
    // radius_vector_length - length of a vector from site to the track curve point
    inline real radius_vector_epsilon_to_points_distance_epsilon(const real & radius_vector_epsilon, const real & radius_vector_length)
    {
        // all epsilons must be positive
        TACKLE_GEOM_DEBUG_WITH_ZERO_EPSILON(DEBUG_ASSERT_GT(radius_vector_epsilon, 0));

#if TACKLE_GEOM_ENABLE_DEBUG_WITH_ZERO_EPSILON
        return radius_vector_epsilon != 0.0 ? sqrt(radius_vector_epsilon * (radius_vector_epsilon + radius_vector_length * 2)) * 2 : 0;
#else
        return sqrt(radius_vector_epsilon * (radius_vector_epsilon + radius_vector_length * 2)) * 2;
#endif
    }

}
}
