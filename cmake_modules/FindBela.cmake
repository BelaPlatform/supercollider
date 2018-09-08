# - Try to find Bela (BeagleRT)
# Once done this will define
#
#  BELA_FOUND - system has bela
#  BELA_INCLUDE_DIRS - the bela include directory
#  BELA_SOURCES - the bela source files to compile in
#  BELA_LIBRARIES - Link these too please
#  BELA_DEFINITIONS - Compiler switches required for using bela
#
#  Copyright (c) 2008 Andreas Schneider <mail@cynapses.org>
#  Modified for other libraries by Lasse Kärkkäinen <tronic>
#
#  Redistribution and use is allowed according to the terms of the New
#  BSD license.
#  For details see the accompanying COPYING-CMAKE-SCRIPTS file.
#

if (BELA_CFLAGS AND BELA_CXXFLAGS AND BELA_LDFLAGS)
  # in cache already
  set(BELA_FOUND TRUE)
else (BELA_CFLAGS AND BELA_CXXFLAGS AND BELA_LDFLAGS)
  # Bela comes with its own ...-config program to get configuration flags
  if (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
    # if cross compiling, we want to find this program only from the sysroot
    set(CACHED ${CMAKE_FIND_ROOT_PATH_MODE_PROGRAM})
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
  endif (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
  find_program(BELA_CONFIG
    NAMES
      bela-config
    PATHS
      /root/Bela/resources/bin
      $ENV{BELA_ROOT}/resources/bin
      /usr/local/bin
      /usr/bin
  )
  if (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
    # restore the previous value
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ${CACHED})
  endif (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
message("Searching for BELA man: config ${BELA_CONFIG}")

  if (BELA_CONFIG)
    execute_process(COMMAND ${BELA_CONFIG} --defines OUTPUT_VARIABLE BELA_DEFINITIONS)
    string(STRIP "${BELA_DEFINITIONS}" BELA_DEFINITIONS)
    execute_process(COMMAND ${BELA_CONFIG} --includes OUTPUT_VARIABLE BELA_INCLUDE_DIRS)
    string(STRIP "${BELA_INCLUDE_DIRS}" BELA_INCLUDE_DIRS)
    execute_process(COMMAND ${BELA_CONFIG} --libraries OUTPUT_VARIABLE BELA_LIBRARIES)
    string(STRIP "${BELA_LIBRARIES}" BELA_LIBRARIES)
    execute_process(COMMAND ${BELA_CONFIG} --cflags OUTPUT_VARIABLE BELA_C_FLAGS)
    string(STRIP "${BELA_C_FLAGS}" BELA_C_FLAGS)
    execute_process(COMMAND ${BELA_CONFIG} --cxxflags OUTPUT_VARIABLE BELA_CXX_FLAGS)
    string(STRIP "${BELA_CXX_FLAGS}" BELA_CXX_FLAGS)
    SET(BELA_CXX_FLAGS "${BELA_CXX_FLAGS} -DBELA_DONT_INCLUDE_UTILITIES")
  endif (BELA_CONFIG)

  if (BELA_CONFIG)
    set(BELA_FOUND TRUE)
  endif (BELA_CONFIG)

  if (BELA_FOUND)
    if (NOT BELA_FIND_QUIETLY)
      execute_process(COMMAND ${BELA_CONFIG} --prefix OUTPUT_VARIABLE BELA_PREFIX)
      message(STATUS "Found Bela: ${BELA_PREFIX}")
      message(STATUS "BELA_DEFINITIONS: ${BELA_DEFINITIONS}")
      message(STATUS "BELA_INCLUDE_DIRS: ${BELA_INCLUDE_DIRS}")
      message(STATUS "BELA_LIBRARIES: ${BELA_LIBRARIES}")
      message(STATUS "BELA_C_FLAGS: ${BELA_C_FLAGS}")
      message(STATUS "BELA_CXX_FLAGS: ${BELA_CXX_FLAGS}")
    endif (NOT BELA_FIND_QUIETLY)
  else (BELA_FOUND)
    if (BELA_FIND_REQUIRED)
      message(FATAL_ERROR "Could not find BELA")
    endif (BELA_FIND_REQUIRED)
  endif (BELA_FOUND)
# show the BELA_ variables only in the advanced view
mark_as_advanced(BELA_CFLAGS BELA_CXXFLAGS BELA_LDFLAGS)

endif (BELA_CFLAGS AND BELA_CXXFLAGS AND BELA_LDFLAGS)
