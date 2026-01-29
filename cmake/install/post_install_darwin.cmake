#
# Copyright (C) 2022  Autodesk, Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

MESSAGE(STATUS "Performing post-install cleanup for Darwin to reduce bundle size...")

# Define the path to the installed Python directory
# CMAKE_INSTALL_PREFIX is expected to be the .app bundle root (e.g., .../RV.app)
SET(RV_APP_PYTHON_DIR "${CMAKE_INSTALL_PREFIX}/Contents/lib/python3.11")

# Lists of directories/files to remove to save space
SET(ITEMS_TO_REMOVE
    "${RV_APP_PYTHON_DIR}/test"
    "${RV_APP_PYTHON_DIR}/unittest"
    "${RV_APP_PYTHON_DIR}/config-3.11-darwin"
    "${RV_APP_PYTHON_DIR}/idlelib"
    "${RV_APP_PYTHON_DIR}/turtledemo"
    "${RV_APP_PYTHON_DIR}/ensurepip"
    "${RV_APP_PYTHON_DIR}/lib2to3"
    "${RV_APP_PYTHON_DIR}/pydoc_data"
    "${RV_APP_PYTHON_DIR}/tkinter"
    "${RV_APP_PYTHON_DIR}/turtle.py"
    "${RV_APP_PYTHON_DIR}/site-packages/pip"
    "${RV_APP_PYTHON_DIR}/site-packages/setuptools"
    "${RV_APP_PYTHON_DIR}/site-packages/wheel"
    "${RV_APP_PYTHON_DIR}/site-packages/Cython"
    "${RV_APP_PYTHON_DIR}/site-packages/mesonbuild"
    "${RV_APP_PYTHON_DIR}/site-packages/ninja"
    "${CMAKE_INSTALL_PREFIX}/Contents/include"
    "${CMAKE_INSTALL_PREFIX}/Contents/lib/pkgconfig"
)

FOREACH(ITEM ${ITEMS_TO_REMOVE})
  IF(EXISTS "${ITEM}")
    MESSAGE(STATUS "Removing unnecessary item: ${ITEM}")
    FILE(REMOVE_RECURSE "${ITEM}")
  ENDIF()
ENDFOREACH()

# Remove __pycache__ directories recursively
MESSAGE(STATUS "Removing __pycache__ directories...")
# Note: GLOB_RECURSE with LIST_DIRECTORIES true might be slow on large trees, but necessary here.
FILE(GLOB_RECURSE ALL_ITEMS LIST_DIRECTORIES true "${RV_APP_PYTHON_DIR}/*")
FOREACH(ITEM ${ALL_ITEMS})
  IF(IS_DIRECTORY "${ITEM}" AND "${ITEM}" MATCHES "/__pycache__$")
     # MESSAGE(STATUS "Removing: ${ITEM}") # Commented out to avoid log spam
     FILE(REMOVE_RECURSE "${ITEM}")
  ENDIF()
ENDFOREACH()

# Remove .a static libraries
MESSAGE(STATUS "Removing static libraries (.a)...")
FILE(GLOB_RECURSE STATIC_LIBS "${CMAKE_INSTALL_PREFIX}/Contents/lib/*.a")
FOREACH(FILE ${STATIC_LIBS})
  MESSAGE(STATUS "Removing static lib: ${FILE}")
  FILE(REMOVE "${FILE}")
ENDFOREACH()

# Advanced PySide6 cleanup
MESSAGE(STATUS "Performing advanced PySide6 cleanup...")

SET(PYSIDE6_DIR "${RV_APP_PYTHON_DIR}/site-packages/PySide6")
# Check for Frameworks and Plugins in the installation prefix
SET(QT_FRAMEWORKS_DIR "${CMAKE_INSTALL_PREFIX}/Contents/Frameworks")
SET(QT_PLUGINS_DIR "${CMAKE_INSTALL_PREFIX}/Contents/PlugIns/Qt")

IF(EXISTS "${PYSIDE6_DIR}")
  MESSAGE(STATUS "PySide6 directory found at ${PYSIDE6_DIR}")
  
  # Remove PySide6 tools and support files
  SET(PYSIDE6_ITEMS_TO_REMOVE
      "${PYSIDE6_DIR}/Assistant.app"
      "${PYSIDE6_DIR}/Designer.app"
      "${PYSIDE6_DIR}/Linguist.app"
      "${PYSIDE6_DIR}/lrelease"
      "${PYSIDE6_DIR}/lupdate"
      "${PYSIDE6_DIR}/qmllint"
      "${PYSIDE6_DIR}/qmlformat"
      "${PYSIDE6_DIR}/qmlls"
      "${PYSIDE6_DIR}/include"
      "${PYSIDE6_DIR}/scripts"
      "${PYSIDE6_DIR}/support"
      "${PYSIDE6_DIR}/typesystems"
      "${PYSIDE6_DIR}/Qt/translations"
      "${PYSIDE6_DIR}/examples"
  )

  FOREACH(ITEM ${PYSIDE6_ITEMS_TO_REMOVE})
      IF(EXISTS "${ITEM}")
          MESSAGE(STATUS "Removing PySide6 item: ${ITEM}")
          FILE(REMOVE_RECURSE "${ITEM}")
      ENDIF()
  ENDFOREACH()

  # Replace Qt lib with symlink to Frameworks
  IF(EXISTS "${QT_FRAMEWORKS_DIR}" AND EXISTS "${PYSIDE6_DIR}/Qt/lib")
      MESSAGE(STATUS "Replacing PySide6/Qt/lib with symlink to Contents/Frameworks")
      FILE(REMOVE_RECURSE "${PYSIDE6_DIR}/Qt/lib")
      # Use execute_process for ln -s to ensure correct relative link
      # Link target is relative to PYSIDE6_DIR/Qt
      EXECUTE_PROCESS(COMMAND ln -s "../../../../../Frameworks" "lib" WORKING_DIRECTORY "${PYSIDE6_DIR}/Qt")
  ENDIF()

  # Replace Qt plugins with symlink to PlugIns/Qt
  IF(EXISTS "${QT_PLUGINS_DIR}" AND EXISTS "${PYSIDE6_DIR}/Qt/plugins")
      MESSAGE(STATUS "Replacing PySide6/Qt/plugins with symlink to Contents/PlugIns/Qt")
      FILE(REMOVE_RECURSE "${PYSIDE6_DIR}/Qt/plugins")
      # Link target is relative to PYSIDE6_DIR/Qt
      EXECUTE_PROCESS(COMMAND ln -s "../../../../../PlugIns/Qt" "plugins" WORKING_DIRECTORY "${PYSIDE6_DIR}/Qt")
  ENDIF()
  
ENDIF()

MESSAGE(STATUS "Post-install cleanup complete.")
