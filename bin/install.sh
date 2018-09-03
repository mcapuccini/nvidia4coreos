#!/bin/bash

# Install Unit file
# shellcheck disable=SC2016,SC1090
source "$HOSTFS/etc/os-release"
tag=mcapuccini/nvidia4coreos:"${NVIDIA_DRIVER_VERSION}"-coreos-'${VERSION}'
cat <<EOF > $HOSTFS/etc/systemd/system/nvidia4coreos.service
[Unit]
Description=nvidia4coreos
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=20m
EnvironmentFile=/etc/os-release
ExecStartPre=/usr/bin/docker pull ${tag}
ExecStartPre=-/usr/bin/docker rm nvidia4coreos
ExecStartPre=-/sbin/rmmod nvidia_uvm nvidia
ExecStart=/usr/bin/docker run --privileged --volume /:${HOSTFS} --name nvidia4coreos ${tag} insert.sh
ExecStop=/usr/bin/docker rm nvidia4coreos
ExecStop=-/sbin/rmmod nvidia_uvm nvidia

[Install]
WantedBy=multi-user.target
EOF
