#!/bin/bash
# Build a single package inside the CUDA 13.0 Docker container (aarch64).
# Usage: sbatch --export=PACKAGE=flash-attn,VERSION=2.7.4.post1 slurm/build-aarch64.sh
#
#SBATCH --job-name=cosmos-build
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --time=08:00:00
#SBATCH --output=slurm/logs/%x-%j.log
#SBATCH --error=slurm/logs/%x-%j.log

set -euo pipefail

echo "=== [$(date)] Environment setup ==="
export HF_HOME=/home/scratch.ktomala_other/.cache
export HOME=/home/scratch.ktomala_other
export UV_CACHE_DIR=/home/scratch.ktomala_other/.cache/uv/
export POETRY_HOME=/home/scratch.ktomala_other
export XDG_RUNTIME_DIR=/home/scratch.ktomala_other/.runtime/${SLURM_JOB_ID:-manual}
export HF_TOKEN=$(cat /home/ktomala/hf_token)
export GITHUB_TOKEN=$(cat /home/ktomala/github_token)
export XDG_BIN_HOME="${HOME}/.local/bin/$(uname -m)"
export PATH="${XDG_BIN_HOME}:${PATH}"
. /home/scratch.ktomala_other/venvs/v1/bin/activate
mkdir -p "${XDG_RUNTIME_DIR}"
echo "Node: $(hostname), User: $(id -un), Arch: $(uname -m)"

: "${PACKAGE:?Must set PACKAGE}"
: "${VERSION:?Must set VERSION}"
PYTHON_VERSION="${PYTHON_VERSION:-3.13}"
TORCH_VERSION="${TORCH_VERSION:-2.9}"
BUILD_DIR="${BUILD_DIR:-build}"

echo "=== [$(date)] Building ${PACKAGE}==${VERSION} py${PYTHON_VERSION} torch${TORCH_VERSION} cu13.0 aarch64 ==="

cd /home/scratch.ktomala_other/cosmos-dependencies
echo "=== [$(date)] Working directory: $(pwd) ==="

echo "=== [$(date)] Building Docker image (cached after first run on this node) ==="
flock /tmp/cosmos-docker-build.lock docker build --build-arg=CUDA_VERSION=13.0.2 -t cosmos-cu130 .
IMAGE=cosmos-cu130
echo "=== [$(date)] Starting Docker build ==="

docker run \
    --rm \
    --runtime=nvidia \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e HF_TOKEN="${HF_TOKEN}" \
    -e UV_CACHE_DIR=/tmp/uv-cache \
    -v "$(pwd):/app" \
    -v "${HF_HOME}:/cache" \
    -v "${HOME}/.ccache:/root/.ccache" \
    "$IMAGE" \
    just build "${PACKAGE}" "${VERSION}" "${PYTHON_VERSION}" "${TORCH_VERSION}" "${BUILD_DIR}"

echo "=== [$(date)] Docker build done ==="
echo "=== [$(date)] Built wheels: ==="
ls build/*${PACKAGE//-/_}*.whl 2>/dev/null || find build -name "*.whl" -newer build -ls

echo "=== [$(date)] Done: ${PACKAGE}==${VERSION} ==="
