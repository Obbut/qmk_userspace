import Testing
@testable import KeymapCompanion

/// Verifies only momentary layers are eligible for the overlay.
@Test
func persistentLayersAreNotHUDLayers() {
    #expect(!KeymapLayer.base.isHUDLayer)
    #expect(!KeymapLayer.qwerty.isHUDLayer)
    #expect(KeymapLayer.lower.isHUDLayer)
    #expect(KeymapLayer.raise.isHUDLayer)
    #expect(KeymapLayer.function.isHUDLayer)
}

/// Verifies a momentary layer must remain active for the configured dwell time.
@MainActor
@Test
func hudAppearsAfterLayerDwell() async throws {
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))
    let activeMask = UInt32(1 << KeymapLayer.base.rawValue)
        | UInt32(1 << KeymapLayer.lower.rawValue)

    model.update(activeLayer: .lower, activeLayerMask: activeMask)
    #expect(model.presentation == nil)

    try await Task.sleep(for: .milliseconds(100))
    #expect(
        model.presentation == LayerHUDPresentation(
            layer: .lower,
            activeLayerMask: activeMask
        )
    )
}

/// Verifies identical firmware reports do not restart an in-progress reveal delay.
@MainActor
@Test
func repeatedLayerStateDoesNotRestartHUDDwell() async throws {
    let model = LayerHUDModel(transitionDelay: .milliseconds(120))

    model.update(activeLayer: .lower, activeLayerMask: 0b0_0101)
    try await Task.sleep(for: .milliseconds(80))
    model.update(activeLayer: .lower, activeLayerMask: 0b0_0101)
    try await Task.sleep(for: .milliseconds(80))

    #expect(model.presentation?.layer == .lower)
}

/// Verifies leaving a momentary layer before the reveal delay cancels the HUD.
@MainActor
@Test
func shortLayerHoldDoesNotShowHUD() async throws {
    let model = LayerHUDModel(transitionDelay: .milliseconds(80))

    model.update(activeLayer: .raise, activeLayerMask: 0b0_1001)
    try await Task.sleep(for: .milliseconds(20))
    model.update(activeLayer: .base, activeLayerMask: 0b0_0001)

    try await Task.sleep(for: .milliseconds(100))
    #expect(model.presentation == nil)
}

/// Verifies the current persistent keymap remains visible during the hide delay.
@MainActor
@Test
func hudHidesAfterPersistentLayerDwell() async throws {
    let model = LayerHUDModel(transitionDelay: .milliseconds(20))

    model.update(activeLayer: .function, activeLayerMask: 0b1_0001)
    try await Task.sleep(for: .milliseconds(100))
    model.update(activeLayer: .qwerty, activeLayerMask: 0b0_0011)

    #expect(
        model.presentation == LayerHUDPresentation(
            layer: .qwerty,
            activeLayerMask: 0b0_0011
        )
    )
    try await Task.sleep(for: .milliseconds(100))
    #expect(model.presentation == nil)
}

/// Verifies returning to a momentary layer cancels a pending dismissal.
@MainActor
@Test
func momentaryLayerCancelsPendingHide() async throws {
    let model = LayerHUDModel(transitionDelay: .milliseconds(30))

    model.update(activeLayer: .lower, activeLayerMask: 0b0_0101)
    try await Task.sleep(for: .milliseconds(100))
    model.update(activeLayer: .base, activeLayerMask: 0b0_0001)
    #expect(model.presentation?.layer == .base)
    try await Task.sleep(for: .milliseconds(10))
    model.update(activeLayer: .raise, activeLayerMask: 0b0_1001)

    try await Task.sleep(for: .milliseconds(50))
    #expect(model.presentation?.layer == .raise)
}
