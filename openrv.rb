class Openrv < Formula
  desc "Open source version of RV, a professional media player"
  homepage "https://github.com/AcademySoftwareFoundation/OpenRV"
  url "https://github.com/AcademySoftwareFoundation/OpenRV/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "e2504aec110d7428afe1a971e76da1c4cecbb34dd418236c164ad3a2bd5a67fe"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.11"
  depends_on "qt@6"

  def install
    # Set up python environment for build requirements
    # We use python@3.11 as specified in the project's build system
    venv_dir = buildpath/".venv"
    system "python3.11", "-m", "venv", venv_dir
    ENV.prepend_path "PATH", venv_dir/"bin"
    system "pip", "install", "--upgrade", "pip"
    system "pip", "install", "-r", "requirements.txt"

    # FFmpeg non-free decoders and encoders requested by the user
    ffmpeg_decoders = [
      "aac", "aac_fixed", "aac_latm", "ac3", "bink", "binkaudio_dct", "binkaudio_rdft",
      "dnxhd", "dvvideo", "hevc", "mpeg2video", "prores", "prores_aw", "prores_ks",
      "prores_lgpl", "qtrle", "svq1", "svq3", "vp9", "vp9_cuvid", "vp9_mediacodec",
      "vp9_qsv", "vp9_rkmpp", "vp9_v4l2m2m"
    ].join(";")

    ffmpeg_encoders = [
      "aac", "aac_mf", "ac3", "dnxhd", "dvvideo", "hevc", "mpeg2video", "prores",
      "qtrle", "svq1", "svq3", "vp9_qsv", "vp9_vaapi"
    ].join(";")

    args = %W[
      -G Ninja
      -DCMAKE_BUILD_TYPE=Release
      -DRV_VFX_PLATFORM=CY2025
      -DRV_FFMPEG=8
      -DRV_FFMPEG_NON_FREE_DECODERS_TO_ENABLE=#{ffmpeg_decoders}
      -DRV_FFMPEG_NON_FREE_ENCODERS_TO_ENABLE=#{ffmpeg_encoders}
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DRV_DEPS_QT_LOCATION=#{Formula["qt@6"].opt_prefix}
      -DPython_EXECUTABLE=#{venv_dir}/bin/python
    ]

    # Handle optional DeckLink SDK if provided via environment variable
    decklink_path = ENV["RV_DEPS_BMD_DECKLINK_SDK_ZIP_PATH"] || "/Users/moliver/Downloads/Blackmagic_DeckLink_SDK_15.3.zip"
    if File.exist?(decklink_path)
      args << "-DRV_DEPS_BMD_DECKLINK_SDK_ZIP_PATH=#{decklink_path}"
    else
      opoo "DeckLink SDK zip not found at #{decklink_path}. Blackmagic support will be disabled."
    end

    system "cmake", "-B", "build", *args
    system "cmake", "--build", "build", "--target", "main_executable"
    system "cmake", "--install", "build"

    # Create a wrapper script in bin for easier access
    (bin/"rv").write <<~EOS
      #!/bin/bash
      exec "#{prefix}/RV.app/Contents/MacOS/RV" "$@"
    EOS
    chmod 0555, bin/"rv"
  end

  def caveats
    <<~EOS
      OpenRV.app has been installed to:
        #{prefix}/RV.app

      To make it available in your Applications folder, run:
        ln -s #{prefix}/RV.app /Applications/OpenRV.app

      You can also run it from the command line using the 'rv' command.

      If you want to build with Blackmagic DeckLink SDK support, set the environment variable:
        export RV_DEPS_BMD_DECKLINK_SDK_ZIP_PATH=/path/to/Blackmagic_DeckLink_SDK_15.3.zip
      before running 'brew install'.
    EOS
  end

  test do
    # Verify the app starts and reports version
    assert_match "RV version", shell_output("#{bin}/rv --version")
  end
end
