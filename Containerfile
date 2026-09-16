FROM docker.io/library/rust:1-bookworm AS build

RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v3.0.1 https://gitlab.steamos.cloud/frame-public/lepton.git /src && \
    cd /src/compat_tool/liblepton/apk_extractor && cargo build --release

RUN mkdir -p /out/lepton/liblepton/apk_extractor/bin /out/lepton/images && cd /src && \
    cp compat_tool/lepton compat_tool/toolmanifest.vdf README.md LICENSE.md LICENSE.AOSP.image LICENSE.lepton /out/lepton/ && \
    ln -s lepton /out/lepton/fauxdroid && \
    cp compat_tool/liblepton/*.sh compat_tool/liblepton/lepton.seccomp.json compat_tool/liblepton/openvrpaths.vrpath /out/lepton/liblepton/ && \
    cp -r compat_tool/liblepton/perfetto /out/lepton/liblepton/ && \
    cp -r compat_tool/images/rootfs_overlay /out/lepton/images/ && \
    cp compat_tool/liblepton/apk_extractor/target/release/apk-info-extractor /out/lepton/liblepton/apk_extractor/bin/ && \
    echo v3.0.1 > /out/lepton/version.txt && \
    test -x /out/lepton/lepton && test -x /out/lepton/liblepton/apk_extractor/bin/apk-info-extractor

FROM ghcr.io/containerpak/base:main

RUN apt-get update && apt-get install -y --no-install-recommends \
    podman passt uidmap fuse-overlayfs catatonit adb zstd && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /out/lepton /usr/share/steam/compatibilitytools.d/lepton
COPY --chmod=0755 lepton /usr/bin/lepton
