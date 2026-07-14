import Observation

/// Delays layer-HUD presentation changes without coupling them to AppKit.
@MainActor
@Observable
final class LayerHUDModel {
    /// The layer snapshot currently rendered by the overlay, or `nil` while hidden.
    private(set) var presentation: LayerHUDPresentation?

    /// The dwell time required to show or hide the overlay.
    @ObservationIgnored private let transitionDelay: Duration

    /// The currently scheduled show or hide operation.
    @ObservationIgnored private var transitionTask: Task<Void, Never>?

    /// The latest eligible layer snapshot waiting for its show delay.
    @ObservationIgnored private var pendingPresentation: LayerHUDPresentation?

    /// Whether the visible HUD is waiting for its hide delay.
    @ObservationIgnored private var isHidePending = false

    /// Creates delayed HUD state.
    /// - Parameter transitionDelay: The dwell time before either visibility change.
    init(transitionDelay: Duration = .seconds(3)) {
        self.transitionDelay = transitionDelay
    }

    /// Responds to a validated firmware layer-state change.
    /// - Parameters:
    ///   - activeLayer: The highest effective layer.
    ///   - activeLayerMask: The complete effective QMK layer stack.
    func update(activeLayer: KeymapLayer, activeLayerMask: UInt32) {
        let nextPresentation = LayerHUDPresentation(
            layer: activeLayer,
            activeLayerMask: activeLayerMask
        )

        guard activeLayer.isHUDLayer else {
            scheduleHideIfNeeded(showing: nextPresentation)
            return
        }

        if presentation != nil {
            cancelPendingTransition()
            presentation = nextPresentation
            return
        }

        if pendingPresentation?.layer == activeLayer {
            pendingPresentation = nextPresentation
            return
        }

        cancelPendingTransition()
        pendingPresentation = nextPresentation
        scheduleShow(for: activeLayer)
    }

    /// Removes the overlay immediately when its keyboard state is no longer valid.
    func hideImmediately() {
        cancelPendingTransition()
        presentation = nil
    }

    /// Starts a show delay tied to one specific momentary layer.
    /// - Parameter layer: The layer that must remain active until the delay expires.
    private func scheduleShow(for layer: KeymapLayer) {
        let delay = transitionDelay
        transitionTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }

            guard let self,
                  let pendingPresentation = self.pendingPresentation,
                  pendingPresentation.layer == layer else { return }
            self.transitionTask = nil
            self.pendingPresentation = nil
            self.presentation = pendingPresentation
        }
    }

    /// Shows the current persistent layer while starting its hide delay.
    /// - Parameter currentPresentation: The latest complete keyboard layer state.
    private func scheduleHideIfNeeded(
        showing currentPresentation: LayerHUDPresentation
    ) {
        pendingPresentation = nil

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

    /// Cancels a pending visibility change and clears its bookkeeping.
    private func cancelPendingTransition() {
        transitionTask?.cancel()
        transitionTask = nil
        pendingPresentation = nil
        isHidePending = false
    }
}
