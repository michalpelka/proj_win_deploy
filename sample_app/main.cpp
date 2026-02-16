// Sample application to test PROJ library installation
// Converts WGS84 coordinates to UTM projection

#include <proj.h>
#include <iostream>
#include <iomanip>

int main() {
    // Create PROJ context
    PJ_CONTEXT *ctx = proj_context_create();
    
    // Define transformation: WGS84 (EPSG:4326) to UTM Zone 33N (EPSG:32633)
    // Example: Berlin, Germany coordinates
    PJ *P = proj_create_crs_to_crs(ctx,
                                    "EPSG:4326",     // WGS84
                                    "EPSG:32633",    // UTM Zone 33N
                                    NULL);
    
    if (P == NULL) {
        std::cerr << "Failed to create transformation" << std::endl;
        proj_context_destroy(ctx);
        return 1;
    }
    
    // Normalize for input/output in radians for geographic, meters for projected
    PJ* P_norm = proj_normalize_for_visualization(ctx, P);
    if (P_norm == NULL) {
        std::cerr << "Failed to normalize transformation" << std::endl;
        proj_destroy(P);
        proj_context_destroy(ctx);
        return 1;
    }
    proj_destroy(P);
    P = P_norm;
    
    // Test coordinates: Berlin, Germany (latitude, longitude in degrees)
    double lat = 52.5200;  // degrees N
    double lon = 13.4050;  // degrees E
    
    std::cout << "Testing PROJ library installation" << std::endl;
    std::cout << "===================================" << std::endl;
    std::cout << std::fixed << std::setprecision(6);
    std::cout << "Input (WGS84):" << std::endl;
    std::cout << "  Latitude:  " << lat << " degrees" << std::endl;
    std::cout << "  Longitude: " << lon << " degrees" << std::endl;
    std::cout << std::endl;
    
    // Create coordinate structure
    PJ_COORD c_in, c_out;
    c_in = proj_coord(lon, lat, 0, 0);
    
    // Transform
    c_out = proj_trans(P, PJ_FWD, c_in);
    
    std::cout << "Output (UTM Zone 33N):" << std::endl;
    std::cout << "  Easting:  " << c_out.enu.e << " meters" << std::endl;
    std::cout << "  Northing: " << c_out.enu.n << " meters" << std::endl;
    std::cout << std::endl;
    
    // Verify transformation was successful
    if (c_out.enu.e == HUGE_VAL || c_out.enu.n == HUGE_VAL) {
        std::cerr << "ERROR: Transformation failed!" << std::endl;
        proj_destroy(P);
        proj_context_destroy(ctx);
        return 1;
    }
    
    // Expected values for Berlin (approximate)
    // UTM Zone 33N: E~391000, N~5820000
    if (c_out.enu.e > 390000 && c_out.enu.e < 392000 &&
        c_out.enu.n > 5819000 && c_out.enu.n < 5821000) {
        std::cout << "SUCCESS: Transformation result is within expected range!" << std::endl;
    } else {
        std::cout << "WARNING: Result outside expected range" << std::endl;
    }
    
    // Cleanup
    proj_destroy(P);
    proj_context_destroy(ctx);
    
    return 0;
}
