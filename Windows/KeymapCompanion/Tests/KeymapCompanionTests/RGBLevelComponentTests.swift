import KeymapCompanionCore
import Testing
@testable import KeymapCompanion

/// Verifies the lighting flyout can move brightness away from its maximum value.
@Test
func brightnessDecrementChangesSettings() {
    var settings = RGBSettings.default

    RGBLevelComponent.brightness.decrease(in: &settings)

    #expect(settings.brightness == RGBSettings.maximumBrightness - 8)
    #expect(settings.normalizedBrightness < 1)
}
