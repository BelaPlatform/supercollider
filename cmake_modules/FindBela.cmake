# - Try to find Bela
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

function(run_bela_config FLAG OUT)
    execute_process(COMMAND ${BELA_CONFIG} ${FLAG} OUTPUT_VARIABLE OUTP RESULT_VARIABLE RET)
    if(RET)
        message(FATAL_ERROR "bela-config failed")
    endif()
    string(STRIP "${OUTP}" OUTP)
    set(${OUT} "${OUTP}" PARENT_SCOPE)
endfunction()

if(BELA_CFLAGS AND BELA_CXXFLAGS AND BELA_LDFLAGS)
    # in cache already
    set(BELA_FOUND TRUE)
else()
    # Bela comes with its own ...-config program to get configuration flags
    if(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
        # ifcross compiling, we want to find this program only from the sysroot
        set(CACHED ${CMAKE_FIND_ROOT_PATH_MODE_PROGRAM})
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
    endif()
    find_program(BELA_CONFIG
        NAMES
        bela-config
        PATHS
        /root/Bela/resources/bin
        $ENV{BELA_ROOT}/resources/bin
        /usr/local/bin
        /usr/bin
        )
    if(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
        # restore the previous value
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ${CACHED})
    endif()
    message("Searching for BELA man: config ${BELA_CONFIG}")

    if(BELA_CONFIG)
        # each of these calls may throw a FATAL_ERROR
        run_bela_config(--defines BELA_DEFINITIONS)
        run_bela_config(--includes BELA_INCLUDE_DIRS)
        run_bela_config(--libraries BELA_LIBRARIES)
        run_bela_config(--cflags BELA_C_FLAGS)
        run_bela_config(--cxxflags BELA_CXX_FLAGS)
        set(BELA_CXX_FLAGS "${BELA_CXX_FLAGS} -DBELA_DONT_INCLUDE_UTILITIES")

        set(BELA_FOUND TRUE)
    endif()

    if(BELA_FOUND)
        if(NOT BELA_FIND_QUIETLY)
            execute_process(COMMAND ${BELA_CONFIG} --prefix OUTPUT_VARIABLE BELA_PREFIX)
            message(STATUS "Found Bela: ${BELA_PREFIX}")
            message(STATUS "BELA_DEFINITIONS: ${BELA_DEFINITIONS}")
            message(STATUS "BELA_INCLUDE_DIRS: ${BELA_INCLUDE_DIRS}")
            message(STATUS "BELA_LIBRARIES: ${BELA_LIBRARIES}")
            message(STATUS "BELA_C_FLAGS: ${BELA_C_FLAGS}")
            message(STATUS "BELA_CXX_FLAGS: ${BELA_CXX_FLAGS}")
        endif()
    else()
        message(FATAL_ERROR "Could not find BELA")
    endif()

    # show the BELA_ variables only in the advanced view
    mark_as_advanced(BELA_CFLAGS BELA_CXXFLAGS BELA_LDFLAGS)
endif()
