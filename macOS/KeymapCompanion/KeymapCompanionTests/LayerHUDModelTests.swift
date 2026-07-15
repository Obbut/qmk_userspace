import Testing
@testable import KeymapCompanion

/// Verifies authored layer metadata controls transient HUD eligibility.
@Test
func authoredLayersControlHUDEligibility() throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let defaultLayer = try #require(definition.supportedLayers.first)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let pointer = try #require(definition.supportedLayers.first { $0.displayName == "Pointer" })

    #expect(!defaultLayer.isHUDLayer)
    #expect(lower.isHUDLayer)
    #expect(!pointer.isHUDLayer)
}

/// Verifies a momentary layer must remain active for the configured dwell time.
@MainActor
@Test
func hudAppearsAfterLayerDwell() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let base = try #require(definition.supportedLayers.first)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let activeMask = UInt32(1 << base.rawValue) | UInt32(1 << lower.rawValue)
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.update(activeLayer: lower, activeLayerMask: activeMask)
    #expect(model.presentation == nil)

    try await Task.sleep(for: .milliseconds(100))
    #expect(model.presentation == LayerHUDPresentation(layer: lower, activeLayerMask: activeMask))
}

/// Verifies identical firmware reports do not restart an in-progress reveal delay.
@MainActor
@Test
func repeatedLayerStateDoesNotRestartHUDDwell() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let lower = try #require(definition.supportedLayers.first { $0.displayName == "Lower" })
    let mask = UInt32(1 << lower.rawValue) | 1
    let model = LayerHUDModel(transitionDelay: .milliseconds(120))

    model.update(activeLayer: lower, activeLayerMask: mask)
    try await Task.sleep(for: .milliseconds(80))
    model.update(activeLayer: lower, activeLayerMask: mask)
    try await Task.sleep(for: .milliseconds(80))

    #expect(model.presentation?.layer == lower)
}

/// Verifies leaving a momentary layer before the reveal delay cancels the HUD.
@MainActor
@Test
func shortLayerHoldDoesNotShowHUD() async throws {
    let definition = KeymapDefinition.makePreview(for: .kyria)
    let base = try #require(definition.supportedLayers.first)
    let raise = try #require(definition.supportedLayers.first { $0.displayName == "Raise" })
    let model = LayerHUDModel(transitionDelay: .milliseconds(80))

    model.update(activeLayer: raise, activeLayerMask: UInt32(1 << raise.rawValue) | 1)
    try await Task.sleep(for: .milliseconds(20))
    model.update(activeLayer: base, activeLayerMask: 1)

    try await Task.sleep(for: .milliseconds(100))
    #expect(model.presentation == nil)
}
