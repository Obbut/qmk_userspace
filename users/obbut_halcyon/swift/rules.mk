# Swift integration rules for QMK
# SPDX-License-Identifier: GPL-2.0-or-later
#
# This compiles Swift sources as part of the QMK build, giving Swift access
# to all generated headers and include paths.

# Swift source files
SWIFT_SRC_DIR = $(QMK_USERSPACE)/users/obbut_halcyon/swift/Sources/KeymapDSL
SWIFT_SOURCES = $(wildcard $(SWIFT_SRC_DIR)/*.swift)
SWIFT_BRIDGING_HEADER = $(QMK_USERSPACE)/users/obbut_halcyon/swift/BridgingHeader.h
SWIFT_OBJ = $(INTERMEDIATE_OUTPUT)/swift_keymap.o

# QMK firmware root (set in Docker environment)
QMK_FIRMWARE ?= /qmk_firmware

# ARM toolchain include path (for standard C headers like inttypes.h)
ARM_TOOLCHAIN_INC = /opt/arm-gnu-toolchain-13.2.Rel1-aarch64-arm-none-eabi/arm-none-eabi/include

# Build output directory with generated headers
SWIFT_GEN_INC = $(INTERMEDIATE_OUTPUT)/src

# Include paths for Swift (-Xcc -I format)
# QMK's CFLAGS isn't populated when this rule runs, so we list paths explicitly
SWIFT_INCLUDES = \
    -Xcc -I$(ARM_TOOLCHAIN_INC) \
    -Xcc -I$(SWIFT_GEN_INC) \
    -Xcc -I$(QMK_FIRMWARE)/quantum \
    -Xcc -I$(QMK_FIRMWARE)/quantum/keymap_extras \
    -Xcc -I$(QMK_FIRMWARE)/quantum/send_string \
    -Xcc -I$(QMK_FIRMWARE)/quantum/sequencer \
    -Xcc -I$(QMK_FIRMWARE)/quantum/process_keycode \
    -Xcc -I$(QMK_FIRMWARE)/quantum/logging \
    -Xcc -I$(QMK_FIRMWARE)/quantum/rgb_matrix \
    -Xcc -I$(QMK_FIRMWARE)/quantum/rgb_matrix/animations \
    -Xcc -I$(QMK_FIRMWARE)/quantum/color \
    -Xcc -I$(QMK_FIRMWARE)/lib/printf/src/printf \
    -Xcc -I$(QMK_FIRMWARE)/platforms \
    -Xcc -I$(QMK_FIRMWARE)/platforms/chibios \
    -Xcc -I$(QMK_FIRMWARE)/platforms/chibios/boards/GENERIC_PROMICRO_RP2040/configs \
    -Xcc -I$(QMK_FIRMWARE)/platforms/chibios/boards/common/configs \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/boards/RP_PICO_RP2040 \
    -Xcc -I$(QMK_FIRMWARE)/tmk_core/protocol \
    -Xcc -I$(QMK_FIRMWARE)/drivers \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/license \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/ports/common/ARMCMx \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/ports/RP/RP2040 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/ports/RP/LLD/DMAv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/ports/RP/LLD/GPIOv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/ports/RP/LLD/TIMERv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/hal/osal/rt-nil \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/rt/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/oslib/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/portability/GCC \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/ports/ARM-common \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/ports/ARMv6-M-RP2 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/startup/ARMCMx/devices/RP2040 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/startup/ARMCMx/compilers/GCC \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/ext/CMSIS/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/ext/ARM/CMSIS/Core/Include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/common/ext/RP/RP2040 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/ports/RP/LLD/DMAv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/ports/RP/LLD/GPIOv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/ports/RP/LLD/TIMERv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/ports/RP/LLD/SPIv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/ports/RP/LLD/USBDv1 \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios-contrib/os/hal/ports/RP/RP2040 \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/pico_platform_compiler/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2040/hardware_regs/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2040/hardware_structs/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_base/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_clocks/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_gpio/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_irq/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_pll/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_sync/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_resets/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_watchdog/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/hardware_xosc/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/common/pico_base_headers/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/common/pico_base/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/common/pico_sync/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/common/pico_time/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/boards/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/pico-sdk/src/rp2_common/pico_platform/include \
    -Xcc -I$(QMK_FIRMWARE)/lib/chibios/os/various/pico_bindings/dumb/include

# Swift defines
# RGB_MATRIX_ENABLE is always enabled for Halcyon keyboards
SWIFT_DEFINES = -Xcc -DTHUMB_PRESENT -Xcc -DRGB_MATRIX_ENABLE

# Add keyboard-specific Swift defines
ifeq ($(findstring kyria,$(KEYBOARD)),kyria)
    SWIFT_DEFINES += -D KYRIA_KEYBOARD
endif
ifeq ($(findstring elora,$(KEYBOARD)),elora)
    SWIFT_DEFINES += -D ELORA_KEYBOARD
endif
ifdef RGB_MATRIX_ENABLE
    SWIFT_DEFINES += -D RGB_MATRIX_ENABLE
endif

# Swift compiler flags
SWIFTFLAGS = \
    -target armv6m-none-none-eabi \
    -enable-experimental-feature Embedded \
    -wmo \
    -Osize \
    -Xcc -mcpu=cortex-m0plus \
    -Xcc -mthumb \
    -Xcc -fshort-enums \
    -Xcc -ffunction-sections \
    -Xcc -fdata-sections \
    $(SWIFT_INCLUDES) \
    $(SWIFT_DEFINES) \
    -import-bridging-header $(SWIFT_BRIDGING_HEADER)

# Generated header that Swift depends on (ensures Swift compiles after QMK generates it)
SWIFT_GENERATED_CONFIG = $(INTERMEDIATE_OUTPUT)/src/info_config.h

# Rule to compile Swift sources
# Depends on generated config header to ensure it runs after QMK header generation
$(SWIFT_OBJ): $(SWIFT_SOURCES) $(SWIFT_BRIDGING_HEADER) $(SWIFT_GENERATED_CONFIG)
	@echo "Compiling Swift sources..."
	swiftc $(SWIFTFLAGS) -c $(SWIFT_SOURCES) -o $@

# Make the elf target depend on Swift object (triggers the rule above)
$(BUILD_DIR)/$(TARGET).elf: $(SWIFT_OBJ)

# Add Swift object to link step
EXTRALDFLAGS += $(SWIFT_OBJ)

# Link against libraries required by Swift runtime
EXTRALDFLAGS += -lgcc -lm

# Add C glue layer source
SRC += $(QMK_USERSPACE)/users/obbut_halcyon/swift/swift_glue.c
