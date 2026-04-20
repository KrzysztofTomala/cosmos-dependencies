# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://github.com/NVIDIA/TransformerEngine?tab=readme-ov-file#pip-installation
export NVTE_FRAMEWORK=pytorch
# Only set NVTE_CUDA_ARCHS if TORCH_CUDA_ARCH_LIST is non-empty; if unset, TE
# falls back to its CUDA-version-specific defaults (which is what we want).
if [[ -n "${TORCH_CUDA_ARCH_LIST:-}" ]]; then
    export NVTE_CUDA_ARCHS="${TORCH_CUDA_ARCH_LIST//./}"
fi

if [ "$(id -u)" = "0" ]; then
    apt-get update && apt-get install -y --no-install-recommends python3-dev
fi

# Create missing PyTorch header file for CUDA extension builds
TORCH_INCLUDE=$(python -c "import torch; print(torch.__path__[0])")/include
if [[ ! -f "${TORCH_INCLUDE}/c10/cuda/impl/cuda_cmake_macros.h" ]]; then
	mkdir -p "${TORCH_INCLUDE}/c10/cuda/impl"
	cat >"${TORCH_INCLUDE}/c10/cuda/impl/cuda_cmake_macros.h" <<'HEADER'
#pragma once

// Automatically generated header file for the C10 CUDA library.  Do not
// include this file directly.  Instead, include c10/cuda/CUDAMacros.h

#define C10_CUDA_BUILD_SHARED_LIBS
HEADER
fi

pip wheel \
	-v \
	--no-deps \
	--no-build-isolation \
	--check-build-dependencies \
	--wheel-dir="${OUTPUT_DIR}" \
	"git+https://github.com/NVIDIA/TransformerEngine.git@v${PACKAGE_VERSION}" \
	"$@"
