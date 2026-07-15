# Shared protocol-v4 build rules for every Swift-authored Obbut keymap.

VPATH += $(QMK_USERSPACE)/users/obbut_keymap
SRC += keymap_protocol_platform.c
SRC += embedded_keymap_protocol.clib
SRC += embedded_firmware.clib
ifeq ($(OBBUT_EMBEDDED_OBBUT_RUNTIME),yes)
    SRC += embedded_obbut_keymaps.clib
endif
RAW_ENABLE = yes
LDFLAGS += -Wl,-u,keymap_protocol_housekeeping
LDFLAGS += -Wl,-u,obbut_firmware_profile
ifeq ($(OBBUT_EMBEDDED_OBBUT_RUNTIME),yes)
    LDFLAGS += -Wl,-u,obbut_swift_post_init
endif

EMBEDDED_KEYMAP_PROTOCOL_SOURCES := $(sort $(wildcard $(QMK_USERSPACE)/Shared/KeymapProtocol/*.swift))
EMBEDDED_OBBUT_KEYMAP_SOURCES := $(QMK_USERSPACE)/SwiftKeymaps/Sources/ObbutKeymaps/ObbutEmbeddedFirmwareRuntime.swift
EMBEDDED_FIRMWARE_SOURCES := $(sort $(wildcard $(QMK_USERSPACE)/SwiftKeymaps/Sources/$(OBBUT_SWIFT_FIRMWARE_MODULE)/*+Embedded.swift))
EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER := $(QMK_USERSPACE)/users/obbut_keymap/keymap_protocol_bridge.h
EMBEDDED_SWIFT_MODULE_DIR := $(INTERMEDIATE_OUTPUT)/swift-modules

ifneq ($(filter RP2040 rp2040,$(MCU)),)
    EMBEDDED_SWIFT_TARGET := armv6m-none-none-eabi
    EMBEDDED_SWIFT_CPU_FLAGS := -Xcc -mcpu=cortex-m0plus -Xcc -mthumb
else
    EMBEDDED_SWIFT_TARGET := armv7em-none-none-eabi
    EMBEDDED_SWIFT_CPU_FLAGS := -Xcc -mcpu=cortex-m4 -Xcc -mthumb -Xcc -mfpu=fpv4-sp-d16 -Xcc -mfloat-abi=hard
endif

EMBEDDED_SWIFT_FLAGS := \
    -target $(EMBEDDED_SWIFT_TARGET) \
    -enable-experimental-feature Embedded \
    -import-bridging-header $(EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER) \
    -swift-version 6 \
    -warnings-as-errors \
    -whole-module-optimization \
    -parse-as-library \
    -Osize \
    -Xfrontend -function-sections \
    -Xfrontend -disable-stack-protector \
    $(EMBEDDED_SWIFT_CPU_FLAGS) \
    -Xcc -fshort-enums \
    -Xcc -I -Xcc $(QMK_USERSPACE)/$(MAIN_KEYMAP_PATH_1) \
    -Xcc -I -Xcc $(MAIN_KEYMAP_PATH_1) \
    -Xcc -isystem -Xcc /opt/qmk/arm-none-eabi/include \
    -I $(EMBEDDED_SWIFT_MODULE_DIR)

$(INTERMEDIATE_OUTPUT)/embedded_keymap_protocol.o: $(EMBEDDED_KEYMAP_PROTOCOL_SOURCES) $(EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER) $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: Embedded Swift protocol v4"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) -module-name QMKFirmwareRuntime -emit-module -emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/QMKFirmwareRuntime.swiftmodule -c $(EMBEDDED_KEYMAP_PROTOCOL_SOURCES) -o $@

$(INTERMEDIATE_OUTPUT)/embedded_obbut_keymaps.o: $(EMBEDDED_OBBUT_KEYMAP_SOURCES) $(INTERMEDIATE_OUTPUT)/embedded_keymap_protocol.o $(EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER) $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: ObbutKeymaps Embedded Swift"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) -module-name ObbutKeymaps -emit-module -emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/ObbutKeymaps.swiftmodule -c $(EMBEDDED_OBBUT_KEYMAP_SOURCES) -o $@

$(INTERMEDIATE_OUTPUT)/embedded_firmware.o: $(EMBEDDED_FIRMWARE_SOURCES) $(INTERMEDIATE_OUTPUT)/embedded_obbut_keymaps.o $(EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER) $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: $(OBBUT_SWIFT_FIRMWARE_MODULE) Embedded Swift"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) -module-name $(OBBUT_SWIFT_FIRMWARE_MODULE) -emit-module -emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/$(OBBUT_SWIFT_FIRMWARE_MODULE).swiftmodule -c $(EMBEDDED_FIRMWARE_SOURCES) -o $@
