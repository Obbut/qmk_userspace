#if canImport(SwiftUI)
import SwiftUI

/// The production SwiftUI renderer shared by applications and Xcode previews.
public struct KeymapRendererView: View {
    private let document: KeymapRenderDocument

    private let selectedLayerID: UInt8

    /// Renders one layer from a platform-neutral keymap document.
    ///
    /// - Parameters:
    ///   - document: The keyboard geometry and per-layer legends.
    ///   - selectedLayerID: The layer to display.
    public init(document: KeymapRenderDocument, selectedLayerID: UInt8) {
        self.document = document
        self.selectedLayerID = selectedLayerID
    }

    public var body: some View {
        KeyboardDiagramView(document: document, selectedLayerID: selectedLayerID)
            .aspectRatio(document.canvasWidth / document.canvasHeight, contentMode: .fit)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(document.displayName) keymap")
    }
}
#endif
