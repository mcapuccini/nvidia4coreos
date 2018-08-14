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
docker run --name nvidia4coreos --privileged --volume /:/hostfs mcapuccini/nvidia4coreos:396.44-coreos-1800.6.0-kernel-4.14.59
```
> This will instert the necessary modules, create the NVIDIA devices in the host and exit. Please do not remove the container, as its volume needs to be accessed by the containers that need to access the GPUs.

The previous command installs NVIDIA driver version `396.44`, compiled with CoreOS `1800.6.0` toolchain and Linux `4.14.59`. Make sure to select the correct versions for your platform. You can find out available versions for the container [here](https://hub.docker.com/r/mcapuccini/nvidia4coreos/tags/). If there is no version available for your platform, please help yourself by adding an entry to the [Travis CI matrix](https://github.com/mcapuccini/nvidia4coreos/blob/master/.travis.yml#L17) via pull request.

## Usage
To access the GPUs a container needs to mount the `nvidia4coreos` volume, have access to the NVIDIA devices and define a couple of environment variables. A couple of examples follow.

- Verify if the drivers are installed:
```
docker run --rm \
  --volumes-from nvidia4coreos \
  $(for d in /dev/nvidia*; do echo -n "--device $d "; done) \
  --env PATH=$PATH:/opt/nvidia/bin/ \
  --env LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/lib  \
  ubuntu:bionic \
  nvidia-smi -L
```

- Run Tensorflow and verify if the GPUs are indentified: 
```
docker run --rm \
  --volumes-from nvidia4coreos \
  $(for d in /dev/nvidia*; do echo -n "--device $d "; done) \
  --env PATH=$PATH:/opt/nvidia/bin/ \
  --env LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/lib \
  tensorflow/tensorflow:latest-gpu \
  python -c "import tensorflow as tf;tf.Session(config=tf.ConfigProto(log_device_placement=True))"
```

## Uninstall
To unistall the driver please run:

```
sudo rmmod nvidia-uvm nvidia
docker rm nvidia4coreos
```
