#!/bin/bash
#
# To call this script, make sure paths of executables such as
# genext2fs, tune2fs, e2fsck are in the environmental variable PATH.

function usage() {
cat<<EOT
Usage:
mkuserimg.sh SRC_DIR OUTPUT_FILE EXT_VARIANT [LABEL]
EOT
}

echo "in mkuserimg.sh PATH=$PATH"

if [ $# -ne 3 -a $# -ne 4 ]; then
  usage
  exit 1
fi

SRC_DIR=$1
if [ ! -d $SRC_DIR ]; then
  echo "Can not find directory $SRC_DIR!"
  exit 2
fi

OUTPUT_FILE=$2
EXT_VARIANT=$3
LABEL=$4

case $EXT_VARIANT in
  ext2) ;;
  ext3) ;;
  ext4) ;;
  *) echo "Only ext2, ext3, ext4 are supported!"; exit 3 ;;
esac

num_blocks=`du -skL $SRC_DIR | tail -n1 | awk '{print $1;}'`
if [ $num_blocks -lt 20480 ]; then
  extra_blocks=3072
else
  extra_blocks=20480
fi
num_blocks=`expr $num_blocks + $extra_blocks`
num_inodes=`find $SRC_DIR | wc -l`
num_inodes=`expr $num_inodes + 500`

echo "num_blocks=$num_blocks"
echo "num_inodes=$num_inodes"

echo "genext2fs -a -d $SRC_DIR -b $num_blocks -N $num_inodes -m 0 $OUTPUT_FILE"
genext2fs -a -d $SRC_DIR -b $num_blocks -N $num_inodes -m 0 $OUTPUT_FILE
if [ $? -ne 0 ]; then
  exit 4
fi

if [ -n $LABEL ]; then
  echo "tune2fs -L $LABEL $OUTPUT_FILE"
  tune2fs -L $LABEL $OUTPUT_FILE
  if [ $? -ne 0 ]; then
    exit 5
  fi
fi

if [ $EXT_VARIANT = "ext3" ]; then
  echo "tune2fs -j $OUTPUT_FILE"
  tune2fs -j $OUTPUT_FILE
  if [ $? -ne 0 ]; then
    exit 6
  fi
elif [ $EXT_VARIANT = "ext4" ]; then
  echo "tune2fs -j -O extents,uninit_bg,dir_index $OUTPUT_FILE"
  tune2fs -j -O extents,uninit_bg,dir_index $OUTPUT_FILE
  if [ $? -ne 0 ]; then
    exit 7
  fi
fi

echo "tune2fs -C 1 $OUTPUT_FILE"
tune2fs -C 1 $OUTPUT_FILE
if [ $? -ne 0 ]; then
  exit 8
fi

echo "e2fsck -fy $OUTPUT_FILE"
e2fsck -fy $OUTPUT_FILE
if [ $? -ge 4 ]; then
  echo "e2fsck returns value $?, no less than 4!"
  exit 9
else
  exit 0
fi
