#!/system/bin/sh
MODDIR=${0%/*}
setenforce 0
echo '0' > /sys/fs/selinux/enforce