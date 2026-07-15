#if canImport(SwiftUI)
import SwiftUI

/// The production SwiftUI renderer shared by applications and Xcode previews.
public struct KeymapRendererView: View {
    /// The platform-neutral keymap document.
    private let document: KeymapRenderDocument

    /// The selected QMK layer identifier.
    private let selectedLayerID: UInt8

    /// Creates a production keymap renderer.
    ///
    /// - Parameters:
    ///   - document: The complete renderer document.
    ///   - selectedLayerID: The layer to display.
    public init(document: KeymapRenderDocument, selectedLayerID: UInt8) {
        self.document = document
        self.selectedLayerID = selectedLayerID
    }

    /// The rendered keyboard diagram.
    public var body: some View {
        KeyboardDiagramView(document: document, selectedLayerID: selectedLayerID)
            .aspectRatio(document.canvasWidth / document.canvasHeight, contentMode: .fit)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(document.displayName) keymap")
    }
}
#endif
