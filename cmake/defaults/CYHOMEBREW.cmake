# CYHOMEBREW platform for building with Homebrew-managed dependencies

IF(RV_VFX_PLATFORM STREQUAL "CYHOMEBREW")
  SET(RV_VFX_CY_YEAR
      "2026"
  ) # Default to recent platform standards
  SET(RV_VFX_CYHOMEBREW
      ON
  )
  ADD_COMPILE_DEFINITIONS(RV_VFX_CYHOMEBREW)
  ADD_COMPILE_DEFINITIONS(QT65ON)

  # Default to using Brew for dependencies
  SET(RV_USE_BREW_DEPS
      ON
      CACHE BOOL "Use Homebrew dependencies" FORCE
  )

  # PySide
  SET(RV_DEPS_PYSIDE_VERSION
      "6.5.3"
  )
  SET(RV_DEPS_PYSIDE_DOWNLOAD_HASH
      "515d3249c6e743219ff0d7dd25b8c8d8"
  )
  SET(RV_DEPS_PYSIDE_TARGET
      "RV_DEPS_PYSIDE6"
  )
  SET(RV_DEPS_PYSIDE_ARCHIVE_URL
      "https://mirrors.ocf.berkeley.edu/qt/official_releases/QtForPython/pyside6/PySide6-${RV_DEPS_PYSIDE_VERSION}-src/pyside-setup-everywhere-src-${RV_DEPS_PYSIDE_VERSION}.zip"
  )

  # Qt default for CYHOMEBREW - Pin to 6.5.3 to avoid breaking changes in newer versions (like 6.10+)
  SET(RV_DEPS_QT_MAJOR
      "6"
  )
  SET(RV_DEPS_QT_VERSION
      "6.5.3"
  )

  # Add Homebrew to CMAKE_PREFIX_PATH automatically if on macOS
  IF(APPLE)
    # Detect Homebrew prefix
    EXECUTE_PROCESS(
      COMMAND brew --prefix
      OUTPUT_VARIABLE _brew_prefix
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    IF(_brew_prefix)
      # Standard Homebrew paths for dependencies other than Qt
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/openssl@3")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/imath")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/openexr")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/opencolorio")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/openimageio")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/libtiff")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/libpng")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/jpeg-turbo")
      LIST(APPEND CMAKE_PREFIX_PATH "${_brew_prefix}/opt/webp")
    ENDIF()
  ENDIF()

  # Note: RV_DEPS_QT_LOCATION MUST be set to a valid Qt 6.5.3 installation.
  IF(RV_DEPS_QT_LOCATION)
    LIST(APPEND CMAKE_PREFIX_PATH "${RV_DEPS_QT_LOCATION}")
  ENDIF()
ENDIF()
