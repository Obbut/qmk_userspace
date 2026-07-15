import SwiftUI

/// A native toolbar item that presents the connected keyboard's base-layer RGB settings.
struct RGBSettingsPopoverButton: View {
    /// Shared process-lifetime app state.
    let model: AppModel

    /// Whether the settings popover is currently presented.
    @State private var isPresented = false

    /// The system-styled toolbar button and its anchored settings popover.
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("RGB Settings", systemImage: "lightbulb.led.fill")
        }
        .help("Base-layer RGB settings")
        .disabled(!model.supportsRGBSettings)
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            RGBSettingsView(model: model)
        }
    }
}

/// Base-layer lighting controls shown by the toolbar popover.
private struct RGBSettingsView: View {
    /// Shared state used to read and write the keyboard configuration.
    let model: AppModel

    /// The popover sections.
    var body: some View {
        @Bindable var model = model

        VStack(alignment: .leading, spacing: 16) {
            RGBSettingsHeader(
                isEnabled: $model.rgbSettings.isEnabled,
                color: model.rgbSettings.color
            )

            Divider()

            RGBSettingsControls(model: model)
        }
        .padding(18)
        .frame(width: 390)
    }
}

/// The popover title, color swatch, and RGB power switch.
private struct RGBSettingsHeader: View {
    /// Whether RGB Matrix output is enabled.
    @Binding var isEnabled: Bool

    /// The current native color-picker value.
    let color: CGColor

    /// The title row.
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(cgColor: color).gradient)
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
            }
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Base Layer RGB")
                    .font(.headline)
                Text("Live keyboard lighting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Enabled", isOn: $isEnabled)
                .toggleStyle(.switch)
        }
    }
}

/// Effect, color, brightness, and speed controls.
private struct RGBSettingsControls: View {
    /// Shared state used to update the keyboard configuration.
    let model: AppModel

    /// The aligned native controls.
    var body: some View {
        @Bindable var model = model

        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("Effect")
                    .gridColumnAlignment(.trailing)

                Picker(selection: $model.rgbSettings.effect) {
                    ForEach(RGBEffect.allCases) { effect in
                        Text(effect.localizedDisplayName)
                            .tag(effect)
                    }
                } label: {
                    Text("Effect")
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 230, alignment: .leading)
            }

            GridRow {
                Text("Color")

                ColorPicker(
                    "Color",
                    selection: $model.rgbSettings.color,
                    supportsOpacity: false
                )
                .labelsHidden()
            }

            GridRow {
                Text("Brightness")

                RGBPercentageSlider(
                    value: $model.rgbSettings.normalizedBrightness,
                    accessibilityLabel: "Brightness"
                )
                .frame(width: 230)
            }

            GridRow {
                Text("Speed")

                RGBPercentageSlider(
                    value: $model.rgbSettings.normalizedSpeed,
                    accessibilityLabel: "Speed"
                )
                .frame(width: 230)
            }
        }
        .disabled(!model.rgbSettings.isEnabled)
    }
}

/// A native slider paired with a compact localized percentage value.
private struct RGBPercentageSlider: View {
    /// The normalized value from zero through one.
    @Binding var value: Double

    /// The VoiceOver description for the unlabeled slider.
    let accessibilityLabel: LocalizedStringResource

    /// The slider and its current percentage.
    var body: some View {
        HStack(spacing: 8) {
            Slider(value: $value, in: 0...1)
                .accessibilityLabel(Text(accessibilityLabel))

            Text(value, format: .percent.precision(.fractionLength(0)))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .trailing)
        }
    }
}

#if DEBUG
    #Preview("RGB Toolbar Item") {
        let model = AppModel.makePreview(
            layoutID: .kyria,
            rgbSettings: RGBSettings(
                isEnabled: true,
                effect: .rainbowBeacon,
                hue: 210,
                saturation: 220,
                brightness: 112,
                speed: 127
            )
        )

        RGBSettingsPopoverButton(model: model)
            .padding()
    }

    #Preview("RGB Settings Popover") {
        RGBSettingsView(
            model: .makePreview(
                layoutID: .elora,
                rgbSettings: RGBSettings(
                    isEnabled: true,
                    effect: .rainbowLeftToRight,
                    hue: 196,
                    saturation: 230,
                    brightness: 104,
                    speed: 127
                )
            )
        )
    }

    #Preview("RGB Settings Popover Dark") {
        RGBSettingsView(
            model: .makePreview(
                layoutID: .kyria,
                rgbSettings: RGBSettings(
                    isEnabled: true,
                    effect: .breathing,
                    hue: 142,
                    saturation: 238,
                    brightness: 92,
                    speed: 127
                )
            )
        )
        .preferredColorScheme(.dark)
    }

    #Preview("RGB Settings Header") {
        RGBSettingsHeader(
            isEnabled: .constant(true),
            color: RGBSettings.default.color
        )
        .padding()
        .frame(width: 340)
    }

    #Preview("RGB Settings Controls") {
        RGBSettingsControls(model: .makePreview())
            .padding()
            .frame(width: 390)
    }

    #Preview("RGB Percentage Slider") {
        @Previewable @State var value = 0.68

        RGBPercentageSlider(
            value: $value,
            accessibilityLabel: "Brightness"
        )
        .padding()
        .frame(width: 280)
    }
#endif
