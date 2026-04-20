#!/usr/bin/env -S bash -euxo pipefail
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

# https://github.com/dmlc/decord?tab=readme-ov-file#installation
# Install system deps only when running as root; non-root builds rely on
# packages pre-installed in the Docker image (see Dockerfile).
if [ "$(id -u)" = "0" ]; then
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential \
        make \
        cmake \
        ffmpeg \
        libavcodec-dev \
        libavfilter-dev \
        libavformat-dev \
        libavutil-dev
fi

# /usr/local/cuda is bind-mounted read-only by the nvidia container runtime.
# Copy Video Codec SDK stubs and headers to writable /tmp locations instead.
NVCODEC_STUBS_DIR="/tmp/nvcodec-stubs"
NVCODEC_INCLUDE_DIR="/tmp/nvcodec-include"
mkdir -p "${NVCODEC_STUBS_DIR}" "${NVCODEC_INCLUDE_DIR}"
cp "Video_Codec_SDK_13.0.19/Lib/linux/stubs/$(uname -m)/"* "${NVCODEC_STUBS_DIR}/"
cp Video_Codec_SDK_13.0.19/Interface/* "${NVCODEC_INCLUDE_DIR}/"
export LD_LIBRARY_PATH="${NVCODEC_STUBS_DIR}:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${NVCODEC_STUBS_DIR}:${LIBRARY_PATH:-}"

temp_dir="$(mktemp -d)"
cd "${temp_dir}"
git clone --depth 1 --branch "v${PACKAGE_VERSION}" --recursive https://github.com/dmlc/decord
cd decord

# Fix to work with ffmpeg 6.0
find . -type f -exec sed -i "s/AVInputFormat \*/const AVInputFormat \*/g" {} \;
sed -i "s/[[:space:]]AVCodec \*dec/const AVCodec \*dec/" src/video/video_reader.cc
sed -i "s/avcodec\.h>/avcodec\.h>\n#include <libavcodec\/bsf\.h>/" src/video/ffmpeg/ffmpeg_common.h

DECORD_INSTALL_DIR="/tmp/decord-install"
mkdir build
cd build
cmake .. -DUSE_CUDA=ON -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${DECORD_INSTALL_DIR}" \
    -DCMAKE_LIBRARY_PATH="${NVCODEC_STUBS_DIR}" \
    -DCMAKE_INCLUDE_PATH="${NVCODEC_INCLUDE_DIR}"
make -j "$(nproc)"
make install
export LD_LIBRARY_PATH="${DECORD_INSTALL_DIR}/lib:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${DECORD_INSTALL_DIR}/lib:${LIBRARY_PATH:-}"
