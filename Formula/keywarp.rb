class Keywarp < Formula
  desc "Summon macOS apps with global keyboard shortcuts"
  homepage "https://github.com/hoelter/keywarp"
  # url and sha256 are rewritten by scripts/release.sh.
  url "https://github.com/hoelter/keywarp/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "03ed180fbe9d4b483b7e5650055e9c9a2d230d290d7c13e36c031c5b92fe6354"
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
