cmake_minimum_required(VERSION 3.10)
project(proj_sample_app)

# Find PROJ library
find_package(PROJ REQUIRED CONFIG)

# Create executable
add_executable(proj_sample main.cpp)

# Link with PROJ library
target_link_libraries(proj_sample PRIVATE PROJ::proj)

# Set C++ standard
target_compile_features(proj_sample PRIVATE cxx_std_11)
