# NVIDIA drivers for CoreOS Container Linux
[![Build Status](https://travis-ci.org/mcapuccini/nvidia4coreos.svg?branch=master)](https://travis-ci.org/mcapuccini/nvidia4coreos)

Yet another NVIDIA driver container for Container Linux (aka CoreOS). This container is based on a [blog post](https://blog.sourced.tech/post/docker_coreos_gpu_deep_learning/) by [source{d}](https://sourced.tech/).

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Uninstall](#uninstall)

## Install
Installing the driver on a CoreOS installation is as simple as running:

```
docker run --name nvidia4coreos --privileged --volume /:/hostfs mcapuccini/nvidia4coreos:<driver-version>-coreos-<coreos-version>
```
> **WARNING:** Make sure to select the correct versions for your platform, thus substituting `<driver-version>` and `<coreos-version>` in the previous command. You can find out available versions for the container [here](https://hub.docker.com/r/mcapuccini/nvidia4coreos/tags/). The CI runs once a day and builds the drivers for the latest version of CoreOS, however the driver versions are hardcoded in the CI matrix. If there is no driver available for your card, please help yourself by adding an entry to the [matrix](https://github.com/mcapuccini/nvidia4coreos/blob/master/.travis.yml#L17) via pull request.

This will instert the necessary modules, create the NVIDIA devices in the host and exit. Please do not remove the container, as its volume needs to be accessed by the containers that need to access the GPUs.

## Usage
To access the GPUs a container needs to mount the `nvidia4coreos` volume, have access to the NVIDIA devices and define a couple of environment variables. A couple of examples follow.

- Verify if the drivers are installed:
```
docker run --rm \
  --volumes-from nvidia4coreos \
  $(for d in /dev/nvidia*; do echo -n "--device $d "; done) \
  ubuntu:bionic \
  sh -c 'export PATH=$PATH:/opt/nvidia/bin/; \
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/lib; \
  nvidia-smi -L'
```

- Run Tensorflow and verify if the GPUs are indentified:
```
docker run --rm \
  --volumes-from nvidia4coreos \
  $(for d in /dev/nvidia*; do echo -n "--device $d "; done) \
  tensorflow/tensorflow:latest-gpu \
  sh -c 'export PATH=$PATH:/opt/nvidia/bin/; \
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/lib; \
  python -c "import tensorflow as tf;tf.Session(config=tf.ConfigProto(log_device_placement=True))"'
```

- Run Jupyter with Tensorflow on port 8888
```
docker run --rm -d \
  --publish 8888:8888 \
  --volumes-from nvidia4coreos \
  $(for d in /dev/nvidia*; do echo -n "--device $d "; done) \
  tensorflow/tensorflow:latest-gpu \
  sh -c 'export PATH=$PATH:/opt/nvidia/bin/; \
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/lib; \
  /run_jupyter.sh --allow-root'
```

## Uninstall
To unistall the driver please run:

```
sudo rmmod nvidia-uvm nvidia
docker rm nvidia4coreos
```
