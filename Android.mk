# Copyright 2008 The Android Open Source Project

LOCAL_PATH:= $(call my-dir)

################################
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
	genext2fs.c

LOCAL_CFLAGS := -O2 -g -Wall -DHAVE_CONFIG_H

LOCAL_MODULE := genext2fs

include $(BUILD_HOST_EXECUTABLE)

################################
include $(CLEAR_VARS)

LOCAL_MODULE := mkuserimg.sh
LOCAL_SRC_FILES := mkuserimg.sh
LOCAL_MODULE_CLASS := EXECUTABLES
# We don't need any additional suffix.
LOCAL_MODULE_SUFFIX :=
LOCAL_BUILT_MODULE_STEM := $(notdir $(LOCAL_SRC_FILES))
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

################################
