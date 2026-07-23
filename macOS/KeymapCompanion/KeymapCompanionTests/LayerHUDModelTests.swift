import Testing
@testable import KeymapCompanion

/// Verifies layer metadata controls transient HUD eligibility.
@Test
func layerMetadataControlsHUDEligibility() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let defaultLayer = try #require(definition.supportedLayers.first)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let pointer = try #require(definition.supportedLayers.first { $0.displayName == "Pointer" })

    #expect(!defaultLayer.isHUDLayer)
    #expect(lower.isHUDLayer)
    #expect(!pointer.isHUDLayer)
}

/// Verifies state reports cannot reveal a hidden HUD.
@MainActor
@Test
func layerStateDoesNotRevealHUD() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let base = try #require(definition.supportedLayers.first)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let activeMask = UInt32(1 << base.rawValue) | UInt32(1 << lower.rawValue)
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.update(activeLayer: lower, activeLayerMask: activeMask)
    #expect(model.presentation == nil)

    try await Task.sleep(for: .milliseconds(100))
    #expect(model.presentation == nil)
}

/// Verifies a firmware trigger reveals an eligible layer immediately.
@MainActor
@Test
func firmwareTriggerRevealsHUDImmediately() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let mask = UInt32(1 << lower.rawValue) | 1
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.present(activeLayer: lower, activeLayerMask: mask)

    #expect(model.presentation == LayerHUDPresentation(layer: lower, activeLayerMask: mask))
}

/// Verifies a non-HUD layer cannot be revealed even by a trigger.
@MainActor
@Test
func firmwareTriggerCannotRevealPointerLayer() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let pointer = try #require(definition.supportedLayers.first { $0.displayName == "Pointer" })
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.present(
        activeLayer: pointer,
        activeLayerMask: UInt32(1 << pointer.rawValue) | 1
    )

    #expect(model.presentation == nil)
}

/// Verifies state changes update an already visible eligible HUD without hiding it.
@MainActor
@Test
func visibleHUDRemainsVisibleOnEligibleLayerState() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let raise = try #require(definition.supportedLayers.first { $0.displayName == "Raise" })
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.present(activeLayer: lower, activeLayerMask: UInt32(1 << lower.rawValue) | 1)
    model.update(activeLayer: raise, activeLayerMask: UInt32(1 << raise.rawValue) | 1)

    #expect(model.presentation?.layer == raise)
}

/// Verifies leaving an eligible layer retains the existing delayed dismissal.
@MainActor
@Test
func visibleHUDHidesAfterBaseLayerDelay() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let base = try #require(definition.supportedLayers.first)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.present(activeLayer: lower, activeLayerMask: UInt32(1 << lower.rawValue) | 1)
    model.update(activeLayer: base, activeLayerMask: 1)

    #expect(model.presentation?.layer == base)
    try await Task.sleep(for: .milliseconds(100))
    #expect(model.presentation == nil)
}
