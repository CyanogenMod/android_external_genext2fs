#!/bin/bash
#

function usage() {
cat<<EOT
Usage:
mkuserimg.sh MKEXT2IMG TUNE2FS E2FSCK SRC_DIR OUTPUT_FILE EXT_VARIANT [LABEL]
EOT
}

if [ $# -ne 6 -a $# -ne 7 ]; then
  usage
  exit 1
fi

MKEXT2IMG=$1
if [ ! -x $MKEXT2IMG -o ! -f $MKEXT2IMG ]; then
  echo "Can not find executable $MKEXT2IMG!"
  exit 2
fi

TUNE2FS=$2
if [ ! -x $TUNE2FS -o ! -f $TUNE2FS ]; then
  echo "Can not find executable $TUNE2FS!"
  exit 3
fi

E2FSCK=$3
if [ ! -x $E2FSCK -o ! -f $E2FSCK ]; then
  echo "Can not find executable $E2FSCK!"
  exit 4
fi

SRC_DIR=$4
if [ ! -d $SRC_DIR ]; then
  echo "Can not find directory $SRC_DIR!"
  exit 5
fi

OUTPUT_FILE=$5
EXT_VARIANT=$6
LABEL=$7

case $EXT_VARIANT in
  ext2) ;;
  ext3) ;;
  ext4) ;;
  *) echo "Only ext2, ext3, ext4 are supported!"; exit 6 ;;
esac

num_blocks=`du -sk $SRC_DIR | tail -n1 | awk '{print $1;}'`
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

echo "$MKEXT2IMG -a -d $SRC_DIR -b $num_blocks -N $num_inodes -m 0 $OUTPUT_FILE"
$MKEXT2IMG -a -d $SRC_DIR -b $num_blocks -N $num_inodes -m 0 $OUTPUT_FILE
if [ $? -ne 0 ]; then
  exit 7
fi

if [ -n $LABEL ]; then
  echo "$TUNE2FS -L $LABEL $OUTPUT_FILE"
  $TUNE2FS -L $LABEL $OUTPUT_FILE
  if [ $? -ne 0 ]; then
    exit 8
  fi
fi

if [ $EXT_VARIANT = "ext3" ]; then
  echo "$TUNE2FS -j $OUTPUT_FILE"
  $TUNE2FS -j $OUTPUT_FILE
  if [ $? -ne 0 ]; then
    exit 9
  fi
elif [ $EXT_VARIANT = "ext4" ]; then
  echo "$TUNE2FS -j -O extents,uninit_bg,dir_index $OUTPUT_FILE"
  $TUNE2FS -j -O extents,uninit_bg,dir_index $OUTPUT_FILE
  if [ $? -ne 0 ]; then
    exit 10
  fi
fi

echo "$TUNE2FS -C 1 $OUTPUT_FILE"
$TUNE2FS -C 1 $OUTPUT_FILE
if [ $? -ne 0 ]; then
  exit 11
fi

echo "$E2FSCK -fy $OUTPUT_FILE"
$E2FSCK -fy $OUTPUT_FILE
if [ $? -ge 4 ]; then
  echo "$E2FSCK returns value $?, no less than 4!"
  exit 12
else
  exit 0
fi
