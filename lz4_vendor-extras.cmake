find_package(lz4 QUIET)

if(NOT TARGET LZ4::lz4)
  find_library(lz4_LIBRARY NAMES lz4 liblz4)
  find_path(lz4_INCLUDE_DIR NAMES lz4.h)
  if(lz4_LIBRARY AND lz4_INCLUDE_DIR)
    add_library(LZ4::lz4 SHARED IMPORTED)
    set_target_properties(LZ4::lz4 PROPERTIES
      IMPORTED_LOCATION "${lz4_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${lz4_INCLUDE_DIR}")
  endif()
endif()
