#!/bin/sh
# Digital RTL-to-GDS on the open IHP SG13G2 PDK, using the LibreLane Docker image.
# One-time PDK fetch (873 MB into ./pdk, git-ignored):
#   docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/work -w /work ghcr.io/librelane/librelane:3.0.16 \
#     ciel enable --pdk-family ihp-sg13g2 --pdk-root /work/pdk 5e6d592e4002946a4616f798c357f0f3c06cf3b6
cd "$(dirname "$0")/../.." || exit 1
exec docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$PWD":/work -w /work \
  ghcr.io/librelane/librelane:3.0.16 \
  librelane --pdk ihp-sg13g2 --pdk-root /work/pdk --manual-pdk \
  --run-tag "${1:-run1}" --overwrite flow/ihp_sg13g2/config.json
