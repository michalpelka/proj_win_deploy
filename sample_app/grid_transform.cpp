#include <proj.h>
#include <iostream>
#include <iomanip>
#include <cmath>

int main()
{
    std::cout << "=== WGS84 ellipsoidal → Geoid height (EGM2008) ===\n";

    PJ_CONTEXT* ctx = proj_context_create();
    if (!ctx) {
        std::cerr << "Failed to create PROJ context\n";
        return 1;
    }

    // WGS84 3D → EGM2008 geoid height
    PJ* P = proj_create_crs_to_crs(
        ctx,
        "EPSG:4979",   // WGS84 lat, lon, ellipsoidal height
        "EPSG:3855",   // EGM2008 height
        nullptr
    );

    if (!P) {
        std::cerr << "Failed to create transformation (missing geoid grid?)\n";
        proj_context_destroy(ctx);
        return 1;
    }

    PJ* P_norm = proj_normalize_for_visualization(ctx, P);
    proj_destroy(P);
    P = P_norm;

    if (!P) {
        std::cerr << "Failed to normalize transformation\n";
        proj_context_destroy(ctx);
        return 1;
    }

    // Example: Berlin
    double lat = 52.5200;
    double lon = 13.4050;
    double h_ellipsoid = 100.0;  // 100 m ellipsoidal height

    std::cout << std::fixed << std::setprecision(4);
    std::cout << "Input:\n";
    std::cout << "  Lat: " << lat << "\n";
    std::cout << "  Lon: " << lon << "\n";
    std::cout << "  Ellipsoidal height: " << h_ellipsoid << " m\n\n";

    PJ_COORD in = proj_coord(lon, lat, h_ellipsoid, 0);
    PJ_COORD out = proj_trans(P, PJ_FWD, in);

    if (out.xyz.z == HUGE_VAL) {
        std::cerr << "ERROR: Transformation failed (geoid grid missing?)\n";
        proj_destroy(P);
        proj_context_destroy(ctx);
        return 1;
    }

    std::cout << "Output:\n";
    std::cout << "  Orthometric height (EGM2008): "
              << out.xyz.z << " m\n";

    double geoid_undulation = h_ellipsoid - out.xyz.z;

    std::cout << "\nComputed geoid undulation: "
              << geoid_undulation << " m\n";

    if (std::fabs(geoid_undulation) > 0.01) {
        std::cout << "\nSUCCESS: Geoid correction applied (GeoTIFF working)\n";
    } else {
        std::cout << "\nWARNING: No geoid correction detected\n";
    }

    proj_destroy(P);
    proj_context_destroy(ctx);

    return 0;
}