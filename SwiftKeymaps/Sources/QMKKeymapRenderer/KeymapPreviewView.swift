#if canImport(SwiftUI)
import QMKFirmwareRuntime
import SwiftUI

/// Interactive Xcode preview for one authored firmware type.
public struct KeymapPreviewView<Firmware: QMKFirmware>: View {
    /// Renderer input produced directly from the firmware type.
    private let document: KeymapRenderDocument

    /// The layer selected by the interactive preview control.
    @State private var selectedLayerID: UInt8

    /// Whether every layer is shown as an overview.
    @State private var showsAllLayers = true

    /// Creates an interactive production-renderer preview.
    ///
    /// - Parameter firmware: The authored firmware type.
    public init(_ firmware: Firmware.Type) {
        let document = KeymapRenderDocument(firmware: AnyFirmware(firmware))
        self.document = document
        _selectedLayerID = State(initialValue: document.layers.first?.id ?? 0)
    }

    /// The all-layers overview and interactive layer selector.
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.displayName)
                        .font(.title2.bold())
                    Text("Swift-authored QMK keymap")
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
