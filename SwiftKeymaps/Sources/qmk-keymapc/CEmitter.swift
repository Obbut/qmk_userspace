import QMKFirmwareRuntime

/// Emits QMK ABI artifacts from one domain-erased Swift firmware definition.
struct CEmitter {
    /// The firmware being emitted.
    let firmware: AnyFirmware

    /// Creates every generated artifact for the firmware.
    ///
    /// - Returns: The complete generated artifact set.
    func artifacts() -> GeneratedArtifacts {
        GeneratedArtifacts(
            keymapC: keymapC(),
            configH: configH(),
            rulesMK: rulesMK(),
            metadataH: metadataH(),
            keymapDrawerYAML: KeymapDrawerEmitter(firmware: firmware).yaml()
        )
    }

    /// Creates the complete QMK keymap translation unit.
    private func keymapC() -> String {
        let forkInclude = isQ15 ? "\n#include \"keychron_common.h\"" : ""
        return """
        // Generated from Swift by qmk-keymapc. Do not edit.
        // SPDX-License-Identifier: GPL-2.0-or-later

        #include QMK_KEYBOARD_H\(forkInclude)
        #include "keymap.generated.h"
        #include "keymap_protocol_bridge.h"

        \(featureDeclarations())
        \(customKeycodeEnumeration())
        \(layerEnumeration())
        \(keymapArray())
        \(encoderArray())
        \(metadataArrays())
        \(metadataFunctions())
        \(firmwareCallbacks())
        """
    }

    /// Creates declarations for custom feature bridges and Embedded Swift hooks.
    private func featureDeclarations() -> String {
        let authoredDeclarations = firmware.features.descriptors.flatMap(\.cDeclarations)
        let hookDeclarations = embeddedSwiftHooks.map { hook in
            switch hook.callback {
            case .keyboardPostInit, .housekeeping, .pointingDeviceInit:
                return "void \(hook.symbol)(void);"
            case .processRecord:
                return "uint8_t \(hook.symbol)(uint16_t keycode, uint8_t pressed);"
            case .layerStateSet:
                return "uint32_t \(hook.symbol)(uint32_t state);"
            case .pointingDeviceTask:
                return "void \(hook.symbol)(int8_t *x, int8_t *y, int8_t *h, int8_t *v, uint8_t *buttons);"
            case .rgbMatrixIndicatorsAdvanced:
                return "uint8_t \(hook.symbol)(uint8_t led_min, uint8_t led_max);"
            case .rawHIDReceive:
                return "void \(hook.symbol)(uint8_t *data, uint8_t length);"
            }
        }
        return (authoredDeclarations + hookDeclarations).joined(separator: "\n")
    }

    /// Creates the generated layer enumeration.
    private func layerEnumeration() -> String {
        let cases = firmware.layers.map { "    \($0.id.cIdentifier) = \($0.id.rawValue)," }
        return "enum obbut_generated_layers {\n\(cases.joined(separator: "\n"))\n};"
    }

    /// Creates custom pointer keycodes used by the Halcyon behavior runtime.
    private func customKeycodeEnumeration() -> String {
        guard isHalcyon else { return "" }
        return """
        enum obbut_generated_custom_keycodes {
            PTR_SCROLL = SAFE_RANGE,
            PTR_SNIPER,
            PTR_DRAG_LOCK,
            PTR_SENS_DOWN,
            PTR_SENS_UP,
            PTR_SCROLL_DOWN,
            PTR_SCROLL_UP,
        };
        """
    }

    /// Creates the QMK keymap array.
    private func keymapArray() -> String {
        let layers = firmware.layers.map { layer in
            """
                [\(layer.id.cIdentifier)] = \(layoutCall(values: layer.keys.map(\.cExpression)))
            """
        }
        return """
        // clang-format off
        const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
        \(layers.joined(separator: ",\n"))
        };
        // clang-format on
        """
    }

    /// Creates all encoder actions in layer-major order.
    private func encoderArray() -> String {
        guard !firmware.encoders.isEmpty else { return "" }
        let rows = firmware.layers.map { layer in
            let mappings = firmware.encoders.compactMap { encoder in
                encoder.mappings.first { $0.layer == layer.id }
            }
            let values: [String]
            if isHalcyon, let mapping = mappings.first {
                let value = encoderPair(mapping)
                values = Array(repeating: value, count: 4)
            } else {
                values = mappings.map(encoderPair)
            }
            return "    [\(layer.id.cIdentifier)] = { \(values.joined(separator: ", ")) }"
        }
        return """
        #if defined(ENCODER_MAP_ENABLE)
        const uint16_t PROGMEM encoder_map[][NUM_ENCODERS][NUM_DIRECTIONS] = {
        \(rows.joined(separator: ",\n"))
        };
        #endif
        """
    }

    /// Creates one QMK encoder-pair macro invocation.
    private func encoderPair(_ mapping: AnyFirmwareEncoderMapping) -> String {
        "ENCODER_CCW_CW(\(mapping.counterclockwise.cExpression), \(mapping.clockwise.cExpression))"
    }

    /// Creates the generated semantic and style matrix tables.
    private func metadataArrays() -> String {
        let semanticLayers = firmware.layers.map { layer in
            let values = layer.keys.map { String($0.semanticID ?? 0) }
            return "    [\(layer.id.cIdentifier)] = \(layoutCall(values: values))"
        }
        let styleLayers = firmware.layers.map { layer in
            let values = layer.keys.map { String($0.styleID ?? 0) }
            return "    [\(layer.id.cIdentifier)] = \(layoutCall(values: values))"
        }
        return """
        const uint16_t PROGMEM obbut_generated_semantics[][MATRIX_ROWS][MATRIX_COLS] = {
        \(semanticLayers.joined(separator: ",\n"))
        };

        const uint16_t PROGMEM obbut_generated_styles[][MATRIX_ROWS][MATRIX_COLS] = {
        \(styleLayers.joined(separator: ",\n"))
        };
        \(encoderMetadataArrays())
        """
    }

    /// Creates encoder semantic and style metadata tables when encoders are present.
    private func encoderMetadataArrays() -> String {
        guard !firmware.encoders.isEmpty else { return "" }
        let semanticRows = firmware.layers.map { layer in
            let pairs = firmware.encoders.map { encoder -> String in
                guard let mapping = encoder.mappings.first(where: { $0.layer == layer.id }) else {
                    return "{ 0, 0 }"
                }
                return "{ \(mapping.counterclockwise.semanticID ?? 0), \(mapping.clockwise.semanticID ?? 0) }"
            }
            return "    [\(layer.id.cIdentifier)] = { \(pairs.joined(separator: ", ")) }"
        }
        let styleRows = firmware.layers.map { layer in
            let pairs = firmware.encoders.map { encoder -> String in
                guard let mapping = encoder.mappings.first(where: { $0.layer == layer.id }) else {
                    return "{ 0, 0 }"
                }
                return "{ \(mapping.counterclockwise.styleID ?? 0), \(mapping.clockwise.styleID ?? 0) }"
            }
            return "    [\(layer.id.cIdentifier)] = { \(pairs.joined(separator: ", ")) }"
        }
        return """
        const uint16_t PROGMEM obbut_generated_encoder_semantics[][OBBUT_GENERATED_ENCODER_COUNT][2] = {
        \(semanticRows.joined(separator: ",\n"))
        };

        const uint16_t PROGMEM obbut_generated_encoder_styles[][OBBUT_GENERATED_ENCODER_COUNT][2] = {
        \(styleRows.joined(separator: ",\n"))
        };
        """
    }

    /// Creates the narrow metadata functions used by protocol v4 and lighting.
    private func metadataFunctions() -> String {
        let encoderFunctions: String
        if firmware.encoders.isEmpty {
            encoderFunctions = """
            uint16_t obbut_generated_encoder_keycode_at(uint8_t layer, uint8_t encoder, uint8_t direction) {
                (void)layer; (void)encoder; (void)direction;
                return KC_NO;
            }
            uint16_t obbut_generated_encoder_semantic_at(uint8_t layer, uint8_t encoder, uint8_t direction) {
                (void)layer; (void)encoder; (void)direction;
                return 0;
            }
            uint16_t obbut_generated_encoder_style_at(uint8_t layer, uint8_t encoder, uint8_t direction) {
                (void)layer; (void)encoder; (void)direction;
                return 0;
            }
            """
        } else {
            encoderFunctions = """
            uint16_t obbut_generated_encoder_keycode_at(uint8_t layer, uint8_t encoder, uint8_t direction) {
                if (layer >= OBBUT_GENERATED_LAYER_COUNT || encoder >= OBBUT_GENERATED_ENCODER_COUNT || direction > 1) return KC_NO;
                return pgm_read_word(&encoder_map[layer][encoder][direction]);
            }
            uint16_t obbut_generated_encoder_semantic_at(uint8_t layer, uint8_t encoder, uint8_t direction) {
                if (layer >= OBBUT_GENERATED_LAYER_COUNT || encoder >= OBBUT_GENERATED_ENCODER_COUNT || direction > 1) return 0;
                return pgm_read_word(&obbut_generated_encoder_semantics[layer][encoder][direction]);
            }
            uint16_t obbut_generated_encoder_style_at(uint8_t layer, uint8_t encoder, uint8_t direction) {
                if (layer >= OBBUT_GENERATED_LAYER_COUNT || encoder >= OBBUT_GENERATED_ENCODER_COUNT || direction > 1) return 0;
                return pgm_read_word(&obbut_generated_encoder_styles[layer][encoder][direction]);
            }
            """
        }
        return """
        uint16_t obbut_generated_semantic_at(uint8_t layer, uint8_t row, uint8_t column) {
            if (layer >= OBBUT_GENERATED_LAYER_COUNT || row >= MATRIX_ROWS || column >= MATRIX_COLS) return 0;
            return pgm_read_word(&obbut_generated_semantics[layer][row][column]);
        }

        uint16_t obbut_generated_style_at(uint8_t layer, uint8_t row, uint8_t column) {
            if (layer >= OBBUT_GENERATED_LAYER_COUNT || row >= MATRIX_ROWS || column >= MATRIX_COLS) return 0;
            return pgm_read_word(&obbut_generated_styles[layer][row][column]);
        }

        \(encoderFunctions)
        """
    }

    /// Creates board-specific QMK callback bridges.
    private func firmwareCallbacks() -> String {
        if isHalcyon { return halcyonCallbacks() }
        if isQ15 { return q15Callbacks() }
        return planckCallbacks()
    }

    /// Creates callbacks into the shared Obbut Embedded Swift behavior engine.
    private func halcyonCallbacks() -> String {
        """
        static uint8_t obbut_generated_key_kind(uint16_t keycode) {
            switch (keycode) {
                case PTR_SCROLL: return 1;
                case PTR_SNIPER: return 2;
                case PTR_DRAG_LOCK: return 3;
                case PTR_SENS_DOWN: return 4;
                case PTR_SENS_UP: return 5;
                case PTR_SCROLL_DOWN: return 6;
                case PTR_SCROLL_UP: return 7;
                case MS_BTN1: return 8;
                case MS_BTN2: return 9;
                case MS_BTN3: return 10;
                case KC_WBAK: return 11;
                case KC_WFWD: return 12;
                case RM_TOGG:
                case RM_NEXT:
                case RM_PREV:
                case RM_HUEU:
                case RM_HUED:
                case RM_SATU:
                case RM_SATD:
                case RM_VALU:
                case RM_VALD:
                    return 20;
                case KC_KB_VOLUME_UP: return 30;
                case KC_KB_VOLUME_DOWN: return 31;
                case LGUI(LCTL(LSFT(KC_4))): return 32;
                case KC_LCTL: return 33;
                case KC_LGUI: return 34;
                default:
                    if ((keycode >= KC_LEFT_CTRL && keycode <= KC_RIGHT_GUI) ||
                        (keycode >= QK_MODS && keycode <= QK_MODS_MAX)) return 40;
                    return 0;
            }
        }

        static bool obbut_generated_is_windows(void) { return obbut_platform_is_windows() != 0; }

        void keyboard_post_init_user(void) {
            obbut_swift_post_init(obbut_firmware_profile());
        \(hookCalls(.keyboardPostInit))
        }
        void housekeeping_task_user(void) {
            obbut_swift_housekeeping();
        \(hookCalls(.housekeeping))
        #if defined(RAW_ENABLE)
            if (obbut_platform_is_keyboard_master()) keymap_protocol_housekeeping();
        #endif
        }
        bool process_record_user(uint16_t keycode, keyrecord_t *record) {
        \(filteringHookCalls(.processRecord, arguments: "keycode, record->event.pressed ? 1 : 0"))
            return obbut_swift_process_record(
                obbut_generated_key_kind(keycode),
                record->event.pressed ? 1 : 0
            ) != 0;
        }
        layer_state_t layer_state_set_user(layer_state_t state) {
        \(transformingHookCalls(.layerStateSet, value: "state"))
            return (layer_state_t)obbut_swift_layer_state_changed((uint32_t)state);
        }
        #if defined(RAW_ENABLE)
        void raw_hid_receive(uint8_t *data, uint8_t length) {
        \(hookCalls(.rawHIDReceive, arguments: "data, length"))
            if (obbut_platform_is_keyboard_master()) keymap_protocol_receive(data, length);
        }
        #endif

        #if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
        bool is_mouse_record_user(uint16_t keycode, keyrecord_t *record) {
            (void)record;
            uint8_t kind = obbut_generated_key_kind(keycode);
            return kind >= 1 && kind <= 12;
        }
        #endif

        #if defined(POINTING_DEVICE_ENABLE)
        void pointing_device_init_user(void) {
            obbut_swift_pointing_device_init();
        \(hookCalls(.pointingDeviceInit))
        }
        report_mouse_t pointing_device_task_user(report_mouse_t report) {
            obbut_swift_transform_pointer(
                &report.x, &report.y, &report.h, &report.v, &report.buttons,
                layer_state_is(_LOWER) ? 1 : 0
            );
        \(hookCalls(.pointingDeviceTask, arguments: "&report.x, &report.y, &report.h, &report.v, &report.buttons"))
            return report;
        }
        #endif
        \(rgbCallback(
            baseLayers: ["_DEFAULT"],
            overlaysBaseRGBOn: "_QWERTY",
            includesOSIndicator: true,
            includesPointerState: isKyria
        ))
        """
    }

    /// Creates Q15 callback bridges and style-catalog-driven lighting.
    private func q15Callbacks() -> String {
        """
        void keyboard_post_init_user(void) {
            (void)obbut_firmware_profile();
        \(hookCalls(.keyboardPostInit))
        }
        bool process_record_user(uint16_t keycode, keyrecord_t *record) {
        \(filteringHookCalls(.processRecord, arguments: "keycode, record->event.pressed ? 1 : 0"))
            return process_record_keychron_common(keycode, record);
        }
        #if defined(RAW_ENABLE)
        void housekeeping_task_user(void) {
        \(hookCalls(.housekeeping))
            keymap_protocol_housekeeping();
        }
        void __real_raw_hid_receive(uint8_t *data, uint8_t length);
        void __wrap_raw_hid_receive(uint8_t *data, uint8_t length) {
        \(hookCalls(.rawHIDReceive, arguments: "data, length"))
            if (length >= 5 && data[0] == 0x4B && data[1] == 0x4D && data[2] == 0x41 && data[3] == 0x50 && data[4] == 4) {
                keymap_protocol_receive(data, length);
                return;
            }
            __real_raw_hid_receive(data, length);
        }
        #endif
        \(nonHalcyonCustomCallbacks())
        \(rgbCallback(baseLayers: ["MAC_BASE", "WIN_BASE"], overlaysBaseRGBOn: nil, includesOSIndicator: false))
        """
    }

    /// Creates Planck platform overrides, LEDs, protocol callbacks, and lighting.
    private func planckCallbacks() -> String {
        let screenshotSemanticID = firmware.semantics.first { $0.legend == "Screenshot" }?.id
        let screenshot = firmware.layers
            .flatMap(\.keys)
            .first { $0.semanticID == screenshotSemanticID }?
            .cExpression ?? "KC_PSCR"
        return """
        void keyboard_post_init_user(void) {
            (void)obbut_firmware_profile();
            planck_ez_right_led_level(255 / 4);
            planck_ez_left_led_level(255 / 4);
            planck_ez_left_led_off();
            planck_ez_right_led_off();
        \(hookCalls(.keyboardPostInit))
        }

        static bool obbut_generated_is_windows(void) { return detected_host_os() == OS_WINDOWS; }

        bool process_record_user(uint16_t keycode, keyrecord_t *record) {
        \(filteringHookCalls(.processRecord, arguments: "keycode, record->event.pressed ? 1 : 0"))
            if (!obbut_generated_is_windows()) return true;
            switch (keycode) {
                case \(screenshot):
                    if (record->event.pressed) register_code(KC_PSCR); else unregister_code(KC_PSCR);
                    return false;
                case KC_LCTL:
                    if (record->event.pressed) register_code(KC_LGUI); else unregister_code(KC_LGUI);
                    return false;
                case KC_LGUI:
                    if (record->event.pressed) register_code(KC_LCTL); else unregister_code(KC_LCTL);
                    return false;
            }
            return true;
        }
        \(commonProtocolCallbacks())
        \(nonHalcyonCustomCallbacks())
        \(rgbCallback(baseLayers: ["_DEFAULT"], overlaysBaseRGBOn: "_QWERTY", includesOSIndicator: true))
        """
    }

    /// Creates protocol-v4 callback bridges for non-Halcyon boards.
    private func commonProtocolCallbacks() -> String {
        """
        #if defined(RAW_ENABLE)
        void housekeeping_task_user(void) {
        \(hookCalls(.housekeeping))
            keymap_protocol_housekeeping();
        }
        void raw_hid_receive(uint8_t *data, uint8_t length) {
        \(hookCalls(.rawHIDReceive, arguments: "data, length"))
            keymap_protocol_receive(data, length);
        }
        #endif
        """
    }

    /// Creates optional state and pointer callbacks for non-Halcyon custom hooks.
    private func nonHalcyonCustomCallbacks() -> String {
        var callbacks: [String] = []
        if embeddedSwiftHooks.contains(where: { $0.callback == .layerStateSet }) {
            callbacks.append(
                """
                layer_state_t layer_state_set_user(layer_state_t state) {
                \(transformingHookCalls(.layerStateSet, value: "state"))
                    return state;
                }
                """
            )
        }
        let hasPointingInitialization = embeddedSwiftHooks.contains {
            $0.callback == .pointingDeviceInit
        }
        let hasPointingTask = embeddedSwiftHooks.contains {
            $0.callback == .pointingDeviceTask
        }
        if hasPointingInitialization || hasPointingTask {
            callbacks.append(
                """
                #if defined(POINTING_DEVICE_ENABLE)
                void pointing_device_init_user(void) {
                \(hookCalls(.pointingDeviceInit))
                }
                report_mouse_t pointing_device_task_user(report_mouse_t report) {
                \(hookCalls(.pointingDeviceTask, arguments: "&report.x, &report.y, &report.h, &report.v, &report.buttons"))
                    return report;
                }
                #endif
                """
            )
        }
        return callbacks.joined(separator: "\n")
    }

    /// Creates style-catalog-driven RGB Matrix indicators.
    private func rgbCallback(
        baseLayers: [String],
        overlaysBaseRGBOn overlayLayer: String?,
        includesOSIndicator: Bool,
        includesPointerState: Bool = false
    ) -> String {
        let baseCondition = baseLayers.map { "layer == \($0)" }.joined(separator: " || ")
        let clearCondition = overlayLayer.map { "layer != \($0)" } ?? "true"
        let osIndicator = includesOSIndicator ? """
                    if (layer == _FUNCTION && style == 0) {
                        keypos_t position = {.row = row, .col = column};
                        uint16_t base_keycode = keymap_key_to_keycode(_DEFAULT, position);
                        uint16_t os_keycode = obbut_generated_is_windows() ? KC_LCTL : KC_LGUI;
                        if (base_keycode == os_keycode) rgb_matrix_set_color(led_index, 255, 255, 255);
                    }
        """ : ""
        let pointerPreparation = includesPointerState ? """
            if (layer == _FUNCTION && obbut_swift_rgb_preview_mode()) return false;
            if (layer == _POINTER) {
                for (uint8_t index = led_min; index < led_max; index++) {
                    if (obbut_swift_pointer_drag_lock_active()) {
                        rgb_matrix_set_color(index, 48, 0, 0);
                    } else {
                        rgb_matrix_set_color(index, 0, 24, 32);
                    }
                }
            } else if (\(clearCondition)) {
                for (uint8_t index = led_min; index < led_max; index++) rgb_matrix_set_color(index, RGB_OFF);
            }
        """ : """
            if (\(clearCondition)) {
                for (uint8_t index = led_min; index < led_max; index++) rgb_matrix_set_color(index, RGB_OFF);
            }
        """
        let pointerDragLockSemanticID = firmware.semantics.first {
            $0.legend == "Drag Lock"
        }?.id ?? 0
        let pointerDragLock = includesPointerState ? """
                    uint16_t semantic = obbut_generated_semantic_at(layer, row, column);
                    if (layer == _POINTER && semantic == \(pointerDragLockSemanticID) && !obbut_swift_pointer_drag_lock_active()) {
                        rgb_matrix_set_color(led_index, 255, 128, 0);
                        continue;
                    }
        """ : ""
        let colorCases = firmware.styles.filter { $0.id != 0 }.map { style in
            "        case \(style.id): rgb_matrix_set_color(led_index, \(style.color.red), \(style.color.green), \(style.color.blue)); break;"
        }.joined(separator: "\n")
        return """
        #if defined(RGB_MATRIX_ENABLE)
        static void obbut_generated_set_style_color(uint8_t led_index, uint16_t style) {
            switch (style) {
        \(colorCases)
                default: break;
            }
        }

        bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
        \(filteringHookCalls(.rgbMatrixIndicatorsAdvanced, arguments: "led_min, led_max", returnsWhenFalse: false))
            uint8_t layer = get_highest_layer(layer_state);
            if (\(baseCondition)) return false;
        \(pointerPreparation)
            for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
                for (uint8_t column = 0; column < MATRIX_COLS; column++) {
                    uint8_t led_index = g_led_config.matrix_co[row][column];
                    if (led_index < led_min || led_index >= led_max || led_index == NO_LED) continue;
                    uint16_t style = obbut_generated_style_at(layer, row, column);
        \(pointerDragLock)
                    obbut_generated_set_style_color(led_index, style);
        \(osIndicator)
                }
            }
            return false;
        }
        #endif
        """
    }

    /// All custom Embedded Swift hooks in feature declaration order.
    private var embeddedSwiftHooks: [EmbeddedSwiftHook] {
        firmware.features.descriptors.flatMap(\.embeddedSwiftHooks)
    }

    /// Creates statement calls for hooks with no return-value composition.
    private func hookCalls(_ callback: EmbeddedSwiftCallback, arguments: String = "") -> String {
        embeddedSwiftHooks.filter { $0.callback == callback }.map { hook in
            "    \(hook.symbol)(\(arguments));"
        }.joined(separator: "\n")
    }

    /// Creates short-circuiting calls for Boolean callback hooks.
    private func filteringHookCalls(
        _ callback: EmbeddedSwiftCallback,
        arguments: String,
        returnsWhenFalse: Bool = true
    ) -> String {
        embeddedSwiftHooks.filter { $0.callback == callback }.map { hook in
            if returnsWhenFalse {
                return "    if (!\(hook.symbol)(\(arguments))) return false;"
            }
            return "    if (\(hook.symbol)(\(arguments))) return true;"
        }.joined(separator: "\n")
    }

    /// Creates ordered state-transform calls for a value-returning hook.
    private func transformingHookCalls(_ callback: EmbeddedSwiftCallback, value: String) -> String {
        embeddedSwiftHooks.filter { $0.callback == callback }.map { hook in
            "    \(value) = \(hook.symbol)(\(value));"
        }.joined(separator: "\n")
    }

    /// Creates one formatted QMK layout macro invocation.
    private func layoutCall(values: [String]) -> String {
        let chunks = stride(from: 0, to: values.count, by: 12).map { start -> String in
            let end = min(start + 12, values.count)
            return "        " + values[start..<end].joined(separator: ", ")
        }
        return "\(firmware.layout.cMacro)(\n\(chunks.joined(separator: ",\n"))\n    )"
    }

    /// Creates the generated configuration header.
    private func configH() -> String {
        let lines = firmware.buildSettings.compactMap { setting -> String? in
            switch setting {
            case let .define(name, value):
                return value.map { "#define \(name) \($0)" } ?? "#define \(name)"
            case let .undefine(name):
                return "#undef \(name)"
            case let .include(path):
                return "#include \"\(path)\""
            case .make, .source:
                return nil
            }
        }
        return """
        // Generated from Swift by qmk-keymapc. Do not edit.
        // SPDX-License-Identifier: GPL-2.0-or-later
        #pragma once

        \(lines.joined(separator: "\n"))
        """
    }

    /// Creates the generated QMK Make fragment.
    private func rulesMK() -> String {
        var lines = firmware.buildSettings.compactMap { setting -> String? in
            switch setting {
            case let .make(variable, value):
                if variable.hasSuffix(" +") {
                    return "\(variable.dropLast(2)) += \(value)"
                }
                return "\(variable) = \(value)"
            case let .source(path):
                return "SRC += \(path)"
            case .define, .undefine, .include:
                return nil
            }
        }
        lines.append("OBBUT_SWIFT_FIRMWARE_MODULE = \(embeddedFirmwareModule)")
        if isHalcyon {
            lines.append("OBBUT_EMBEDDED_OBBUT_RUNTIME = yes")
            lines.append("include $(QMK_USERSPACE)/users/obbut_halcyon/rules.mk")
        } else {
            lines.append("include $(QMK_USERSPACE)/users/obbut_keymap/rules.mk")
        }
        return """
        # Generated from Swift by qmk-keymapc. Do not edit.
        \(lines.joined(separator: "\n"))
        """
    }

    /// Creates the generated C header consumed by protocol v4.
    private func metadataH() -> String {
        """
        // Generated from Swift by qmk-keymapc. Do not edit.
        // SPDX-License-Identifier: GPL-2.0-or-later
        #pragma once
        #include <stdint.h>

        #define OBBUT_GENERATED_LAYOUT_ID \(firmware.layoutID)
        #define OBBUT_GENERATED_LAYER_COUNT \(firmware.layers.count)
        #define OBBUT_GENERATED_ENCODER_COUNT \(firmware.encoders.count)
        #define OBBUT_GENERATED_SEMANTIC_CATALOG_FINGERPRINT \(firmware.semanticCatalogFingerprint)u
        #define OBBUT_GENERATED_STYLE_CATALOG_FINGERPRINT \(firmware.styleCatalogFingerprint)u

        uint16_t obbut_generated_semantic_at(uint8_t layer, uint8_t row, uint8_t column);
        uint16_t obbut_generated_style_at(uint8_t layer, uint8_t row, uint8_t column);
        uint16_t obbut_generated_encoder_keycode_at(uint8_t layer, uint8_t encoder, uint8_t direction);
        uint16_t obbut_generated_encoder_semantic_at(uint8_t layer, uint8_t encoder, uint8_t direction);
        uint16_t obbut_generated_encoder_style_at(uint8_t layer, uint8_t encoder, uint8_t direction);
        """
    }

    /// Whether this is one of the two Halcyon layouts.
    private var isHalcyon: Bool {
        firmware.layout.id.hasPrefix("splitkb.halcyon")
    }

    /// Whether this is the Kyria layout with its pointer layer.
    private var isKyria: Bool {
        firmware.layout.id.hasPrefix("splitkb.halcyon.kyria")
    }

    /// Whether this is the Keychron Q15 layout.
    private var isQ15: Bool {
        firmware.layout.id.hasPrefix("keychron.q15")
    }

    /// The selected third-stage Embedded Swift firmware module.
    private var embeddedFirmwareModule: String {
        if firmware.layout.id.hasPrefix("splitkb.halcyon.kyria") { return "KyriaFirmware" }
        if firmware.layout.id.hasPrefix("splitkb.halcyon.elora") { return "EloraFirmware" }
        if isQ15 { return "Q15Firmware" }
        return "PlanckFirmware"
    }
}
