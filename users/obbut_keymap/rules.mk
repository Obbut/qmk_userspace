# Direct Embedded Swift build shared by every Obbut firmware.

VPATH += $(QMK_USERSPACE)/users/obbut_keymap
SRC += qmk_swift_shim.c
SRC += keymap_protocol_platform.c
SRC += embedded_selected_firmware.clib
SRC += embedded_firmware_module.clib
SRC += embedded_obbut_keymaps.clib
SRC += embedded_qmk_firmware_runtime.clib
SRC += embedded_qmk_keymap_kit.clib
RAW_ENABLE = yes

LDFLAGS += -Wl,-u,qmk_swift_post_init
LDFLAGS += -Wl,-u,qmk_swift_keycode_at
LDFLAGS += -Wl,-u,qmk_swift_process_record

EMBEDDED_SWIFT_ROOT := $(QMK_USERSPACE)/SwiftKeymaps
EMBEDDED_SWIFT_SOURCE_ROOT := $(EMBEDDED_SWIFT_ROOT)/Sources
EMBEDDED_SWIFT_MODULE_DIR := $(INTERMEDIATE_OUTPUT)/swift-modules
EMBEDDED_SWIFT_BRIDGING_HEADER := $(QMK_USERSPACE)/users/obbut_keymap/keymap_protocol_bridge.h

EMBEDDED_QMK_KEYMAP_KIT_SOURCES := \
    $(sort $(wildcard $(EMBEDDED_SWIFT_SOURCE_ROOT)/QMKKeymapKit/*.swift))

EMBEDDED_QMK_FIRMWARE_RUNTIME_SOURCES := \
    $(sort $(wildcard $(EMBEDDED_SWIFT_SOURCE_ROOT)/QMKFirmwareRuntime/*.swift)) \
    $(sort $(wildcard $(QMK_USERSPACE)/Shared/KeymapProtocol/*.swift))

EMBEDDED_OBBUT_KEYMAP_SOURCES := \
    $(sort $(wildcard $(EMBEDDED_SWIFT_SOURCE_ROOT)/ObbutKeymaps/*.swift))
EMBEDDED_FIRMWARE_SOURCES := $(sort \
    $(wildcard $(EMBEDDED_SWIFT_SOURCE_ROOT)/$(OBBUT_SWIFT_FIRMWARE_MODULE)/*.swift))
EMBEDDED_SELECTED_FIRMWARE_SOURCE := $(EMBEDDED_SWIFT_ROOT)/Embedded/SelectedFirmwareRuntime.swift

EMBEDDED_MACRO_SOURCES := \
    $(EMBEDDED_SWIFT_SOURCE_ROOT)/QMKFirmwareMacros/QMKFirmwareDiagnostic.swift \
    $(EMBEDDED_SWIFT_SOURCE_ROOT)/QMKFirmwareMacros/QMKFirmwareLayerIDSynthesis.swift \
    $(EMBEDDED_SWIFT_SOURCE_ROOT)/QMKFirmwareMacros/QMKFirmwareMacro.swift \
    $(EMBEDDED_SWIFT_ROOT)/Embedded/QMKFirmwarePluginMain.swift
EMBEDDED_MACRO_HASH := $(shell cat $(EMBEDDED_MACRO_SOURCES) | sha256sum | cut -c1-16)
EMBEDDED_MACRO_EXECUTABLE := \
    $(INTERMEDIATE_OUTPUT)/swift-host/6.3.3-$(EMBEDDED_MACRO_HASH)/QMKFirmwareMacros

ifneq ($(filter RP2040 rp2040,$(MCU)),)
    EMBEDDED_SWIFT_TARGET := armv6m-none-none-eabi
    EMBEDDED_SWIFT_CPU_FLAGS := -Xcc -mcpu=cortex-m0plus -Xcc -mthumb
else
    EMBEDDED_SWIFT_TARGET := armv7em-none-none-eabi
    EMBEDDED_SWIFT_CPU_FLAGS := \
        -Xcc -mcpu=cortex-m4 \
        -Xcc -mthumb \
        -Xcc -mfpu=fpv4-sp-d16 \
        -Xcc -mfloat-abi=hard
endif

# Preserve QMK's active fork, keyboard, keymap, configuration, and
# preprocessor state when Clang imports the bridging header. ChibiOS platform
# post-config headers are C implementation details rather than QMK ABI input;
# importing them also exposes a `time` field that conflicts with libc's
# declaration in Swift's Clang importer on the Keychron fork.
EMBEDDED_SWIFT_CONFIG_HEADERS = $(filter-out \
    ./platforms/% platforms/% quantum/%,$(CONFIG_H) $(POST_CONFIG_H))
EMBEDDED_SWIFT_QMK_FLAGS = \
    $(foreach flag,$(filter -D% -I%,$($(MASTER_OUTPUT)_CFLAGS)),-Xcc $(flag)) \
    $(foreach header,$(EMBEDDED_SWIFT_CONFIG_HEADERS),-Xcc -include -Xcc $(header))

EMBEDDED_SWIFT_FLAGS = \
    -target $(EMBEDDED_SWIFT_TARGET) \
    -enable-experimental-feature Embedded \
    -import-bridging-header $(EMBEDDED_SWIFT_BRIDGING_HEADER) \
    -swift-version 6 \
    -warnings-as-errors \
    -whole-module-optimization \
    -cross-module-optimization \
    -parse-as-library \
    -Osize \
    -Xfrontend -function-sections \
    -Xfrontend -disable-stack-protector \
    $(EMBEDDED_SWIFT_CPU_FLAGS) \
    $(EMBEDDED_SWIFT_QMK_FLAGS) \
    -Xcc -fshort-enums \
    -Xcc -isystem \
    -Xcc /opt/qmk/arm-none-eabi/include \
    -I $(EMBEDDED_SWIFT_MODULE_DIR) \
    -load-plugin-executable $(EMBEDDED_MACRO_EXECUTABLE)\#QMKFirmwareMacros

$(EMBEDDED_MACRO_EXECUTABLE): $(EMBEDDED_MACRO_SOURCES) $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D)
	@$(SILENT) || printf "Compiling: QMKFirmware macro plugin"
	@swiftc \
		-I /usr/lib/swift/host \
		-L /usr/lib/swift/host \
		-Xlinker -rpath \
		-Xlinker /usr/lib/swift/host \
		-lSwiftCompilerPluginMessageHandling \
		-lSwiftSyntaxMacroExpansion \
		-lSwiftDiagnostics \
		-lSwiftSyntax \
		-lSwiftSyntaxBuilder \
		-lSwiftSyntaxMacros \
		-module-name QMKFirmwareMacros \
		$(EMBEDDED_MACRO_SOURCES) \
		-o $@

$(INTERMEDIATE_OUTPUT)/embedded_qmk_keymap_kit.o: \
        $(EMBEDDED_QMK_KEYMAP_KIT_SOURCES) \
        $(EMBEDDED_MACRO_EXECUTABLE) \
        $(EMBEDDED_SWIFT_BRIDGING_HEADER) \
        $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: QMKKeymapKit Embedded Swift"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) \
		-module-name QMKKeymapKit \
		-emit-module \
		-emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/QMKKeymapKit.swiftmodule \
		-c $(EMBEDDED_QMK_KEYMAP_KIT_SOURCES) \
		-o $@

$(INTERMEDIATE_OUTPUT)/embedded_qmk_firmware_runtime.o: \
        $(EMBEDDED_QMK_FIRMWARE_RUNTIME_SOURCES) \
        $(INTERMEDIATE_OUTPUT)/embedded_qmk_keymap_kit.o \
        $(EMBEDDED_MACRO_EXECUTABLE) \
        $(EMBEDDED_SWIFT_BRIDGING_HEADER) \
        $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: QMKFirmwareRuntime Embedded Swift"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) \
		-module-name QMKFirmwareRuntime \
		-emit-module \
		-emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/QMKFirmwareRuntime.swiftmodule \
		-c $(EMBEDDED_QMK_FIRMWARE_RUNTIME_SOURCES) \
		-o $@

$(INTERMEDIATE_OUTPUT)/embedded_obbut_keymaps.o: \
        $(EMBEDDED_OBBUT_KEYMAP_SOURCES) \
        $(INTERMEDIATE_OUTPUT)/embedded_qmk_firmware_runtime.o \
        $(EMBEDDED_MACRO_EXECUTABLE) \
        $(EMBEDDED_SWIFT_BRIDGING_HEADER) \
        $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: ObbutKeymaps Embedded Swift"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) \
		-module-name ObbutKeymaps \
		-emit-module \
		-emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/ObbutKeymaps.swiftmodule \
		-c $(EMBEDDED_OBBUT_KEYMAP_SOURCES) \
		-o $@

$(INTERMEDIATE_OUTPUT)/embedded_firmware_module.o: \
        $(EMBEDDED_FIRMWARE_SOURCES) \
        $(INTERMEDIATE_OUTPUT)/embedded_obbut_keymaps.o \
        $(EMBEDDED_MACRO_EXECUTABLE) \
        $(EMBEDDED_SWIFT_BRIDGING_HEADER) \
        $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: $(OBBUT_SWIFT_FIRMWARE_MODULE) Embedded Swift"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) \
		-module-name $(OBBUT_SWIFT_FIRMWARE_MODULE) \
		-emit-module \
		-emit-module-path $(EMBEDDED_SWIFT_MODULE_DIR)/$(OBBUT_SWIFT_FIRMWARE_MODULE).swiftmodule \
		-c $(EMBEDDED_FIRMWARE_SOURCES) \
		-o $@

$(INTERMEDIATE_OUTPUT)/embedded_selected_firmware.o: \
        $(EMBEDDED_SELECTED_FIRMWARE_SOURCE) \
        $(INTERMEDIATE_OUTPUT)/embedded_firmware_module.o \
        $(EMBEDDED_MACRO_EXECUTABLE) \
        $(EMBEDDED_SWIFT_BRIDGING_HEADER) \
        $(QMK_USERSPACE)/users/obbut_keymap/rules.mk
	@mkdir -p $(@D) $(EMBEDDED_SWIFT_MODULE_DIR)
	@$(SILENT) || printf "Compiling: FirmwareRuntime<$(OBBUT_SWIFT_FIRMWARE_MODULE)>"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) \
		-D $(OBBUT_SWIFT_FIRMWARE_DEFINE) \
		-module-name ObbutFirmwareExecutable \
		-c $(EMBEDDED_SELECTED_FIRMWARE_SOURCE) \
		-o $@
