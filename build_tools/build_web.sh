#!/usr/bin/env sh
set -e

export RUSTFLAGS="-C target-feature=+atomics,+bulk-memory,+mutable-globals"
# build Rust code with wasm-pack
wasm-pack build --release -t no-modules \
    --no-typescript --out-name native \
    --out-dir ../web/native native \
    -- -Z build-std=std,panic_abort
