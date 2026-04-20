#!/bin/bash
# Submit all aarch64 py313 cu130 build jobs to SLURM.
# Run this script on the aarch64 cluster head node.
# Usage: P="<partitions>" bash slurm/submit-aarch64.sh

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p slurm/logs
export P="gh200-480gb@evt/lego-cg1@qs/1gpu-72cpu-575gb,gh200-120gb@evt/skinnyjoe@dvt/4gpu-288cpu-860gb"

: "${P:?Must set P to the SLURM partition(s), e.g. P=gh200-480gb bash slurm/submit-aarch64.sh}"

submit() {
    local package="$1"
    local version="$2"
    local extra="${3:-}"
    sbatch \
        --partition="${P}" \
        --job-name="build-${package}" \
        --export="PACKAGE=${package},VERSION=${version}${extra:+,${extra}}" \
        slurm/build-aarch64.sh
}

# Core packages required by cosmos-oss cu130_torch29
# submit flash-attn          2.7.4.post1  # running: lego-cg1-qs-213
submit natten               0.21.0
submit transformer-engine   2.8
submit decord               0.6.0

# Extra packages
#submit apex                 0.1.0
submit sageattention        2.2.0.dev1
submit torchcodec           0.9.1
#submit xformers             0.0.33
submit groundingdino        0.1.0-alpha2
submit vllm                 0.11.0  TORCH_VERSION=2.8
