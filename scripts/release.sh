#!/bin/bash
# Tags a release, then points Formula/keywarp.rb at the tag's tarball so
# `brew upgrade` picks it up. Usage: make release VERSION=X.Y.Z
set -euo pipefail

die() { echo "release: $*" >&2; exit 1; }

version="${1:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "VERSION must be X.Y.Z, got \"$version\""
[[ "$(git branch --show-current)" == main ]] || die "must be on main"
[[ -z "$(git status --porcelain)" ]] || die "working tree is not clean"
git fetch --quiet origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || die "main is not in sync with origin/main"

swift test

tag="v$version"
git tag -a "$tag" -m "keywarp $version"
git push origin "$tag"

url="https://github.com/hoelter/keywarp/archive/refs/tags/$tag.tar.gz"
sha256="$(curl --fail --silent --show-error --location --retry 5 --retry-all-errors "$url" | shasum -a 256 | cut -d ' ' -f 1)"
sed -i '' \
  -e "s|^  url \".*\"|  url \"$url\"|" \
  -e "s|^  sha256 \".*\"|  sha256 \"$sha256\"|" \
  Formula/keywarp.rb
git commit --quiet -m "keywarp $version" Formula/keywarp.rb
git push origin main
echo "released $tag ($sha256)"
