#!/bin/sh

# Instert deps modules if not inserted already
if ! (lsmod | grep -w -q "^ipmi_msghandler"); then
  insmod `find $HOSTFS/usr -iname ipmi_msghandler.ko`
fi
if ! (lsmod | grep -w -q "^ipmi_devintf"); then
  insmod `find $HOSTFS/usr -iname ipmi_devintf.ko`
fi

# Insert nvidia modules
insmod ${NVIDIA_MODULES_PATH}/nvidia.ko
insmod ${NVIDIA_MODULES_PATH}/nvidia-uvm.ko

# Count the number of NVIDIA controllers found.
ndevs=`lspci | grep -i NVIDIA`
n3d=`echo "$ndevs" | grep "3D controller" | wc -l`
nvga=`echo "$ndevs" | grep "VGA compatible controller" | wc -l`
n=`expr $n3d + $nvga - 1`

# Make devices
for i in `seq 0 $n`; do
  rm -f $HOSTFS/dev/nvidia$i
  mknod -m 666 $HOSTFS/dev/nvidia$i c 195 $i
done
rm -f $HOSTFS/dev/nvidiactl
mknod -m 666 $HOSTFS/dev/nvidiactl c 195 255
d=`grep nvidia-uvm $HOSTFS/proc/devices | awk '{print $1}'`
rm -f $HOSTFS/dev/nvidia-uvm
mknod -m 666 $HOSTFS/dev/nvidia-uvm c $d 0
