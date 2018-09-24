#pragma once

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>
#include <utility/memory.hpp>

#include <cstddef>
#include <cstdlib>
#include <string>
#include <functional>
#include <atomic>


#if defined(ENABLE_QD_QD_INTEGRATION)
#define REAL_AS_QD_REAL_INTEGRATION_ENABLED 1
#else
#define REAL_AS_QD_REAL_INTEGRATION_ENABLED 0
#endif

#if defined(ENABLE_QD_DD_INTEGRATION)
#define REAL_AS_DD_REAL_INTEGRATION_ENABLED 1
#else
#define REAL_AS_DD_REAL_INTEGRATION_ENABLED 0
#endif

#if REAL_AS_QD_REAL_INTEGRATION_ENABLED || REAL_AS_DD_REAL_INTEGRATION_ENABLED
#define REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED 1
#else
#define REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED 0
#endif


namespace tackle {
namespace geometry {

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)

#if defined(TACKLE_GEOM_REAL_FLOAT_TYPE)
using real = TACKLE_GEOM_REAL_FLOAT_TYPE;

// real as qd_real/dd_real from the QD library
#elif REAL_AS_QD_REAL_INTEGRATION_ENABLED
using real = qd_real;

#elif REAL_AS_DD_REAL_INTEGRATION_ENABLED
using real = dd_real;

#else

#error The `real` type is not defined properly

#endif

#else
using real = double;
#endif

const real real_min = (std::numeric_limits<real>::min)();
const real real_max = (std::numeric_limits<real>::max)();

#if defined(TACKLE_GEOM_REAL_FLOAT_TYPE)
const real real_pi = math::pi();

// real as qd_real/dd_real from the QD library
#elif REAL_AS_QD_REAL_INTEGRATION_ENABLED
const real real_pi = qd_real::_pi();

#elif REAL_AS_DD_REAL_INTEGRATION_ENABLED
const real real_pi = dd_real::_pi();

#endif

struct BasicVector3d
{
    using elem_type = real;
    using arr_type = elem_type[3];

    elem_type & operator [](size_t index)
    {
        DEBUG_ASSERT_LT(index, 3);
        switch (index) {
            case 0: return x;
            case 1: return y;
            case 2: return z;
        }
        return x;
    }

    elem_type operator [](size_t index) const
    {
        DEBUG_ASSERT_LT(index, 3);
        switch (index) {
            case 0: return x;
            case 1: return y;
            case 2: return z;
        }
        return elem_type{};
    }

    elem_type x, y, z;
};

struct Vector3d : BasicVector3d
{
    Vector3d(const Vector3d &) = default;

    Vector3d()
    {
        x = y = z = 0.0;
    }

    Vector3d(const real & x_, const real & y_, const real & z_)
    {
        x = x_;
        y = y_;
        z = z_;
    }

    ~Vector3d()
    {
    }
};

inline bool operator ==(const Vector3d & l, const Vector3d & r)
{
    return l.x == r.x && l.y == r.y && l.z == r.z;
}

inline bool operator !=(const Vector3d & l, const Vector3d & r)
{
    return l.x != r.x || l.y != r.y || l.z != r.z;
}

inline Vector3d operator +(const Vector3d & vec, double k)
{
    return Vector3d{ vec.x + k, vec.y + k, vec.z + k };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator +(const Vector3d & vec, const real & k)
{
    return Vector3d{ vec.x + k, vec.y + k, vec.z + k };
}
#endif

inline Vector3d operator +(double k, const Vector3d & vec)
{
    return Vector3d{ vec.x + k, vec.y + k, vec.z + k };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator +(const real & k, const Vector3d & vec)
{
    return Vector3d{ vec.x + k, vec.y + k, vec.z + k };
}
#endif

inline Vector3d operator +(const Vector3d & l, const Vector3d & r)
{
    return Vector3d{ l.x + r.x, l.y + r.y, l.z + r.z };
}

inline Vector3d operator -(const Vector3d & vec, double k)
{
    return Vector3d{ vec.x - k, vec.y - k, vec.z - k };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator -(const Vector3d & vec, const real & k)
{
    return Vector3d{ vec.x - k, vec.y - k, vec.z - k };
}
#endif

inline Vector3d operator -(const Vector3d & l, const Vector3d & r)
{
    return Vector3d{ l.x - r.x, l.y - r.y, l.z - r.z };
}

inline Vector3d operator -(const Vector3d & vec)
{
    return Vector3d{ -vec.x, -vec.y, -vec.z };
}

inline Vector3d operator *(const Vector3d & vec, double k)
{
    return Vector3d{ vec.x * k, vec.y * k, vec.z * k };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator *(const Vector3d & vec, const real & k)
{
    return Vector3d{ vec.x * k, vec.y * k, vec.z * k };
}
#endif

inline Vector3d operator *(double k, const Vector3d & vec)
{
    return Vector3d{ k * vec.x, k * vec.y, k * vec.z };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator *(const real & k, const Vector3d & vec)
{
    return Vector3d{ k * vec.x, k * vec.y, k * vec.z };
}
#endif

inline Vector3d operator /(const Vector3d & vec, double k)
{
    return Vector3d{ vec.x / k, vec.y / k, vec.z / k };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator /(const Vector3d & vec, const real & k)
{
    return Vector3d{ vec.x / k, vec.y / k, vec.z / k };
}
#endif

// normalized vector
struct Normal3d : public Vector3d
{
    Normal3d(const Normal3d &) = default;

    Normal3d() :
        Vector3d()
    {
    }

    explicit Normal3d(const Vector3d & vec) :
        Vector3d(vec)
    {
    }

    Normal3d(const real & x_, const real & y_, const real & z_) :
        Vector3d(x_, y_, z_)
    {
    }

    void fix_float_trigonometric_range_factor()
    {
        x = math::fix_float_trigonometric_range_factor(x);
        y = math::fix_float_trigonometric_range_factor(y);
        z = math::fix_float_trigonometric_range_factor(z);
    }
};

inline bool operator ==(const Normal3d & l, const Normal3d & r)
{
    return l.x == r.x && l.y == r.y && l.z == r.z;
}

inline bool operator !=(const Normal3d & l, const Normal3d & r)
{
    return l.x != r.x || l.y != r.y || l.z != r.z;
}

inline Normal3d operator -(const Normal3d & vec)
{
    return Normal3d{ -vec.x, -vec.y, -vec.z };
}

inline Vector3d operator *(const Normal3d & vec, double k)
{
    return Vector3d{ vec.x * k, vec.y * k, vec.z * k };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator *(const Normal3d & vec, const real & k)
{
    return Vector3d{ vec.x * k, vec.y * k, vec.z * k };
}
#endif

inline Vector3d operator *(double k, const Normal3d & vec)
{
    return Vector3d{ k * vec.x, k * vec.y, k * vec.z };
}

#if ERROR_IF_EMPTY_PP_DEF(REAL_INSTEAD_DOUBLE_INTEGRATION_ENABLED)
inline Vector3d operator *(const real & k, const Normal3d & vec)
{
    return Vector3d{ k * vec.x, k * vec.y, k * vec.z };
}
#endif

struct BasicVector4d
{
    using elem_type = real;
    using arr_type = elem_type[4];

    elem_type & operator [](size_t index)
    {
        DEBUG_ASSERT_LT(index, 3);
        switch (index) {
            case 0: return x;
            case 1: return y;
            case 2: return z;
            case 3: return w;
        }
        return x;
    }

    elem_type operator [](size_t index) const
    {
        DEBUG_ASSERT_LT(index, 3);
        switch (index) {
            case 0: return x;
            case 1: return y;
            case 2: return z;
            case 3: return w;
        }
        return elem_type{};
    }

    elem_type x, y, z, w;
};

struct Vector4d : public BasicVector4d
{
    Vector4d(const Vector4d &) = default;

    Vector4d()
    {
        x = y = z = w = 0.0;
    }

    Vector4d(const Vector3d & v, const real & w_)
    {
        x = v.x;
        y = v.y;
        z = v.z;
        w = w_;
    }

    Vector4d(const real & x_, const real & y_, const real & z_, const real & w_)
    {
        x = x_;
        y = y_;
        z = z_;
        w = w_;
    }

    Vector3d basis() const
    {
        return Vector3d{ x, y, z };
    }
};

inline bool operator ==(const Vector4d & l, const Vector4d & r)
{
    return l.x == r.x && l.y == r.y && l.z == r.z && l.w == r.w;
}

inline bool operator !=(const Vector4d & l, const Vector4d & r)
{
    return l.x != r.x || l.y != r.y || l.z != r.z || l.w != r.w;
}

inline Vector3d operator -(const Vector4d & l, const Vector4d & r)
{
    return Vector3d{ l.x - r.x, l.y - r.y, l.z - r.z };
}

inline Vector3d operator +(const Vector4d & l, const Vector4d & r)
{
    return Vector3d{ l.x + r.x, l.y + r.y, l.z + r.z };
}

struct NormalMatrix3d
{
    NormalMatrix3d(const NormalMatrix3d &) = default;

    NormalMatrix3d()
    {
    }

    NormalMatrix3d(const Normal3d (& vec_mat)[3]) :
        m{ vec_mat[0], vec_mat[1], vec_mat[2] }
    {
    }

    NormalMatrix3d(const Normal3d & vec0, const Normal3d & vec1, const Normal3d & vec2) :
        m{ vec0, vec1, vec2 }
    {
    }

    Normal3d & operator [](size_t index)
    {
        DEBUG_ASSERT_LT(index, 3);
        return m[index];
    }

    const Normal3d & operator [](size_t index) const
    {
        DEBUG_ASSERT_LT(index, 3);
        return m[index];
    }

    void fix_float_trigonometric_range_factor()
    {
        m[0].fix_float_trigonometric_range_factor();
        m[1].fix_float_trigonometric_range_factor();
        m[2].fix_float_trigonometric_range_factor();
    }

    void validate(const real & unit_square_epsilon) const;

    Normal3d m[3];
};

inline bool operator ==(const NormalMatrix3d & l, const NormalMatrix3d & r)
{
    return l.m[0] == r.m[0] && l.m[1] == r.m[1] && l.m[2] == r.m[2];
}

inline bool operator !=(const NormalMatrix3d & l, const NormalMatrix3d & r)
{
    return l.m[0] != r.m[0] || l.m[1] != r.m[1] || l.m[2] != r.m[2];
}

extern void vector_cross_product(Vector3d & vec_out, const Vector3d & vec_first, const Vector3d & vec_second);
extern bool vector_is_equal(const Vector3d & l, const Vector3d & r, const real & vec_square_epsilon);

inline void NormalMatrix3d::validate(const real & unit_square_epsilon) const
{
    // self test matrix on consistency
#if DEBUG_ASSERT_VERIFY_ENABLED
    NormalMatrix3d vec_mat_test;
    vector_cross_product(vec_mat_test.m[2], m[0], m[1]);
    vector_cross_product(vec_mat_test.m[0], m[1], m[2]);
    vector_cross_product(vec_mat_test.m[1], m[2], m[0]);

    DEBUG_ASSERT_TRUE(vector_is_equal(vec_mat_test.m[0], m[0], unit_square_epsilon));
    DEBUG_ASSERT_TRUE(vector_is_equal(vec_mat_test.m[1], m[1], unit_square_epsilon));
    DEBUG_ASSERT_TRUE(vector_is_equal(vec_mat_test.m[2], m[2], unit_square_epsilon));
#else
    UTILITY_UNUSED_EXPR(unit_square_epsilon);
#endif
}

}
}
