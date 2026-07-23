import Observation

/// A trigger-driven layer-HUD state machine with delayed dismissal.
@MainActor
@Observable
public final class LayerHUDModel {
    /// The layer snapshot currently rendered by the overlay, or `nil` while hidden.
    public private(set) var presentation: LayerHUDPresentation?

    /// The dwell time required to hide the overlay.
    @ObservationIgnored private let transitionDelay: Duration

    /// The currently scheduled hide operation.
    @ObservationIgnored private var transitionTask: Task<Void, Never>?

    /// Whether the visible HUD is waiting for its hide delay.
    @ObservationIgnored private var isHidePending = false

    /// Creates a layer HUD state machine.
    ///
    /// - Parameter transitionDelay: The dwell time required to hide the overlay.
    public init(transitionDelay: Duration = .seconds(3)) {
        self.transitionDelay = transitionDelay
    }

    /// Updates or dismisses a visible HUD after a validated firmware state change.
    ///
    /// State changes never reveal a hidden HUD.
    ///
    /// - Parameters:
    ///   - activeLayer: The highest currently active layer.
    ///   - activeLayerMask: The bit mask of active and default firmware layers.
    public func update(activeLayer: KeymapLayer, activeLayerMask: UInt32) {
        let nextPresentation = LayerHUDPresentation(
            layer: activeLayer,
            activeLayerMask: activeLayerMask
        )

        guard presentation != nil else {
            cancelPendingTransition()
            return
        }

        if activeLayer.isHUDLayer {
            cancelPendingTransition()
            presentation = nextPresentation
            return
        }

        scheduleHideIfNeeded(showing: nextPresentation)
    }

    /// Reveals the HUD immediately for a firmware-authorized eligible layer.
    ///
    /// - Parameters:
    ///   - activeLayer: The highest currently active layer.
    ///   - activeLayerMask: The bit mask of active and default firmware layers.
    public func present(activeLayer: KeymapLayer, activeLayerMask: UInt32) {
        guard activeLayer.isHUDLayer else { return }
        cancelPendingTransition()
        presentation = LayerHUDPresentation(
            layer: activeLayer,
            activeLayerMask: activeLayerMask
        )
    }

    /// Removes the overlay immediately when its keyboard state is no longer valid.
    public func hideImmediately() {
        cancelPendingTransition()
        presentation = nil
    }

    /// Schedules the visible HUD to hide after showing a base-layer snapshot.
    ///
    /// - Parameter currentPresentation: The latest base-layer snapshot.
    private func scheduleHideIfNeeded(showing currentPresentation: LayerHUDPresentation) {
        guard presentation != nil else {
            cancelPendingTransition()
            return
        }
        presentation = currentPresentation
        guard !isHidePending else { return }

        cancelPendingTransition()
        isHidePending = true
        let delay = transitionDelay
        transitionTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }

            guard let self, self.isHidePending else { return }
            self.transitionTask = nil
            self.isHidePending = false
            self.presentation = nil
        }
    }

    /// Cancels the scheduled hide operation.
    private func cancelPendingTransition() {
        transitionTask?.cancel()
        transitionTask = nil
        isHidePending = false
    }
}
