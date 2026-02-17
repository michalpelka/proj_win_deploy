cmake_minimum_required(VERSION 3.10)
project(proj_sample_app)

# Find PROJ library
add_library(proj SHARED IMPORTED)

set_target_properties(proj PROPERTIES
    IMPORTED_LOCATION "${CMAKE_SOURCE_DIR}/../install_proj/bin/proj_9_3.dll"
    IMPORTED_IMPLIB   "${CMAKE_SOURCE_DIR}/../install_proj/lib/proj.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/../install_proj/include"
)

# Create executable
add_executable(proj_sample simple_transform.cpp)
target_link_libraries(proj_sample PRIVATE proj)
target_compile_features(proj_sample PRIVATE cxx_std_11)


add_executable(grid_transform grid_transform.cpp)
target_link_libraries(grid_transform PRIVATE proj)
target_compile_features(grid_transform PRIVATE cxx_std_11)



add_custom_command(TARGET proj_sample POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:proj>
        $<TARGET_FILE_DIR:proj_sample>
)

add_custom_command(TARGET proj_sample POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/../install_proj/share/proj/proj.db"
        $<TARGET_FILE_DIR:proj_sample>
)

add_custom_command(TARGET grid_transform POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:proj>
        $<TARGET_FILE_DIR:proj_sample>
)

add_custom_command(TARGET grid_transform POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/../install_proj/bin/z.dll"
        $<TARGET_FILE_DIR:proj_sample>
)

add_custom_command(TARGET grid_transform POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/us_nga_egm08_25.tif"
        $<TARGET_FILE_DIR:proj_sample>
)
