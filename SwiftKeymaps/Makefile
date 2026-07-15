# Direct host build for the macro plugin and qmk-keymapc.
#
# This intentionally does not invoke SwiftPM. Xcode and tests still consume the
# package manifest, while Docker/QMK builds use the compiler's plugin ABI
# directly so the generated firmware path has no package-manager dependency.

SWIFTC ?= swiftc
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR ?= $(ROOT)/.build-direct
BIN_DIR := $(BUILD_DIR)/bin
LIB_DIR := $(BUILD_DIR)/lib
MODULE_DIR := $(BUILD_DIR)/modules

SWIFT_RESOURCE_PATH := $(shell $(SWIFTC) -print-target-info | sed -n 's/.*"runtimeResourcePath" *: *"\([^"]*\)".*/\1/p')
SWIFT_HOST_LIB_DIR ?= $(SWIFT_RESOURCE_PATH)/host
UNAME_S := $(shell uname -s)
SHLIB_EXT := $(if $(filter Darwin,$(UNAME_S)),dylib,so)

PLUGIN := $(BIN_DIR)/QMKKeymapMacrosPlugin
COMPILER := $(BIN_DIR)/qmk-keymapc

QMK_KEYMAP_KIT_SOURCES := $(sort $(wildcard $(ROOT)/Sources/QMKKeymapKit/*.swift))
QMK_FIRMWARE_RUNTIME_SOURCES := $(sort $(wildcard $(ROOT)/Sources/QMKFirmwareRuntime/*.swift))
OBBUT_KEYMAP_SOURCES := $(sort $(wildcard $(ROOT)/Sources/ObbutKeymaps/*.swift))
KYRIA_FIRMWARE_SOURCES := $(sort $(wildcard $(ROOT)/Sources/KyriaFirmware/*.swift))
ELORA_FIRMWARE_SOURCES := $(sort $(wildcard $(ROOT)/Sources/EloraFirmware/*.swift))
Q15_FIRMWARE_SOURCES := $(sort $(wildcard $(ROOT)/Sources/Q15Firmware/*.swift))
PLANCK_FIRMWARE_SOURCES := $(sort $(wildcard $(ROOT)/Sources/PlanckFirmware/*.swift))
OBBUT_CATALOG_SOURCES := $(sort $(wildcard $(ROOT)/Sources/ObbutKeyboardCatalog/*.swift))
COMPILER_SOURCES := $(sort $(wildcard $(ROOT)/Sources/qmk-keymapc/*.swift))
PLUGIN_SOURCES := $(sort $(wildcard $(ROOT)/Sources/QMKKeymapMacrosPlugin/*.swift))

COMMON_SWIFT_FLAGS := \
	-swift-version 6 \
	-warnings-as-errors \
	-enable-experimental-feature StrictConcurrency \
	-parse-as-library \
	-D QMK_DIRECT_HOST_BUILD

MODULE_SWIFT_FLAGS := \
	$(COMMON_SWIFT_FLAGS) \
	-I $(MODULE_DIR) \
	-L $(LIB_DIR) \
	-load-plugin-executable $(PLUGIN)\#QMKKeymapMacrosPlugin

RPATH_FLAGS := -Xlinker -rpath -Xlinker $(LIB_DIR)

QMK_KEYMAP_KIT_LIBRARY := $(LIB_DIR)/libQMKKeymapKit.$(SHLIB_EXT)
QMK_FIRMWARE_RUNTIME_LIBRARY := $(LIB_DIR)/libQMKFirmwareRuntime.$(SHLIB_EXT)
OBBUT_KEYMAP_LIBRARY := $(LIB_DIR)/libObbutKeymaps.$(SHLIB_EXT)
KYRIA_FIRMWARE_LIBRARY := $(LIB_DIR)/libKyriaFirmware.$(SHLIB_EXT)
ELORA_FIRMWARE_LIBRARY := $(LIB_DIR)/libEloraFirmware.$(SHLIB_EXT)
Q15_FIRMWARE_LIBRARY := $(LIB_DIR)/libQ15Firmware.$(SHLIB_EXT)
PLANCK_FIRMWARE_LIBRARY := $(LIB_DIR)/libPlanckFirmware.$(SHLIB_EXT)
OBBUT_CATALOG_LIBRARY := $(LIB_DIR)/libObbutKeyboardCatalog.$(SHLIB_EXT)

.PHONY: all qmk-keymapc generate clean

all: qmk-keymapc

qmk-keymapc: $(COMPILER)

generate: $(COMPILER)
	$(COMPILER) $(ARGS)

$(PLUGIN): $(PLUGIN_SOURCES)
	@mkdir -p $(BIN_DIR)
	$(SWIFTC) $(COMMON_SWIFT_FLAGS) \
		-D QMK_DIRECT_PLUGIN \
		-emit-executable \
		-module-name QMKKeymapMacrosPlugin \
		-I $(SWIFT_HOST_LIB_DIR) \
		-L $(SWIFT_HOST_LIB_DIR) \
		-Xlinker -rpath -Xlinker $(SWIFT_HOST_LIB_DIR) \
		$(PLUGIN_SOURCES) \
		-o $@

$(QMK_KEYMAP_KIT_LIBRARY): $(QMK_KEYMAP_KIT_SOURCES) $(PLUGIN)
	@mkdir -p $(LIB_DIR) $(MODULE_DIR)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name QMKKeymapKit \
		-emit-module-path $(MODULE_DIR)/QMKKeymapKit.swiftmodule \
		$(QMK_KEYMAP_KIT_SOURCES) \
		-o $@

$(QMK_FIRMWARE_RUNTIME_LIBRARY): $(QMK_FIRMWARE_RUNTIME_SOURCES) $(QMK_KEYMAP_KIT_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name QMKFirmwareRuntime \
		-emit-module-path $(MODULE_DIR)/QMKFirmwareRuntime.swiftmodule \
		-lQMKKeymapKit \
		$(QMK_FIRMWARE_RUNTIME_SOURCES) \
		-o $@

$(OBBUT_KEYMAP_LIBRARY): $(OBBUT_KEYMAP_SOURCES) $(QMK_FIRMWARE_RUNTIME_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name ObbutKeymaps \
		-emit-module-path $(MODULE_DIR)/ObbutKeymaps.swiftmodule \
		-lQMKFirmwareRuntime -lQMKKeymapKit \
		$(OBBUT_KEYMAP_SOURCES) \
		-o $@

$(KYRIA_FIRMWARE_LIBRARY): $(KYRIA_FIRMWARE_SOURCES) $(OBBUT_KEYMAP_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name KyriaFirmware \
		-emit-module-path $(MODULE_DIR)/KyriaFirmware.swiftmodule \
		-lObbutKeymaps -lQMKFirmwareRuntime -lQMKKeymapKit \
		$(KYRIA_FIRMWARE_SOURCES) \
		-o $@

$(ELORA_FIRMWARE_LIBRARY): $(ELORA_FIRMWARE_SOURCES) $(OBBUT_KEYMAP_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name EloraFirmware \
		-emit-module-path $(MODULE_DIR)/EloraFirmware.swiftmodule \
		-lObbutKeymaps -lQMKFirmwareRuntime -lQMKKeymapKit \
		$(ELORA_FIRMWARE_SOURCES) \
		-o $@

$(Q15_FIRMWARE_LIBRARY): $(Q15_FIRMWARE_SOURCES) $(OBBUT_KEYMAP_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name Q15Firmware \
		-emit-module-path $(MODULE_DIR)/Q15Firmware.swiftmodule \
		-lObbutKeymaps -lQMKFirmwareRuntime -lQMKKeymapKit \
		$(Q15_FIRMWARE_SOURCES) \
		-o $@

$(PLANCK_FIRMWARE_LIBRARY): $(PLANCK_FIRMWARE_SOURCES) $(OBBUT_KEYMAP_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name PlanckFirmware \
		-emit-module-path $(MODULE_DIR)/PlanckFirmware.swiftmodule \
		-lObbutKeymaps -lQMKFirmwareRuntime -lQMKKeymapKit \
		$(PLANCK_FIRMWARE_SOURCES) \
		-o $@

$(OBBUT_CATALOG_LIBRARY): $(OBBUT_CATALOG_SOURCES) $(KYRIA_FIRMWARE_LIBRARY) $(ELORA_FIRMWARE_LIBRARY) $(Q15_FIRMWARE_LIBRARY) $(PLANCK_FIRMWARE_LIBRARY)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-library -emit-module \
		-module-name ObbutKeyboardCatalog \
		-emit-module-path $(MODULE_DIR)/ObbutKeyboardCatalog.swiftmodule \
		-lKyriaFirmware -lEloraFirmware -lQ15Firmware -lPlanckFirmware \
		-lObbutKeymaps -lQMKFirmwareRuntime -lQMKKeymapKit \
		$(OBBUT_CATALOG_SOURCES) \
		-o $@

$(COMPILER): $(COMPILER_SOURCES) $(OBBUT_CATALOG_LIBRARY)
	@mkdir -p $(BIN_DIR)
	$(SWIFTC) $(MODULE_SWIFT_FLAGS) \
		-emit-executable \
		-module-name qmk_keymapc \
		-lObbutKeyboardCatalog \
		-lKyriaFirmware -lEloraFirmware -lQ15Firmware -lPlanckFirmware \
		-lObbutKeymaps -lQMKFirmwareRuntime -lQMKKeymapKit \
		$(RPATH_FLAGS) \
		$(COMPILER_SOURCES) \
		-o $@

clean:
	rm -rf $(BUILD_DIR)
