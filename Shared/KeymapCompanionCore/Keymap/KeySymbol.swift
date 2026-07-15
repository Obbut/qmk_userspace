/// Platform-neutral symbols that native renderers map to their iconography.
public enum KeySymbol: Equatable, Sendable {
    /// A Return or Enter key.
    case returnKey
    /// An Escape key.
    case escape
    /// A backward-delete key.
    case deleteBackward
    /// A Tab key.
    case tab
    /// A Space key.
    case space
    /// A Caps Lock key.
    case capsLock
    /// A forward-delete key.
    case deleteForward
    /// A right-arrow key.
    case arrowRight
    /// A left-arrow key.
    case arrowLeft
    /// A down-arrow key.
    case arrowDown
    /// An up-arrow key.
    case arrowUp
    /// A mute control.
    case mute
    /// A volume-up control.
    case volumeUp
    /// A volume-down control.
    case volumeDown
    /// A next-track control.
    case nextTrack
    /// A previous-track control.
    case previousTrack
    /// A play-or-pause control.
    case playPause
    /// A Control modifier.
    case control
    /// A Shift modifier.
    case shift
    /// An Option or Alt modifier.
    case option
    /// A Command or Windows modifier.
    case command
    /// A screenshot camera.
    case camera
    /// A window-management action.
    case windowManagement
    /// A locked pointer action.
    case lockedPointer
    /// A Bluetooth radio.
    case bluetooth
    /// A battery level.
    case battery
    /// A pointer button.
    case pointerButton
    /// Pointer movement.
    case pointer
    /// Pointer scrolling.
    case scroll
    /// Browser navigation.
    case browserNavigation
    /// A generic wireless radio.
    case wireless
}
