#!/bin/bash
# Submit all aarch64 py313 cu130 build jobs to SLURM.
# Run this script on the aarch64 cluster head node.
# Usage: bash slurm/submit-aarch64.sh

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p slurm/logs

submit() {
    local package="$1"
    local version="$2"
    sbatch \
        --job-name="build-${package}" \
        --export="PACKAGE=${package},VERSION=${version}" \
        slurm/build-aarch64.sh
}

# Core packages required by cosmos-oss cu130_torch29
submit flash-attn          2.7.4.post1
submit natten               0.21.0
submit transformer-engine   2.8.0
submit decord               0.6.0

# Extra packages
submit apex                 0.1.0
submit sageattention        2.2.0.dev1
submit torchcodec           0.9.1
submit xformers             0.0.33
submit groundingdino        0.1.0
submit vllm                 0.11.0
