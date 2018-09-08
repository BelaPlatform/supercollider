# - Try to find xenomai
# Once done this will define
#
#    XENOMAI_FOUND - system has xenomai
#    XENOMAI_INCLUDE_DIRS - the xenomai include directory
#    XENOMAI_LIBRARIES - Link these to use xenomai
#    XENOMAI_DEFINITIONS - Compiler switches required for using xenomai
#
#    Copyright (c) 2008 Andreas Schneider <mail@cynapses.org>
#    Modified for other libraries by Lasse Kärkkäinen <tronic>
#
#    Redistribution and use is allowed according to the terms of the New
#    BSD license.
#    For details see the accompanying COPYING-CMAKE-SCRIPTS file.
#

# https://cmake.org/Wiki/CMakeMacroParseArguments

MACRO(PARSE_ARGUMENTS prefix arg_names option_names)
    SET(DEFAULT_ARGS)
    FOREACH(arg_name ${arg_names})
        SET(${prefix}_${arg_name})
    ENDFOREACH(arg_name)
    FOREACH(option ${option_names})
        SET(${prefix}_${option} FALSE)
    ENDFOREACH(option)

    SET(current_arg_name DEFAULT_ARGS)
    SET(current_arg_list)
    FOREACH(arg ${ARGN})
        SET(larg_names ${arg_names})
        LIST(FIND larg_names "${arg}" is_arg_name)
        IF (is_arg_name GREATER -1)
            SET(${prefix}_${current_arg_name} ${current_arg_list})
            SET(current_arg_name ${arg})
            SET(current_arg_list)
        ELSE (is_arg_name GREATER -1)
            SET(loption_names ${option_names})
            LIST(FIND loption_names "${arg}" is_option)
            IF (is_option GREATER -1)
                SET(${prefix}_${arg} TRUE)
            ELSE (is_option GREATER -1)
                SET(current_arg_list ${current_arg_list} ${arg})
            ENDIF (is_option GREATER -1)
        ENDIF (is_arg_name GREATER -1)
    ENDFOREACH(arg)
    SET(${prefix}_${current_arg_name} ${current_arg_list})
ENDMACRO(PARSE_ARGUMENTS)

# LIST_FILTER(<list> <regexp_var> [<regexp_var> ...]
#                            [OUTPUT_VARIABLE <variable>])
# Removes items from <list> which do not match any of the specified
# regular expressions. An optional argument OUTPUT_VARIABLE
# specifies a variable in which to store the matched items instead of
# updating <list>
# As regular expressions can not be given to macros (see bug #5389), we pass
# variable names whose content is the regular expressions.
# Note that this macro requires PARSE_ARGUMENTS macro, available here:
# http://www.cmake.org/Wiki/CMakeMacroParseArguments
MACRO(LIST_FILTER)
    PARSE_ARGUMENTS(LIST_FILTER "OUTPUT_VARIABLE" "" ${ARGV})
    # Check arguments.
    LIST(LENGTH LIST_FILTER_DEFAULT_ARGS LIST_FILTER_default_length)
    IF(${LIST_FILTER_default_length} EQUAL 0)
        MESSAGE(FATAL_ERROR "LIST_FILTER: missing list variable.")
    ENDIF(${LIST_FILTER_default_length} EQUAL 0)
    IF(${LIST_FILTER_default_length} EQUAL 1)
        MESSAGE(FATAL_ERROR "LIST_FILTER: missing regular expression variable.")
    ENDIF(${LIST_FILTER_default_length} EQUAL 1)
    # Reset output variable
    IF(NOT LIST_FILTER_OUTPUT_VARIABLE)
        SET(LIST_FILTER_OUTPUT_VARIABLE "LIST_FILTER_internal_output")
    ENDIF(NOT LIST_FILTER_OUTPUT_VARIABLE)
    SET(${LIST_FILTER_OUTPUT_VARIABLE})
    # Extract input list from arguments
    LIST(GET LIST_FILTER_DEFAULT_ARGS 0 LIST_FILTER_input_list)
    LIST(REMOVE_AT LIST_FILTER_DEFAULT_ARGS 0)
    FOREACH(LIST_FILTER_item ${${LIST_FILTER_input_list}})
        FOREACH(LIST_FILTER_regexp_var ${LIST_FILTER_DEFAULT_ARGS})
            FOREACH(LIST_FILTER_regexp ${${LIST_FILTER_regexp_var}})
                IF(${LIST_FILTER_item} MATCHES ${LIST_FILTER_regexp})
                    LIST(APPEND ${LIST_FILTER_OUTPUT_VARIABLE} ${LIST_FILTER_item})
                ENDIF(${LIST_FILTER_item} MATCHES ${LIST_FILTER_regexp})
            ENDFOREACH(LIST_FILTER_regexp ${${LIST_FILTER_regexp_var}})
        ENDFOREACH(LIST_FILTER_regexp_var)
    ENDFOREACH(LIST_FILTER_item)
    # If OUTPUT_VARIABLE is not specified, overwrite the input list.
    IF(${LIST_FILTER_OUTPUT_VARIABLE} STREQUAL "LIST_FILTER_internal_output")
        SET(${LIST_FILTER_input_list} ${${LIST_FILTER_OUTPUT_VARIABLE}})
    ENDIF(${LIST_FILTER_OUTPUT_VARIABLE} STREQUAL "LIST_FILTER_internal_output")
ENDMACRO(LIST_FILTER)


if (XENOMAI_LIRARIES AND XENOMAI_INCLUDE_DIRS AND XENOMAI_DEFINITIONS)
    # in cache already
    set(XENOMAI_FOUND TRUE)
else (XENOMAI_LIRARIES AND XENOMAI_INCLUDE_DIRS AND XENOMAI_DEFINITIONS)
    # Xenomai comes with its own ...-config program to get cflags and ldflags
    if (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
        # if cross compiling, we want to find this program only from the sysroot
        set(CACHED ${CMAKE_FIND_ROOT_PATH_MODE_PROGRAM})
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
    endif (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
    find_program(XENOMAI_XENO_CONFIG
        NAMES
            xeno-config
        PATHS
            ${_XENOMAI_INCLUDEDIR}
            /usr/xenomai/bin
            /usr/local/bin
            /usr/bin
    )
    if (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)
        # restore the previous value
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ${CACHED})
    endif (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM)

    if (XENOMAI_XENO_CONFIG)
        set(XENOMAI_FOUND TRUE)
        execute_process(COMMAND ${XENOMAI_XENO_CONFIG} --skin=posix --cflags OUTPUT_VARIABLE XENOMAI_CFLAGS)
        string(STRIP "${XENOMAI_CFLAGS}" XENOMAI_CFLAGS)
        # use grep to separate out defines and includes
        execute_process(
                COMMAND bash -c "A= ; for a in ${XENOMAI_CFLAGS}; do echo $a | grep -q \"\\-D.*\" && A=\"$A $a\"; done; echo $A"
                OUTPUT_VARIABLE XENOMAI_DEFINITIONS)
        string(STRIP "${XENOMAI_DEFINITIONS}" XENOMAI_DEFINITIONS)

        execute_process(
            COMMAND bash -c "A= ; for a in ${XENOMAI_CFLAGS}; do echo $a | grep -q \"\\-I.*\" && A=\"$A `echo $a|sed s/-I//`;\"; done; echo $A"
            OUTPUT_VARIABLE XENOMAI_INCLUDE_DIRS)
        string(STRIP "${XENOMAI_INCLUDE_DIRS}" XENOMAI_INCLUDE_DIRS)

        execute_process(
            COMMAND ${XENOMAI_XENO_CONFIG} --skin=posix --ldflags --no-auto-init
            COMMAND sed "s/-Wl,@.*wrappers//g"
            OUTPUT_VARIABLE XENOMAI_LIBRARIES)
        string(STRIP "${XENOMAI_LIBRARIES}" XENOMAI_LIBRARIES)
    endif (XENOMAI_XENO_CONFIG)

    if (XENOMAI_FOUND)
        if (NOT XENOMAI_FIND_QUIETLY)
            execute_process(COMMAND ${XENOMAI_XENO_CONFIG} --prefix OUTPUT_VARIABLE XENOMAI_PREFIX)
            message(STATUS "Found xenomai: ${XENOMAI_PREFIX}")
            message(STATUS "XENOMAI_LIBRARIES: ${XENOMAI_LIBRARIES}")
            message(STATUS "XENOMAI_INCLUDE_DIRS: ${XENOMAI_INCLUDE_DIRS}")
            message(STATUS "XENOMAI_DEFINITIONS: ${XENOMAI_DEFINITIONS}")
        endif (NOT XENOMAI_FIND_QUIETLY)
    else (XENOMAI_FOUND)
        if (XENOMAI_FIND_REQUIRED)
            message(FATAL_ERROR "Could not find XENOMAI")
        endif (XENOMAI_FIND_REQUIRED)
    endif (XENOMAI_FOUND)
# show the XENOMAI_ variables only in the advanced view
mark_as_advanced(XENOMAI_LIRARIES XENOMAI_INCLUDE_DIRS XENOMAI_DEFINITIONS)

endif (XENOMAI_LIRARIES AND XENOMAI_INCLUDE_DIRS AND XENOMAI_DEFINITIONS)
