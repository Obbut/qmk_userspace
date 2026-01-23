# Swift integration rules for QMK
# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE: Swift compilation is handled by docker-build.sh before QMK build.
# The Swift object file is pre-compiled and placed in the INTERMEDIATE_OUTPUT
# directory. This rules.mk just adds it to the link step.

# Pre-compiled Swift object file location
# This is created by docker-build.sh before running qmk compile
SWIFT_OBJ = $(INTERMEDIATE_OUTPUT)/swift_keymap.o

# Add Swift object to QMK build via EXTRALDFLAGS
# OBJ doesn't work because QMK filters it for dependencies
EXTRALDFLAGS += $(SWIFT_OBJ)

# Link against libraries required by Swift runtime
# -lgcc provides __atomic_* operations
# -lm provides math functions like ceil
# These must come AFTER the Swift object file
EXTRALDFLAGS += -lgcc -lm

# Add C glue layer source (provides posix_memalign and other stubs)
SRC += $(QMK_USERSPACE)/users/obbut_halcyon/swift/swift_glue.c
