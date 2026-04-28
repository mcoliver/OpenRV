#
# Copyright (C) 2022  Autodesk, Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

ADD_SUBDIRECTORY(FastMemcpyTest)
ADD_SUBDIRECTORY(Base64Test)
ADD_SUBDIRECTORY(TwkMathTest)
ADD_SUBDIRECTORY(TwkRegExTest)
ADD_SUBDIRECTORY(TwkImgTest)
ADD_SUBDIRECTORY(TiffProbe)
ADD_SUBDIRECTORY(ExrProbe)
ADD_SUBDIRECTORY(PngProbe)
ADD_SUBDIRECTORY(OcioProbe)
ADD_SUBDIRECTORY(QFontTest)
IF(RV_TARGET_LINUX)
  # These are simple tests replicating part of what the AudioRender is doing on Linux, uses `dlopen`
  ADD_SUBDIRECTORY(LoadingSharedLibrariesTest)
  # Won't run (yet) on macOS
  ADD_SUBDIRECTORY(IPCore)
ENDIF()
