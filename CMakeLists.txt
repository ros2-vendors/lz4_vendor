cmake_minimum_required(VERSION 3.7)

project(lz4_vendor)

find_package(ament_cmake REQUIRED)

option(FORCE_BUILD_VENDOR_PKG
  "Build lz4 from source, even if a system-installed package is available"
  OFF)

if(NOT FORCE_BUILD_VENDOR_PKG)
  # Attempt to find an existing lz4 installation
  find_package(lz4 QUIET)
endif()

macro(build_lz4)
  set(extra_cmake_args)
  if(DEFINED CMAKE_BUILD_TYPE)
    list(APPEND extra_cmake_args -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
  endif()
  if(DEFINED BUILD_SHARED_LIBS)
    list(APPEND extra_cmake_args -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS})
  else()
    list(APPEND extra_cmake_args -DBUILD_SHARED_LIBS=ON)
  endif()
  if(DEFINED CMAKE_TOOLCHAIN_FILE)
    list(APPEND extra_cmake_args "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
  endif()
  list(APPEND extra_cmake_args "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
  # lz4's CMake project lives in build/cmake, not the repo root
  list(APPEND extra_cmake_args -DLZ4_BUILD_CLI=OFF -DLZ4_BUILD_LEGACY_LZ4C=OFF)

  include(ExternalProject)

  # VxWorks source patches (see VxDocs/ros2/vxworks/vendors/lz4_vendor.md):
  #  - programs/bench.c: CLOCKS_PER_SEC is not a compile-time constant on VxWorks
  #  - build/cmake/CMakeLists.txt: drop the MSVC-style /W4 flag probe
  externalproject_add(lz4_external
    GIT_REPOSITORY https://github.com/lz4/lz4.git
    GIT_TAG v1.9.4
    GIT_CONFIG advice.detachedHead=false
    UPDATE_COMMAND ""
    TIMEOUT 600
    PATCH_COMMAND
      patch -p1 -N -r - < ${CMAKE_CURRENT_SOURCE_DIR}/patches/0001-bench-CLOCKS_PER_SEC.patch || true
      COMMAND patch -p1 -N -r - < ${CMAKE_CURRENT_SOURCE_DIR}/patches/0002-cmake-drop-W4.patch || true
    SOURCE_SUBDIR build/cmake
    CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_install
      ${extra_cmake_args}
  )

  install(
    DIRECTORY
      ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_install/
    DESTINATION
      ${CMAKE_INSTALL_PREFIX}
    USE_SOURCE_PERMISSIONS
  )
endmacro()

if(NOT lz4_FOUND)
  message(STATUS "Did not find lz4 installation, building from source")
  build_lz4()
endif()

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package(
  CONFIG_EXTRAS "lz4_vendor-extras.cmake"
)
