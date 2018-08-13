# This Dockerfile is a refactory of: https://github.com/src-d/coreos-nvidia/blob/master/Dockerfile

# Fist compile the driver in a "builder" container
FROM ubuntu:bionic as builder
MAINTAINER Marco Capuccini <marco.capuccini@it.uu.se>

# Build arguments
ARG COREOS_RELEASE_CHANNEL
ARG COREOS_VERSION
ARG KERNEL_REPOSITORY
ARG KERNEL_VERSION
ARG NVIDIA_DRIVER_URL
ARG NVIDIA_DRIVER_VERSION

# Build environment
ENV KERNEL_PATH /usr/src/kernels/linux
ENV KERNEL_TAG v${KERNEL_VERSION}
ENV COREOS_RELEASE_URL https://${COREOS_RELEASE_CHANNEL}.release.core-os.net/amd64-usr/${COREOS_VERSION}
ENV NVIDIA_PATH /opt/nvidia
ENV NVIDIA_BUILD_PATH /opt/nvidia/build
ENV NVIDIA_INSTALLER /opt/nvidia/download/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}/nvidia-installer

# Install deps
RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    curl \
    git \
    bc \
    make \
    dpkg-dev \
    libssl-dev \
    module-init-tools \
    p7zip-full \
    libelf-dev && \
    apt-get autoremove && \
    apt-get clean

# Get the kernel source
RUN git clone ${KERNEL_REPOSITORY} \
    --single-branch \
    --depth 1 \
    --branch ${KERNEL_TAG} \
    ${KERNEL_PATH}
WORKDIR ${KERNEL_PATH}
RUN git checkout -b stable ${KERNEL_TAG} && rm -rf .git

# Get CoreOS toolchain and kernel configs
RUN curl ${COREOS_RELEASE_URL}/coreos_developer_container.bin.bz2 | \
        bzip2 -d > /tmp/coreos_developer_container.bin
RUN 7z e /tmp/coreos_developer_container.bin "usr/lib64/modules/*-coreos*/build/.config"
RUN 7z e /tmp/coreos_developer_container.bin "usr/lib64/modules/*-coreos*/build/include/config/kernel.release" && cp kernel.release /tmp/kernel.release

# Prepare kernel source tree to build external modules
RUN make modules_prepare
RUN sed -i -e "s/${KERNEL_VERSION}/$(cat /tmp/kernel.release)/" include/generated/utsrelease.h

# Get the driver
WORKDIR ${NVIDIA_PATH}/download
RUN curl ${NVIDIA_DRIVER_URL} -o driver.run && \
    chmod +x driver.run

# Extract the driver
RUN ${NVIDIA_PATH}/download/driver.run \
    --accept-license \
    --extract-only \
    --ui=none

# Build kernel modules
RUN ${NVIDIA_INSTALLER} \
    --accept-license \
    --no-questions \
    --ui=none \
    --no-precompiled-interface \
    --kernel-source-path=${KERNEL_PATH} \
    --kernel-name=$(cat /tmp/kernel.release) \
    --installer-prefix=${NVIDIA_BUILD_PATH} \
    --utility-prefix=${NVIDIA_BUILD_PATH} \
    --opengl-prefix=${NVIDIA_BUILD_PATH}
RUN mkdir  ${NVIDIA_BUILD_PATH}/lib/modules/ && \
    cp -rf /lib/modules/$(cat /tmp/kernel.release) ${NVIDIA_BUILD_PATH}/lib/modules/${KERNEL_VERSION}

# Create an image with the modules only
FROM ubuntu:bionic
MAINTAINER Marco Capuccini <marco.capuccini@it.uu.se>

# Arguments
ARG COREOS_RELEASE_CHANNEL
ARG COREOS_VERSION
ARG KERNEL_VERSION
ARG NVIDIA_DRIVER_VERSION

# Environment
ENV COREOS_RELEASE_CHANNEL ${COREOS_RELEASE_CHANNEL}
ENV COREOS_VERSION ${COREOS_VERSION}
ENV NVIDIA_DRIVER_VERSION ${NVIDIA_DRIVER_VERSION}
ENV KERNEL_VERSION ${KERNEL_VERSION}
ENV NVIDIA_PATH /opt/nvidia
ENV NVIDIA_BIN_PATH ${NVIDIA_PATH}/bin
ENV NVIDIA_LIB_PATH ${NVIDIA_PATH}/lib
ENV NVIDIA_MODULES_PATH ${NVIDIA_LIB_PATH}/modules/${KERNEL_VERSION}/video
ENV PATH $PATH:${NVIDIA_BIN_PATH}
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${NVIDIA_LIB_PATH}
ENV HOSTFS=/hostfs

# Install deps
RUN apt-get -y update && \
    apt-get -y install module-init-tools pciutils && \
    apt-get autoremove && \
    apt-get clean

# Copy modules from builder container
COPY --from=builder /opt/nvidia/build ${NVIDIA_PATH}
COPY entrypoint.sh /entrypoint.sh

# Volume to be consumed by other containers
VOLUME ${NVIDIA_PATH}

# Specify the entrypoint
ENTRYPOINT /entrypoint.sh
