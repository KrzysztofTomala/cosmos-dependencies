#!/bin/bash
# Submit all x86_64 py313 cu130 build jobs to SLURM.
# Run this script on the x86_64 cluster head node.
# Usage: P="<partitions>" bash slurm/submit-x86.sh

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p slurm/logs
export P="h100-80gb-hbm3@ts6/mg62g4100/1gpu-32cpu-256gb,h100-pcie@ts3/romed8nl/1gpu-32cpu-128gb,h100-pcie@cr+mp/h12sswnt/1gpu-16cpu-128gb"
: "${P:?Must set P to the SLURM partition(s), e.g. P=h100-80gb bash slurm/submit-x86.sh}"

submit() {
    local package="$1"
    local version="$2"
    local extra="${3:-}"
    sbatch \
        --partition="${P}" \
        --job-name="build-${package}" \
        --export="PACKAGE=${package},VERSION=${version}${extra:+,${extra}}" \
        slurm/build-x86.sh
}

# Core packages required by cosmos-oss cu130_torch29
# submit flash-attn          2.7.4.post1  # running: ipp2-0720
# submit natten               0.21.0       # running: ipp2-0713
submit transformer-engine   2.8
# submit xformers             0.0.33       # running: ipp2-0715
submit decord               0.6.0

# Extra packages
#submit apex                 0.1.0
#submit sageattention        2.2.0
submit torchcodec           0.9.1
# submit groundingdino        0.1.0-alpha2  # incompatible with nvcc 13.0
# submit vllm                 0.11.0 # skip for now
