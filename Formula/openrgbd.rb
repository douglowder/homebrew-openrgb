class Openrgbd < Formula
  desc "OpenRGB SDK server, headless: no user interface and no Qt"
  homepage "https://openrgb.org/"
  url "https://github.com/douglowder/OpenRGB.git",
      revision: "bc6b6ba65d46a4512bcd7c68f63061c7c9f20c91"
  version "0.9.2288"
  license "GPL-2.0-only"
  head "https://github.com/douglowder/OpenRGB.git", branch: "doug/headless-library"

  # The daemon reaches USB and HID devices through the macOS IOKit backends and
  # runs as a per-user LaunchAgent.  The Linux build works but is packaged by
  # the distributions, not here.
  depends_on :macos

  # qmake only: the daemon and the core it links contain no Qt.  qtbase rather
  # than qt, which adds the QML and multimedia modules that nothing here uses.
  depends_on "qtbase" => :build

  depends_on "hidapi"
  depends_on "libusb"
  depends_on "mbedtls@3"

  def install
    # The source tree's own version numbers come from git describe.  Homebrew
    # checks out one revision with no tags, so pass them in instead.
    args = %W[
      PREFIX=#{prefix}
      COMMITS=#{version.to_s.split(".").last}
      SHORTHASH=#{stable.specs.fetch(:revision, "").slice(0, 7)}
      MBEDTLS_PREFIX=#{Formula["mbedtls@3"].opt_prefix}
    ]

    # Two separate targets rather than the OpenRGB.pro subdirs project, which
    # also builds the Qt application.  The core has to come first: the daemon
    # links it.
    system "qmake", "libopenrgb.pro", *args
    system "make"
    system "make", "install"

    system "qmake", "openrgbd.pro", *args
    system "make"
    system "make", "install"

    # qmake gives the daemon an rpath into the build tree as well as one into
    # the prefix.  The build tree is gone by the time anyone runs the binary,
    # and editing it invalidates the ad-hoc signature that arm64 requires.
    system "install_name_tool", "-delete_rpath", buildpath, bin/"openrgbd"
    system "codesign", "--force", "--sign", "-", bin/"openrgbd"
  end

  service do
    run [opt_bin/"openrgbd", "--server"]
    run_type :immediate
    working_dir Dir.home
    log_path var/"log/openrgbd.log"
    error_log_path var/"log/openrgbd.log"

    # Restart after a failure only.  A clean stop exits zero, so `brew services
    # stop` and a SIGTERM both stay stopped.
    keep_alive successful_exit: false

    # A stop request that arrives during device detection is honoured once
    # detection finishes, which can take several seconds.
    stop_timeout 30

    # Wait between restarts, so a device that fails detection every time does
    # not become a loop of USB resets.
    throttle_interval 10
  end

  test do
    assert_match "OpenRGB", shell_output("#{bin}/openrgbd --version")

    # The point of this build: the daemon links the core and no Qt.
    linkage = shell_output("otool -L #{bin}/openrgbd")
    assert_match "libopenrgb", linkage
    refute_match(/libQt/, linkage)
  end
end
