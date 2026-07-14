# Shared rules for Obbut's Halcyon keyboards (Kyria, Elora).

VPATH += $(QMK_USERSPACE)/users/obbut_halcyon
SRC += obbut_halcyon.c
SRC += embedded_keymap_protocol.clib
RAW_ENABLE = yes

EMBEDDED_KEYMAP_PROTOCOL_SOURCES := $(sort $(wildcard $(QMK_USERSPACE)/Shared/KeymapProtocol/*.swift))
EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER := $(QMK_USERSPACE)/users/obbut_halcyon/keymap_protocol_bridge.h
EMBEDDED_SWIFT_FLAGS := \
    -target armv6m-none-none-eabi \
    -enable-experimental-feature Embedded \
    -import-bridging-header $(EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER) \
    -swift-version 6 \
    -warnings-as-errors \
    -whole-module-optimization \
    -parse-as-library \
    -Osize \
    -Xfrontend -function-sections \
    -Xfrontend -disable-stack-protector \
    -Xcc -mcpu=cortex-m0plus \
    -Xcc -mthumb \
    -Xcc -fshort-enums \
    -Xcc -isystem -Xcc /opt/qmk/arm-none-eabi/include \
    -module-name KeymapProtocolEmbedded

$(INTERMEDIATE_OUTPUT)/embedded_keymap_protocol.o: $(EMBEDDED_KEYMAP_PROTOCOL_SOURCES) $(EMBEDDED_KEYMAP_PROTOCOL_BRIDGING_HEADER) $(QMK_USERSPACE)/users/obbut_halcyon/rules.mk
	@mkdir -p $(@D)
	@$(SILENT) || printf "Compiling: Embedded Swift keymap protocol"
	@swiftc $(EMBEDDED_SWIFT_FLAGS) -c $(EMBEDDED_KEYMAP_PROTOCOL_SOURCES) -o $@
