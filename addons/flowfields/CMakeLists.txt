cmake_minimum_required(VERSION 3.16)
project(flowfield LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include(FetchContent)

# Automatically fetch godot-cpp into the local build folder during configuration
FetchContent_Declare(
    godot-cpp
    GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
    GIT_TAG        godot-4.3-stable
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(godot-cpp)

set(SOURCES
    src/register_types.cpp
    src/flow_field.cpp
)

set(HEADERS
    src/register_types.h
    src/flow_field.h
)

add_library(flowfield SHARED ${SOURCES} ${HEADERS})

target_include_directories(flowfield PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(flowfield PRIVATE
    godot::cpp
)

# Output compiled binaries to addons/flowfields/bin/ with platform naming
if(ANDROID)
    target_link_options(flowfield PRIVATE "-Wl,-z,max-page-size=16384")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(LIB_NAME "flowfield.android.debug.arm64")
    else()
        set(LIB_NAME "flowfield.android.release.arm64")
    endif()
else()
    set(LIB_NAME "flowfield")
endif()

set_target_properties(flowfield PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
    PREFIX "lib"
    OUTPUT_NAME "${LIB_NAME}"
)
