#!/bin/bash
# Build a single package inside the CUDA 13.0 Docker container (aarch64).
# Usage: sbatch --export=PACKAGE=flash-attn,VERSION=2.7.4.post1 slurm/build-aarch64.sh
#
#SBATCH --job-name=cosmos-build
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --time=04:00:00
#SBATCH --output=slurm/logs/%x-%j.log
#SBATCH --error=slurm/logs/%x-%j.log

set -euo pipefail

# Environment setup
export HF_HOME=/home/scratch.ktomala_other/.cache
export HOME=/home/scratch.ktomala_other
export UV_CACHE_DIR=/home/scratch.ktomala_other/.cache/uv/
export POETRY_HOME=/home/scratch.ktomala_other
export XDG_RUNTIME_DIR=/home/scratch.ktomala_other/.runtime/${SLURM_JOB_ID}
export HF_TOKEN=$(cat /home/ktomala/hf_token)
export GITHUB_TOKEN=$(cat /home/ktomala/github_token)
export XDG_BIN_HOME="${HOME}/.local/bin/$(uname -m)"
export PATH="${XDG_BIN_HOME}:${PATH}"
. /home/scratch.ktomala_other/venvs/v1/bin/activate
mkdir -p "${XDG_RUNTIME_DIR}"
cd /home/scratch.ktomala_other

: "${PACKAGE:?Must set PACKAGE}"
: "${VERSION:?Must set VERSION}"
PYTHON_VERSION="${PYTHON_VERSION:-3.13}"
TORCH_VERSION="${TORCH_VERSION:-2.9}"
BUILD_DIR="${BUILD_DIR:-build}"

echo "=== Building ${PACKAGE}==${VERSION} py${PYTHON_VERSION} torch${TORCH_VERSION} cu13.0 aarch64 ==="

cd "$(dirname "$0")/.."

# Build Docker image — use a lockfile to avoid concurrent builds corrupting the cache
DOCKER_LOCK=/tmp/cosmos-docker-build.lock
IMAGE=$(flock "${DOCKER_LOCK}" docker build --build-arg=CUDA_VERSION=13.0.2 -q .)

docker run \
    --rm \
    --runtime=nvidia \
    --user "$(id -u):$(id -g)" \
    -e HF_TOKEN="${HF_TOKEN}" \
    -e UV_CACHE_DIR=/root/.cache/uv \
    -v "$(pwd):/app" \
    -v "${HF_HOME}:/root/.cache" \
    -v "${HOME}/.ccache:/root/.ccache" \
    "$IMAGE" \
    just build "${PACKAGE}" "${VERSION}" "${PYTHON_VERSION}" "${TORCH_VERSION}" "${BUILD_DIR}"

docker run --rm --userns=host -v "$(pwd):/app" ubuntu chmod -R 777 /app/build

echo "=== Done: ${PACKAGE}==${VERSION} ==="
