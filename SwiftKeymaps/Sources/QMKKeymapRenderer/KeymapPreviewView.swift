#if canImport(SwiftUI)
import ObbutKeyboardLayouts
import QMKFirmwareHost
import QMKFirmwareRuntime
import SwiftUI

/// Interactive Xcode preview for a firmware definition.
public struct KeymapPreviewView<Firmware: QMKFirmware>: View
where Firmware.Layout: HostFirmwareLayout {
    private let document: KeymapRenderDocument

    @State private var selectedLayerID: UInt8

    @State private var showsAllLayers = true

    /// Uses the same renderer document as the companion applications.
    ///
    /// - Parameter firmware: The firmware definition to preview.
    public init(_ firmware: Firmware.Type) {
        let document = KeymapRenderDocument(firmware: AnyFirmware(firmware))
        self.document = document
        _selectedLayerID = State(initialValue: document.layers.first?.id ?? 0)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.displayName)
                        .font(.title2.bold())
                    Text("QMK keymap")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("All layers", isOn: $showsAllLayers)
                    .toggleStyle(.switch)
                if !showsAllLayers {
                    Picker("Layer", selection: $selectedLayerID) {
                        ForEach(document.layers) { layer in
                            Text(layer.name).tag(layer.id)
                        }
                    }
                    .frame(width: 180)
                }
            }

            if showsAllLayers {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 460), spacing: 16)], spacing: 16) {
                        ForEach(document.layers) { layer in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(layer.name)
                                    .font(.headline)
                                KeymapRendererView(document: document, selectedLayerID: layer.id)
                                    .frame(minHeight: 180)
                            }
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            } else {
                KeymapRendererView(document: document, selectedLayerID: selectedLayerID)
            }
        }
        .padding(20)
        .frame(minWidth: 780, minHeight: 520)
    }
}
#endif
