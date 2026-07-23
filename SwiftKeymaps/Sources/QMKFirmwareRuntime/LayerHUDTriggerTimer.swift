/// Allocation-free firmware timing for one layer-HUD reveal cycle.
struct LayerHUDTriggerTimer: Sendable {
    /// The required idle interval before firmware authorizes HUD presentation.
    static let revealDelayMilliseconds: UInt32 = 3_000

    /// Layers whose highest-active state may arm the reveal timer.
    private var eligibleLayerMask: UInt32 = 0

    /// The momentary layer mask most recently observed by housekeeping.
    private var observedLayerStateMask: UInt32 = 0

    /// The most recent activation or key-down timestamp.
    private var lastActivityTimestamp: UInt32 = 0

    /// Whether the current highest momentary layer is HUD-eligible.
    private var isArmed = false

    /// Whether the current layer-state cycle already emitted its trigger.
    private var hasTriggered = false

    /// Sets the firmware-derived mask of HUD-eligible layers.
    ///
    /// - Parameter eligibleLayerMask: Layers marked `showsHUD` by keymap metadata.
    mutating func configure(eligibleLayerMask: UInt32) {
        self.eligibleLayerMask = eligibleLayerMask
        observedLayerStateMask = 0
        lastActivityTimestamp = 0
        isArmed = false
        hasTriggered = false
    }

    /// Observes current QMK momentary layer state and starts a new timing cycle on change.
    ///
    /// - Parameters:
    ///   - layerStateMask: The current nonpersistent QMK layer-state mask.
    ///   - timestamp: The current wraparound QMK millisecond timestamp.
    mutating func observe(layerStateMask: UInt32, at timestamp: UInt32) {
        guard layerStateMask != observedLayerStateMask else { return }
        observedLayerStateMask = layerStateMask
        lastActivityTimestamp = timestamp
        isArmed = highestLayerIsEligible(in: layerStateMask)
        hasTriggered = false
    }

    /// Restarts an armed reveal delay for one key-down event.
    ///
    /// - Parameter timestamp: The current wraparound QMK millisecond timestamp.
    mutating func recordKeyDown(at timestamp: UInt32) {
        guard isArmed, !hasTriggered else { return }
        lastActivityTimestamp = timestamp
    }

    /// Consumes a reveal trigger when the armed layer has remained idle long enough.
    ///
    /// - Parameter timestamp: The current wraparound QMK millisecond timestamp.
    /// - Returns: Whether firmware should emit one layer-HUD trigger now.
    mutating func takeTriggerIfReady(at timestamp: UInt32) -> Bool {
        guard isArmed,
            !hasTriggered,
            timestamp &- lastActivityTimestamp >= Self.revealDelayMilliseconds
        else {
            return false
        }
        hasTriggered = true
        return true
    }

    /// Returns whether the highest momentary layer is included in the eligible mask.
    ///
    /// - Parameter layerStateMask: The nonpersistent QMK layer-state mask.
    /// - Returns: Whether the layer state should arm the timer.
    private func highestLayerIsEligible(in layerStateMask: UInt32) -> Bool {
        guard layerStateMask != 0 else { return false }
        let highestLayer = UInt32(31 - layerStateMask.leadingZeroBitCount)
        return eligibleLayerMask & (UInt32(1) << highestLayer) != 0
    }
}
