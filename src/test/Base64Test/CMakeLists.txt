INCLUDE(cxx_defaults)

SET(_target
    "Base64Test"
)

LIST(APPEND _sources main.cpp)

ADD_EXECUTABLE(
  ${_target}
  ${_sources}
)

TARGET_LINK_LIBRARIES(${_target} TwkUtil doctest::doctest)

IF(RV_TARGET_LINUX)
  TARGET_LINK_LIBRARIES(${_target} pthread dl)
ENDIF()

# Simply assert that the test executable actually works.
ADD_TEST(
  NAME "${_target}"
  COMMAND ${CMAKE_COMMAND} -E env LD_LIBRARY_PATH=${RV_STAGE_LIB_DIR}:${RV_STAGE_LIB_DIR}/OpenSSL DYLD_LIBRARY_PATH=${RV_STAGE_LIB_DIR}:${RV_STAGE_LIB_DIR}/OpenSSL "$<TARGET_FILE:${_target}>"
)

RV_STAGE(TYPE "EXECUTABLE" TARGET ${_target})
