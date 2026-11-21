class Keywarp < Formula
  desc "Summon macOS apps with global keyboard shortcuts"
  homepage "https://github.com/hoelter/keywarp"
  # url and sha256 are rewritten by scripts/release.sh.
  url "https://github.com/hoelter/keywarp/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"
  head "https://github.com/hoelter/keywarp.git", branch: "main"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  def install
    system "make", "bundle", "VERSION=#{version}", "SWIFT_BUILD_FLAGS=--disable-sandbox"
    prefix.install "build/Keywarp.app"
    bin.install_symlink prefix/"Keywarp.app/Contents/MacOS/keywarp"
  end

  service do
    run opt_prefix/"Keywarp.app/Contents/MacOS/keywarp"
    keep_alive true
    process_type :interactive
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/keywarp --version")
  end
end
