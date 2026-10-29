#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
swift build -c release --product ausfallrekorder-cli --static-swift-stdlib
bin_dir=$(swift build -c release --show-bin-path)
arch=$(uname -m)
mkdir -p dist/linux
cp "$bin_dir/ausfallrekorder-cli" dist/linux/
cp README.md dist/linux/
ldd dist/linux/ausfallrekorder-cli > dist/linux/runtime-libraries.txt
tar -czf "dist/Ausfallrekorder-linux-$arch.tar.gz" -C dist/linux .
sha256sum "dist/Ausfallrekorder-linux-$arch.tar.gz"
