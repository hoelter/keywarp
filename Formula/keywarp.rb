class Keywarp < Formula
  desc "Summon macOS apps with global keyboard shortcuts"
  homepage "https://github.com/hoelter/keywarp"
  # url and sha256 are rewritten by scripts/release.sh.
  url "https://github.com/hoelter/keywarp/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "9aa5bdabf5c907e4d96045fe2f3ffc828c9846a8e64a159d42bf3e6bb594602f"
  license "MIT"
  head "https://github.com/hoelter/keywarp.git", branch: "main"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  def install
    # HEAD builds have no release number, and the bundle version must be X.Y.Z.
    bundle_version = build.head? ? "0.0.0" : version.to_s
    system "make", "bundle", "VERSION=#{bundle_version}", "SWIFT_BUILD_FLAGS=--disable-sandbox"
    prefix.install "build/Keywarp.app"
    bin.install_symlink prefix/"Keywarp.app/Contents/MacOS/keywarp"
  end

  service do
    run opt_prefix/"Keywarp.app/Contents/MacOS/keywarp"
    keep_alive true
    process_type :interactive
  end

  test do
    assert_match(/^\d+\.\d+\.\d+$/, shell_output("#{bin}/keywarp --version"))
  end
end
