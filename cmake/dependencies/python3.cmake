#
# Copyright (C) 2022  Autodesk, Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

SET(Python3_FIND_VIRTUALENV
    FIRST
)

SET(_python3_target
    "RV_DEPS_PYTHON3"
)

SET(_opentimelineio_target
    "RV_DEPS_OPENTIMELINEIO"
)

# Initial discovery to satisfy components and basic variables
IF(RV_USE_BREW_DEPS)
  FIND_PACKAGE(
    Python3
    COMPONENTS Interpreter Development
  )
  IF(Python3_FOUND)
    MESSAGE(STATUS "Using Homebrew/System Python3: ${Python3_VERSION}")

    # Satisfy variables used in requirements.txt template etc
    SET(RV_DEPS_PYTHON_VERSION
        "${Python3_VERSION}"
        CACHE INTERNAL "" FORCE
    )
    SET(RV_DEPS_PYTHON_VERSION_SHORT
        "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}"
        CACHE INTERNAL "" FORCE
    )
    SET(RV_DEPS_PYTHON3_EXECUTABLE
        "${Python3_EXECUTABLE}"
        CACHE INTERNAL "" FORCE
    )

    # Satisfy targets that depend on Python::Python
    IF(NOT TARGET Python::Python)
      ADD_LIBRARY(Python::Python INTERFACE IMPORTED GLOBAL)
      TARGET_LINK_LIBRARIES(
        Python::Python
        INTERFACE Python3::Python
      )
    ENDIF()

    # Check for PySide if possible
    IF(RV_VFX_PLATFORM STREQUAL "CY2023")
      SET(_pyside_pkg
          "PySide2"
      )
    ELSE()
      SET(_pyside_pkg
          "PySide6"
      )
    ENDIF()

    EXECUTE_PROCESS(
      COMMAND "${Python3_EXECUTABLE}" -c "import ${_pyside_pkg}; print(${_pyside_pkg}.__version__)"
      RESULT_VARIABLE _pyside_check_res
      OUTPUT_VARIABLE _pyside_ver
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    IF(_pyside_check_res EQUAL 0)
      MESSAGE(STATUS "Using Homebrew/System ${_pyside_pkg}: ${_pyside_ver}")
      SET(RV_DEPS_PYSIDE_VERSION
          "${_pyside_ver}"
          CACHE INTERNAL "" FORCE
      )
    ELSE()
      IF(NOT RV_DEPS_PYSIDE_VERSION)
        MESSAGE(WARNING "Homebrew/System ${_pyside_pkg} not found in ${Python3_EXECUTABLE}")
      ELSE()
        MESSAGE(STATUS "Homebrew/System ${_pyside_pkg} not found in ${Python3_EXECUTABLE}, using default: ${RV_DEPS_PYSIDE_VERSION}")
      ENDIF()
    ENDIF()

    # Skip everything else in this file for build but continue for requirements
    LIST(APPEND RV_DEPS_LIST Python::Python)
  ENDIF()
ELSE()
  FIND_PACKAGE(
    Python3
    COMPONENTS Interpreter
    REQUIRED
  )
ENDIF()

SET(_pyside_target
    "${RV_DEPS_PYSIDE_TARGET}"
)

SET(_python3_version
    "${RV_DEPS_PYTHON_VERSION}"
)
STRING(REPLACE "." ";" _python_version_list "${_python3_version}")

LIST(GET _python_version_list 0 PYTHON_VERSION_MAJOR)
LIST(GET _python_version_list 1 PYTHON_VERSION_MINOR)
LIST(GET _python_version_list 2 PYTHON_VERSION_PATCH)

SET(RV_DEPS_PYTHON_VERSION_SHORT
    "${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}"
)

# This version is used for generating src/build/requirements.txt from requirements.txt.in template
SET(_opentimelineio_version
    "${RV_DEPS_OTIO_VERSION}"
)

SET(_pyside_version
    "${RV_DEPS_PYSIDE_VERSION}"
)

# logic to handle the optional version
IF(RV_DEPS_NUMPY_VERSION
   AND NOT "${RV_DEPS_NUMPY_VERSION}" STREQUAL ""
)
  # If version exists, result is "==1.26.4"
  SET(_numpy_version
      "==${RV_DEPS_NUMPY_VERSION}"
  )
ELSE()
  # If version is empty, result is "", so the file just says "numpy"
  SET(_numpy_version
      ""
  )
ENDIF()

SET(_python3_download_url
    "https://github.com/python/cpython/archive/refs/tags/v${_python3_version}.zip"
)

SET(_python3_download_hash
    "${RV_DEPS_PYTHON_DOWNLOAD_HASH}"
)

SET(_opentimelineio_download_url
    "https://github.com/AcademySoftwareFoundation/OpenTimelineIO"
)

SET(_opentimelineio_git_tag
    "v${_opentimelineio_version}"
)

SET(_pyside_archive_url
    "${RV_DEPS_PYSIDE_ARCHIVE_URL}"
)

SET(_pyside_download_hash
    "${RV_DEPS_PYSIDE_DOWNLOAD_HASH}"
)

SET(_install_dir
    ${RV_DEPS_BASE_DIR}/${_python3_target}/install
)
SET(_source_dir
    ${RV_DEPS_BASE_DIR}/${_python3_target}/src
)
SET(_build_dir
    ${RV_DEPS_BASE_DIR}/${_python3_target}/build
)

IF(RV_USE_BREW_DEPS)
  # When using Brew, we still want an "install" directory to stage requirements into
  SET(_install_dir
      ${RV_DEPS_BASE_DIR}/${_python3_target}-brew/install
  )
  FILE(MAKE_DIRECTORY ${_install_dir})

  # Map variables to Homebrew versions
  SET(_python3_executable
      ${Python3_EXECUTABLE}
  )
  SET(_include_dir
      ${Python3_INCLUDE_DIRS}
  )
  # Pick the first library if multiple
  LIST(GET Python3_LIBRARIES 0 _python3_cmake_library)
  SET(_python3_lib
      ${_python3_cmake_library}
  )
  SET(_python3_lib_name
      "brew-python"
  ) # dummy name for stage
ELSE()
  # Standard RV built Python mapping
  IF(RV_TARGET_WINDOWS)
    IF(CMAKE_BUILD_TYPE MATCHES "^Debug$")
      SET(PYTHON3_EXTRA_WIN_LIBRARY_SUFFIX_IF_DEBUG
          "_d"
      )
    ELSE()
      SET(PYTHON3_EXTRA_WIN_LIBRARY_SUFFIX_IF_DEBUG
          ""
      )
    ENDIF()
    SET(_python_name
        python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}${PYTHON3_EXTRA_WIN_LIBRARY_SUFFIX_IF_DEBUG}
    )
    SET(_include_dir
        ${_install_dir}/include
    )
    SET(_bin_dir
        ${_install_dir}/bin
    )
    SET(_lib_dir
        ${_install_dir}/libs
    )
    SET(_python3_lib_name
        ${_python_name}${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
    SET(_python3_lib
        ${_bin_dir}/${_python3_lib_name}
    )
    SET(_python3_implib
        ${_lib_dir}/${_python_name}${CMAKE_IMPORT_LIBRARY_SUFFIX}
    )
    SET(_python3_executable
        ${_bin_dir}/python${PYTHON3_EXTRA_WIN_LIBRARY_SUFFIX_IF_DEBUG}.exe
    )

    # When building in Debug, we need the Release name also: see below for add_custom_command.
    SET(_python_release_libname
        python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    SET(_python_release_libpath
        ${_lib_dir}/${_python_release_libname}
    )

    SET(_python_release_in_bin_libpath
        ${_bin_dir}/${_python_release_libname}
    )
  ELSE() # Not WINDOWS
    SET(_python_name
        python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}
    )
    SET(_include_dir
        ${_install_dir}/include/${_python_name}
    )
    SET(_lib_dir
        ${_install_dir}/lib
    )
    SET(_python3_lib_name
        ${CMAKE_SHARED_LIBRARY_PREFIX}${_python_name}${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
    SET(_python3_lib
        ${_lib_dir}/${_python3_lib_name}
    )
    SET(_python3_executable
        ${_install_dir}/bin/python3
    )
  ENDIF()

  # Set the appropriate library for CMAKE_ARGS based on platform Windows needs the import library (.lib), Unix needs the shared library (.so/.dylib)
  IF(RV_TARGET_WINDOWS)
    SET(_python3_cmake_library
        ${_python3_implib}
    )
  ELSE()
    SET(_python3_cmake_library
        ${_python3_lib}
    )
  ENDIF()
ENDIF()

# Generate requirements.txt from template with the OpenTimelineIO and NumPy versions substituted
SET(_requirements_input_file
    "${PROJECT_SOURCE_DIR}/src/build/requirements.txt.in"
)
SET(_requirements_output_file
    "${CMAKE_BINARY_DIR}/requirements.txt"
)

CONFIGURE_FILE(${_requirements_input_file} ${_requirements_output_file} @ONLY)

# Set OTIO_CXX_DEBUG_BUILD for all Debug builds
IF(CMAKE_BUILD_TYPE MATCHES "^Debug$")
  SET(_otio_debug_env
      "OTIO_CXX_DEBUG_BUILD=1"
  )
ELSE()
  SET(_otio_debug_env
      ""
  )
ENDIF()

# Build dependencies
SET(RV_PYTHON_BUILD_DEPS
    "pip" "setuptools" "wheel" "Cython" "meson-python" "ninja"
    CACHE STRING "Build dependencies to install first (from wheels)"
)

SET(RV_PYTHON_WHEEL_SAFE
    ${RV_PYTHON_BUILD_DEPS} "PyOpenGL" "certifi" "six" "packaging" "requests"
    CACHE STRING "Packages safe to install from wheels (pure Python or build tools)"
)

STRING(REPLACE ";" "," _wheel_safe_packages "${RV_PYTHON_WHEEL_SAFE}")

IF(RV_TARGET_DARWIN
   AND CMAKE_OSX_SYSROOT
)
  SET(_sdkroot_env
      "SDKROOT=${CMAKE_OSX_SYSROOT}"
  )
ENDIF()

# Requirements Install Commands
SET(_build_deps_install_command
    ${CMAKE_COMMAND} -E env ${_sdkroot_env} "${_python3_executable}" -s -E -I -m pip install --upgrade --no-cache-dir ${RV_PYTHON_BUILD_DEPS}
)

SET(_requirements_install_command
    ${CMAKE_COMMAND} -E env ${_otio_debug_env} ${_sdkroot_env}
)

IF(DEFINED RV_DEPS_OPENSSL_INSTALL_DIR)
  LIST(APPEND _requirements_install_command "OPENSSL_DIR=${RV_DEPS_OPENSSL_INSTALL_DIR}")
ENDIF()

LIST(
  APPEND
  _requirements_install_command
  "CMAKE_ARGS=-DPYTHON_LIBRARY=${_python3_cmake_library} -DPYTHON_INCLUDE_DIR=${_include_dir} -DPYTHON_EXECUTABLE=${_python3_executable}"
  "${_python3_executable}"
  -s
  -E
  -I
  -m
  pip
  install
  --upgrade
  --no-cache-dir
  --force-reinstall
  --no-binary
  :all:
  --only-binary
  ${_wheel_safe_packages}
  ${RV_PYTHON_WHEEL_SAFE}
  -r
  "${_requirements_output_file}"
)

# Branch for Building Python or using Brew
IF(NOT RV_USE_BREW_DEPS)
  FETCHCONTENT_DECLARE(
    ${_pyside_target}
    URL ${_pyside_archive_url}
    URL_HASH MD5=${_pyside_download_hash}
    SOURCE_SUBDIR "sources"
  )
  FETCHCONTENT_MAKEAVAILABLE(${_pyside_target})

  SET(_python3_make_command_script
      "${PROJECT_SOURCE_DIR}/src/build/make_python.py"
  )
  SET(_python3_make_command
      ${Python3_EXECUTABLE} "${_python3_make_command_script}"
  )
  LIST(
    APPEND
    _python3_make_command
    "--variant"
    ${CMAKE_BUILD_TYPE}
    "--source-dir"
    ${_source_dir}
    "--output-dir"
    ${_install_dir}
    "--temp-dir"
    ${_build_dir}
    "--vfx_platform"
    ${RV_VFX_CY_YEAR}
  )

  IF(DEFINED RV_DEPS_OPENSSL_INSTALL_DIR)
    LIST(APPEND _python3_make_command "--openssl-dir" ${RV_DEPS_OPENSSL_INSTALL_DIR})
  ENDIF()
  IF(RV_TARGET_WINDOWS)
    LIST(APPEND _python3_make_command "--python-version" "${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}")
  ENDIF()

  # PySide make commands (CY2023 vs CY2024+)
  IF(RV_VFX_PLATFORM STREQUAL CY2023)
    SET(_pyside_make_command_script
        "${PROJECT_SOURCE_DIR}/src/build/make_pyside.py"
    )
    SET(_pyside_source_dir
        ${rv_deps_pyside2_SOURCE_DIR}
    )
  ELSE()
    SET(_pyside_make_command_script
        "${PROJECT_SOURCE_DIR}/src/build/make_pyside6.py"
    )
    SET(_pyside_source_dir
        ${rv_deps_pyside6_SOURCE_DIR}
    )
  ENDIF()

  SET(_pyside_make_command
      ${Python3_EXECUTABLE} "${_pyside_make_command_script}"
  )
  LIST(
    APPEND
    _pyside_make_command
    "--variant"
    ${CMAKE_BUILD_TYPE}
    "--source-dir"
    ${_pyside_source_dir}
    "--output-dir"
    ${_install_dir}
    "--temp-dir"
    ${_build_dir}
    "--python-dir"
    ${_install_dir}
    "--qt-dir"
    ${RV_DEPS_QT_LOCATION}
    "--python-version"
    "${RV_DEPS_PYTHON_VERSION_SHORT}"
  )
  IF(DEFINED RV_DEPS_OPENSSL_INSTALL_DIR)
    LIST(APPEND _pyside_make_command "--openssl-dir" ${RV_DEPS_OPENSSL_INSTALL_DIR})
  ENDIF()

  EXTERNALPROJECT_ADD(
    ${_python3_target}
    DOWNLOAD_NAME ${_python3_target}_${_python3_version}.zip
    DOWNLOAD_DIR ${RV_DEPS_DOWNLOAD_DIR}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    SOURCE_DIR ${_source_dir}
    INSTALL_DIR ${_install_dir}
    URL ${_python3_download_url}
    URL_MD5 ${_python3_download_hash}
    DEPENDS OpenSSL::Crypto OpenSSL::SSL
    CONFIGURE_COMMAND ${_python3_make_command} --configure
    BUILD_COMMAND ${_python3_make_command} --build
    INSTALL_COMMAND ${_python3_make_command} --install
    BUILD_BYPRODUCTS ${_python3_executable} ${_python3_lib} ${_python3_implib}
    BUILD_IN_SOURCE TRUE
    BUILD_ALWAYS FALSE
    USES_TERMINAL_BUILD TRUE
  )

  # Requirements and Flags
  SET(${_python3_target}-build-deps-flag
      ${_install_dir}/${_python3_target}-build-deps-flag
  )
  ADD_CUSTOM_COMMAND(
    OUTPUT ${${_python3_target}-build-deps-flag}
    COMMAND ${_build_deps_install_command}
    COMMAND cmake -E touch ${${_python3_target}-build-deps-flag}
    DEPENDS ${_python3_target}
  )

  SET(${_python3_target}-requirements-flag
      ${_install_dir}/${_python3_target}-requirements-flag
  )
  ADD_CUSTOM_COMMAND(
    OUTPUT ${${_python3_target}-requirements-flag}
    COMMAND ${_requirements_install_command}
    COMMAND cmake -E touch ${${_python3_target}-requirements-flag}
    DEPENDS ${_python3_target} ${${_python3_target}-build-deps-flag} ${_requirements_output_file}
  )

  # Testing
  SET(${_python3_target}-test-flag
      ${_install_dir}/${_python3_target}-test-flag
  )
  SET(_test_python_script
      "${PROJECT_SOURCE_DIR}/src/build/test_python.py"
  )
  ADD_CUSTOM_COMMAND(
    OUTPUT ${${_python3_target}-test-flag}
    COMMAND ${Python3_EXECUTABLE} "${_test_python_script}" --python-home "${_install_dir}" --variant "${CMAKE_BUILD_TYPE}"
    COMMAND cmake -E touch ${${_python3_target}-test-flag}
    DEPENDS ${${_python3_target}-requirements-flag}
  )

  # PySide build
  SET(${_pyside_target}-build-flag
      ${_install_dir}/${_pyside_target}-build-flag
  )
  IF(RV_VFX_PLATFORM STREQUAL CY2023
     AND RV_TARGET_WINDOWS
  )
    SET(_pyside_patch_command
        COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/src/build/patch_PySide2/windows_desktop.py
        ${rv_deps_pyside2_SOURCE_DIR}/build_scripts/platforms/windows_desktop.py
    )
  ENDIF()
  ADD_CUSTOM_COMMAND(
    OUTPUT ${${_pyside_target}-build-flag} ${_pyside_patch_command}
    COMMAND ${_pyside_make_command} --prepare --build
    COMMAND cmake -E touch ${${_pyside_target}-build-flag}
    DEPENDS ${_python3_target} ${${_python3_target}-requirements-flag} ${${_python3_target}-test-flag}
    USES_TERMINAL
  )

  # Stage commands for non-brew
  IF(RV_TARGET_WINDOWS)
    SET(_copy_commands
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${_install_dir}/lib ${RV_STAGE_LIB_DIR} COMMAND ${CMAKE_COMMAND} -E copy_directory ${_install_dir}/include
        ${RV_STAGE_INCLUDE_DIR} COMMAND ${CMAKE_COMMAND} -E copy_directory ${_install_dir}/bin ${RV_STAGE_BIN_DIR}
    )
    IF(RV_VFX_PLATFORM STRGREATER_EQUAL CY2024)
      LIST(
        APPEND
        _copy_commands
        COMMAND
        ${CMAKE_COMMAND}
        -E
        copy_directory
        ${_install_dir}/DLLs
        ${RV_STAGE_ROOT_DIR}/DLLs
      )
    ENDIF()
    ADD_CUSTOM_COMMAND(
      OUTPUT ${RV_STAGE_BIN_DIR}/${_python3_lib_name} ${_copy_commands}
      DEPENDS ${_python3_target} ${${_python3_target}-requirements-flag} ${${_python3_target}-test-flag} ${${_pyside_target}-build-flag}
    )
    ADD_CUSTOM_TARGET(
      ${_python3_target}-stage-target ALL
      DEPENDS ${RV_STAGE_BIN_DIR}/${_python3_lib_name}
    )
  ELSE()
    ADD_CUSTOM_COMMAND(
      OUTPUT ${RV_STAGE_LIB_DIR}/${_python3_lib_name}
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${_install_dir}/lib ${RV_STAGE_LIB_DIR}
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${_install_dir}/include ${RV_STAGE_INCLUDE_DIR}
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${_install_dir}/bin ${RV_STAGE_BIN_DIR}
      DEPENDS ${_python3_target} ${${_python3_target}-requirements-flag} ${${_python3_target}-test-flag} ${${_pyside_target}-build-flag}
    )
    ADD_CUSTOM_TARGET(
      ${_python3_target}-stage-target ALL
      DEPENDS ${RV_STAGE_LIB_DIR}/${_python3_lib_name}
    )
  ENDIF()

ELSE() # RV_USE_BREW_DEPS is ON
  # When using Brew, we still want to install requirements if they are missing Note: Installing into Brew Python might require --user or be done in a venv, but
  # RV staging copies files. For now, let's try to install them and touch the flags.

  SET(${_python3_target}-requirements-flag
      "${CMAKE_BINARY_DIR}/python3-brew-requirements-flag"
  )

  # Check if requirements are already satisfied to avoid unnecessary sudo/permission issues but for RV packaging we might still want them local.
  ADD_CUSTOM_COMMAND(
    OUTPUT "${${_python3_target}-requirements-flag}"
    COMMAND ${_build_deps_install_command}
    COMMAND ${_requirements_install_command}
    COMMAND ${CMAKE_COMMAND} -E touch "${${_python3_target}-requirements-flag}"
    COMMENT "Installing Python requirements for Homebrew build"
  )

  SET(${_pyside_target}-build-flag
      "${CMAKE_BINARY_DIR}/pyside-brew-build-flag"
  )
  ADD_CUSTOM_COMMAND(
    OUTPUT "${${_pyside_target}-build-flag}"
    COMMAND ${CMAKE_COMMAND} -E touch "${${_pyside_target}-build-flag}"
  )

  IF(NOT TARGET ${_python3_target}-stage-target)
    ADD_CUSTOM_TARGET(
      ${_python3_target}-stage-target ALL
      DEPENDS "${${_python3_target}-requirements-flag}" "${${_pyside_target}-build-flag}"
    )
    ADD_DEPENDENCIES(dependencies ${_python3_target}-stage-target)
  ENDIF()
ENDIF()

# Final target properties (Common)
IF(NOT TARGET Python::Python)
  ADD_LIBRARY(Python::Python SHARED IMPORTED GLOBAL)
  SET_TARGET_PROPERTIES(
    Python::Python
    PROPERTIES SYSTEM FALSE
  )
  IF(NOT RV_USE_BREW_DEPS)
    ADD_DEPENDENCIES(Python::Python ${_python3_target})
  ENDIF()
  SET_PROPERTY(
    TARGET Python::Python
    PROPERTY IMPORTED_LOCATION ${_python3_lib}
  )
  SET_PROPERTY(
    TARGET Python::Python
    PROPERTY IMPORTED_SONAME ${_python3_lib_name}
  )
  IF(RV_TARGET_WINDOWS
     AND NOT RV_USE_BREW_DEPS
  )
    SET_PROPERTY(
      TARGET Python::Python
      PROPERTY IMPORTED_IMPLIB ${_python3_implib}
    )
  ENDIF()
  FILE(MAKE_DIRECTORY ${_include_dir})
  TARGET_INCLUDE_DIRECTORIES(
    Python::Python
    INTERFACE ${_include_dir}
  )
ENDIF()

IF(NOT RV_USE_BREW_DEPS)
  ADD_DEPENDENCIES(dependencies ${_python3_target}-stage-target)
ENDIF()

SET(RV_DEPS_PYTHON3_VERSION
    ${_python3_version}
    CACHE INTERNAL "" FORCE
)
SET(RV_DEPS_PYSIDE_VERSION
    ${_pyside_version}
    CACHE INTERNAL "" FORCE
)
SET(RV_DEPS_PYTHON3_EXECUTABLE
    ${_python3_executable}
    CACHE INTERNAL "" FORCE
)
