#pragma once

#include <utility/platform.hpp>
#include <utility/static_assert.hpp>
#include <utility/assert.hpp>
#include <utility/math.hpp>
#include <utility/memory.hpp>

#include <tackle/aligned_storage_decl.hpp>

#include <cstddef>
#include <cstdlib>
#include <string>
#include <functional>
#include <atomic>


// Legend:
//
// * TLE coordinate system has 2 axis:
//      az=[0..360]
//      el=[-90..+90], where elevation reference - Plane
//
// * Site coordinate system has 3 axis:
//      az=[-360..+360]
//      el=[-90..+90], if elevation reference - Plane Normal
//      el=[0..180], if elevation reference - Plane
//      za=[-90..+90] (z-axis)
//
// * SiteTle:
//      The same as the Site but w/o z-axis.
//

#if 0
// Event types, codes and flags.
//
//  LoopbackEvent::Type::Failure:
//
//      code = 1: Basic failures
//      flags:
//          0x00000001 - common failure
//          0x00000002 - azimuth engine failure
//          0x00000004 - elevation engine failure
//          0x00000008 - z-axis engine failure
//          0x00000010 - azimuth sensor failure
//          0x00000020 - elevation sensor failure
//          0x00000040 - z-axis sensor failure
//          0x00000080 - FLASH memory failure
//
//  LoopbackEvent::Type::Triggers:
//
//      code = 1: Hardware limit triggers
//      flags:
//          0x00000000 - azimuth left limit trigger
//          0x00000001 - azimuth right limit trigger
//          0x00000002 - elevation bottom limit trigger
//          0x00000004 - elevation top limit trigger
//          0x00000008 - z-axis negative limit trigger
//          0x00000010 - z-axis positive limit trigger
//
//      code = 2: Software limit triggers
//      flags:
//          0x00000000 - azimuth left limit trigger
//          0x00000001 - azimuth right limit trigger
//          0x00000002 - elevation bottom limit trigger
//          0x00000004 - elevation top limit trigger
//          0x00000008 - z-axis negative limit trigger
//          0x00000010 - z-axis positive limit trigger
//
//      code = 3: Antenna moving
//      flags:
//          0x00000000 - azimuth to left moving
//          0x00000001 - azimuth to right moving
//          0x00000002 - elevation down moving
//          0x00000004 - elevation up moving
//          0x00000008 - z-axis to negative moving
//          0x00000010 - z-axis to positive moving
//
#endif


namespace st {

struct Vector3d
{
    using arr_type = double[3];

    Vector3d(const Vector3d &) = default;

    Vector3d() :
        x(0), y(0), z(0)
    {
    }

    Vector3d(double x_, double y_, double z_) :
        x(x_), y(y_), z(z_)
    {
    }

    ~Vector3d()
    {
    }

    double & operator [](size_t index)
    {
        DEBUG_ASSERT_LT(index, 3);
        return v[index];
    }

    double operator [](size_t index) const
    {
        DEBUG_ASSERT_LT(index, 3);
        return v[index];
    }

    union {
        double x, y, z;
        arr_type v;
    };
};

inline Vector3d operator -(const Vector3d & vec)
{
    return Vector3d{ -vec.x, -vec.y, -vec.z };
}

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

    Normal3d(double x_, double y_, double z_) :
        Vector3d(x_, y_, z_)
    {
    }
};

inline Normal3d operator -(const Normal3d & vec)
{
    return Normal3d{ -vec.x, -vec.y, -vec.z };
}

struct Vector4d : public Vector3d
{
    using arr_type = double[4];

    Vector4d(const Vector4d &) = default;

    Vector4d() :
        Vector3d(), w(0)
    {
    }

    Vector4d(const Vector3d & v, double w_) :
        Vector3d(v), w(w_)
    {
    }

    Vector4d(double x_, double y_, double z_, double w_) :
        Vector3d(x_, y_, z_), w(w_)
    {
    }

    double & operator [](size_t index)
    {
        STATIC_ASSERT_EQ(offsetof(Vector4d, v) + 3 * sizeof(double), offsetof(Vector4d, w), "declval(Vector3d).v[3] and declval(Vector4d).w must has the same class member offset");
        DEBUG_ASSERT_LT(index, 4);
        return utility::cast_addressof<double *>(v)[index];
    }

    double operator [](size_t index) const
    {
        STATIC_ASSERT_EQ(offsetof(Vector4d, v) + 3 * sizeof(double), offsetof(Vector4d, w), "declval(Vector3d).v[3] and declval(Vector4d).w must has the same class member offset");
        DEBUG_ASSERT_LT(index, 4);
        return utility::cast_addressof<const double *>(v)[index];
    }

    double w;
};

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

    Normal3d m[3];
};

// The earth-centered inertial.
struct VectorTrackPos
{
    VectorTrackPos() = default;
    VectorTrackPos(const VectorTrackPos &) = default;

    VectorTrackPos(const Vector4d & pos_, const Vector4d & vel_) :
        pos(pos_), vel(vel_)
    {
    }

    Vector4d pos;
    Vector4d vel;
};

struct GeoPos
{
    GeoPos(const GeoPos &) = default;

    GeoPos() :
        lat_deg(0), lon_deg(0), alt_km(0)
    {
    }

    GeoPos(double lat_deg_, double lon_deg_, double alt_km_) :
        lat_deg(lat_deg_), lon_deg(lon_deg_), alt_km(alt_km_)
    {
    }

    double lat_deg; // latitude in degrees
    double lon_deg; // longitude in degrees
    double alt_km;  // altitude in kilometers
};

struct TagNoInput {};

template <int N>
struct TleAngleTrackPos_scope
{
    struct TleAngleTrackPos
    {
        TleAngleTrackPos(const TleAngleTrackPos &) = default;

        TleAngleTrackPos() :
            az(0), el(0)
        {
        }

        TleAngleTrackPos(double az_, double el_) :
            az(az_), el(el_)
        {
        }

        TleAngleTrackPos(TagNoInput) :
            az(math::quiet_NaN), el(math::quiet_NaN)
        {
        }

        double  az; // azimuth
        double  el; // elevation
    };
};

using TleAngleTrackPos              = TleAngleTrackPos_scope<0>::TleAngleTrackPos;
using SiteTleAngleTrackPos          = TleAngleTrackPos_scope<1>::TleAngleTrackPos;
using SiteTleAngleTrackSpeed        = TleAngleTrackPos_scope<2>::TleAngleTrackPos;
using SiteTleAngleTrackSpeedRate    = TleAngleTrackPos_scope<3>::TleAngleTrackPos;
using SiteTleAngleTrackJerk         = TleAngleTrackPos_scope<4>::TleAngleTrackPos;

template <int N>
struct AngleTrackPos_scope
{
    struct AngleTrackPos
    {
        AngleTrackPos(const AngleTrackPos &) = default;

        AngleTrackPos() :
            az(0), el(0), za(0)
        {
        }

        AngleTrackPos(double az_, double el_, double za_) :
            az(az_), el(el_), za(za_)
        {
        }

        AngleTrackPos(TagNoInput) :
            az(math::quiet_NaN), el(math::quiet_NaN), za(math::quiet_NaN)
        {
        }

        AngleTrackPos(const SiteTleAngleTrackPos & site_tle_track_pos) :
            az(site_tle_track_pos.az), el(site_tle_track_pos.el), za(0)
        {
        }

        double  az; // azimuth
        double  el; // elevation
        double  za; // z-axis
    };
};

using SiteAngleTrackPos         = AngleTrackPos_scope<0>::AngleTrackPos;
using SiteAngleTrackSpeed       = AngleTrackPos_scope<1>::AngleTrackPos;
using SiteAngleTrackSpeedRate   = AngleTrackPos_scope<2>::AngleTrackPos;
using SiteAngleTrackJerk        = AngleTrackPos_scope<3>::AngleTrackPos;

struct SiteTleAngleTrackTimePos;

struct SiteAngleTrackTimePos : SiteAngleTrackPos
{
    SiteAngleTrackTimePos(const SiteAngleTrackTimePos &) = default;

    SiteAngleTrackTimePos() :
        utc_time_mcsec(0)
    {
    }

    SiteAngleTrackTimePos(const AngleTrackPos & ang_pos, uint64_t utc_time_mcsec_) :
        AngleTrackPos(ang_pos), utc_time_mcsec(utc_time_mcsec_)
    {
    }

    SiteAngleTrackTimePos(TagNoInput) :
        AngleTrackPos(TagNoInput{}), utc_time_mcsec(math::uint64_max)
    {
    }

    SiteAngleTrackTimePos(const SiteTleAngleTrackTimePos & ang_track_time_pos);

    uint64_t utc_time_mcsec; // actual UTC time in microseconds (0 if initial)
};

// TLE coordinates in the TLE coordinate system
struct TleTrackTimePos
{
    TleTrackTimePos(const TleTrackTimePos &) = default;

    TleTrackTimePos() :
        utc_time_epoch_day(0), utc_time_mpe(0)
    {
    }

    TleTrackTimePos(const VectorTrackPos & vec_pos_, const TleAngleTrackPos & ang_pos_, double utc_time_epoch_day_, double utc_time_mpe_) :
        vec_pos(vec_pos_), ang_pos(ang_pos_),
        utc_time_epoch_day(utc_time_epoch_day_), utc_time_mpe(utc_time_mpe_)
    {
    }

    VectorTrackPos          vec_pos;            // vector from the site to the target (not the Earth Centred Inertial!)
    TleAngleTrackPos        ang_pos;            // angles from the site to the target in TLE coordinate system (az=[0..360], el=[0..90])
    double                  utc_time_epoch_day; // in days
    double                  utc_time_mpe;       // minutes past epoch
};

// angle TLE coordinates in the Site coordinate system
struct SiteTleAngleTrackTimePos
{
    SiteTleAngleTrackTimePos(const SiteTleAngleTrackTimePos &) = default;

    SiteTleAngleTrackTimePos() :
        utc_time_epoch_day(0), utc_time_mpe(0)
    {
    }

    SiteTleAngleTrackTimePos(const SiteTleAngleTrackPos & ang_pos_, double utc_time_epoch_day_, double utc_time_mpe_) :
        ang_pos(ang_pos_),
        utc_time_epoch_day(utc_time_epoch_day_), utc_time_mpe(utc_time_mpe_)
    {
    }

    SiteTleAngleTrackPos    ang_pos;            // angles from the site to the target in site coordinate system (az=[-360..+360], el=[-90..+90] or el=[0..90])
    double                  utc_time_epoch_day; // in days
    double                  utc_time_mpe;       // minutes past epoch
};

// vector from the site to the target (with center in the Site instead of Earth)
struct SiteVectorTrackPos
{
    SiteVectorTrackPos() = default;
    SiteVectorTrackPos(const SiteVectorTrackPos&) = default;

    SiteVectorTrackPos(const Vector4d & pos_, const Vector4d & vel_) :
        vec_pos(pos_, vel_)
    {
    }

    SiteVectorTrackPos(const VectorTrackPos & vec_pos_) :
        vec_pos(vec_pos_)
    {
    }

    VectorTrackPos vec_pos;
};

// TLE coordinates in the Site coordinate system
struct SiteTleTrackTimePos : SiteVectorTrackPos, SiteTleAngleTrackTimePos
{
    SiteTleTrackTimePos() = default;
    SiteTleTrackTimePos(const SiteTleTrackTimePos &) = default;

    SiteTleTrackTimePos(const VectorTrackPos & vec_pos_, const SiteTleAngleTrackPos & ang_pos_, double utc_time_epoch_day_, double utc_time_mpe_) :
        SiteVectorTrackPos(vec_pos_), SiteTleAngleTrackTimePos(ang_pos_, utc_time_epoch_day_, utc_time_mpe_)
    {
    }
};

struct SiteTleTrackInertialPos
{
    SiteTleTrackInertialPos() = default;
    SiteTleTrackInertialPos(const SiteTleTrackInertialPos &) = default;

    SiteTleTrackInertialPos(const SiteTleAngleTrackTimePos & pos_, const SiteTleAngleTrackSpeed & speed_, const SiteTleAngleTrackSpeedRate & speed_rate_) :
        pos(pos_), speed(speed_), speed_rate(speed_rate_)
    {
    }

    SiteTleAngleTrackTimePos    pos;
    SiteTleAngleTrackSpeed      speed;
    SiteTleAngleTrackSpeedRate  speed_rate;
};

struct SiteTrackInertialPos
{
    SiteTrackInertialPos() = default;
    SiteTrackInertialPos(const SiteTrackInertialPos &) = default;

    SiteTrackInertialPos(const SiteAngleTrackTimePos & pos_, const SiteAngleTrackSpeed & speed_, const SiteAngleTrackSpeedRate & speed_rate_) :
        pos(pos_), speed(speed_), speed_rate(speed_rate_)
    {
    }

    SiteTrackInertialPos(TagNoInput) :
        pos(TagNoInput{}), speed(TagNoInput{}), speed_rate(TagNoInput{})
    {
    }

    SiteTrackInertialPos(const SiteTleTrackInertialPos & site_tle_track_inert_pos) :
        pos(site_tle_track_inert_pos.pos)
    {
    }

    SiteAngleTrackTimePos   pos;
    SiteAngleTrackSpeed     speed;
    SiteAngleTrackSpeedRate speed_rate;
};

struct TleTrackWindow
{
    TleTrackWindow(const TleTrackWindow &) = default;

    TleTrackWindow() :
        is_target_on_track(false)
    {
    }

    TleTrackWindow(const TleTrackTimePos & start_track_pos_, const TleTrackTimePos & end_track_pos_, bool is_target_on_track_) :
        start_track_pos(start_track_pos_), end_track_pos(end_track_pos_), is_target_on_track(is_target_on_track_)
    {
    }

    TleTrackTimePos start_track_pos;        // rise position if target is not in track window, otherwise target position
    TleTrackTimePos end_track_pos;          // settings position
    bool            is_target_on_track;
};

struct SiteTleTrackWindow
{
    SiteTleTrackWindow() = default;
    SiteTleTrackWindow(const SiteTleTrackWindow &) = default;

    SiteTleTrackWindow(const SiteTleTrackTimePos & start_track_pos_, const SiteTleTrackTimePos & end_track_pos_) :
        start_track_pos(start_track_pos_), end_track_pos(end_track_pos_)
    {
    }

    SiteTleTrackTimePos start_track_pos;    // rise position if target is not in track window, otherwise target position
    SiteTleTrackTimePos end_track_pos;      // setting position
};

struct SiteTrackWindow
{
    SiteTrackWindow() = default;
    SiteTrackWindow(const SiteTrackWindow &) = default;

    SiteTrackWindow(const SiteAngleTrackPos & start_track_ang_pos_, const SiteAngleTrackPos & end_track_ang_pos_) :
        start_track_ang_pos(start_track_ang_pos_), end_track_ang_pos(end_track_ang_pos_)
    {
    }

    SiteAngleTrackPos   start_track_ang_pos;    // rise position if target is not in track window, otherwise target position
    SiteAngleTrackPos   end_track_ang_pos;      // setting position
};

enum ElevationReferenceType
{
    ElevationReference_HorizontPlaneNormal  = 1,    // range [-90..+90]
    ElevationReference_HorizontPlane        = 2,    // range [0..+180]
};

}
