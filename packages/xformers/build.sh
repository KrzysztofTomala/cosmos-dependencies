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

# https://github.com/facebookresearch/xformers?tab=readme-ov-file#installing-xformers

# https://github.com/facebookresearch/xformers/blob/main/setup.py
export XFORMERS_BUILD_TYPE="Release"
export MAX_JOBS="${MAX_JOBS:-4}"

# Clone xformers so we can patch setup.py before building.
# xformers has FLASHATTENTION_DISABLE_PAGEDKV commented out due to an nvcc
# segfault (https://github.com/Dao-AILab/flash-attention/issues/1453) that
# also affects nvcc 13.0. Uncommenting it skips the paged KV kernel
# instantiations that trigger the ICE.
temp_dir="$(mktemp -d)"
git clone --depth 1 --branch "v${PACKAGE_VERSION}" --recurse-submodules \
    "https://github.com/facebookresearch/xformers.git" "${temp_dir}/xformers"
sed -i 's|# ("paged", "-DFLASHATTENTION_DISABLE_PAGEDKV"),|("paged", "-DFLASHATTENTION_DISABLE_PAGEDKV"),|' \
    "${temp_dir}/xformers/setup.py"

pip wheel \
	-v \
	--no-deps \
	--no-build-isolation \
	--check-build-dependencies \
	--wheel-dir="${OUTPUT_DIR}" \
	"${temp_dir}/xformers" \
	"$@"
