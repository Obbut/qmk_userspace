import QMKKeymapKit

/// The semantic and visual domain shared by the four Obbut firmware modules.
public enum ObbutKeymapDomain: KeymapDomain {
    /// The concrete semantic catalog type.
    public typealias Semantics = SemanticCatalogValue<ObbutSemantic>

    /// The concrete style catalog type.
    public typealias Styles = StyleCatalogValue<ObbutStyle>

    /// Presentation for every Obbut semantic identifier.
    @SemanticCatalogBuilder
    public static var semantics: Semantics {
        QMKKeymapKit.Semantic(ObbutSemantic.screenshot, legend: "Screenshot", symbol: .camera)
        QMKKeymapKit.Semantic(ObbutSemantic.aerospace, legend: "Aerospace", symbol: .windowManagement)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerLeftClick, legend: "Left Click", symbol: .pointerButton)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerRightClick, legend: "Right Click", symbol: .pointerButton)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerMiddleClick, legend: "Middle Click", symbol: .pointerButton)
        QMKKeymapKit.Semantic(ObbutSemantic.browserBack, legend: "Browser Back", symbol: .browserNavigation)
        QMKKeymapKit.Semantic(ObbutSemantic.browserForward, legend: "Browser Forward", symbol: .browserNavigation)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerScroll, legend: "Scroll", symbol: .scroll)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerSniper, legend: "Sniper", symbol: .pointer)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerDragLock, legend: "Drag Lock", symbol: .lockedPointer)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerSensitivityDown, legend: "Pointer −", symbol: .pointer)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerSensitivityUp, legend: "Pointer +", symbol: .pointer)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerScrollSpeedDown, legend: "Scroll −", symbol: .scroll)
        QMKKeymapKit.Semantic(ObbutSemantic.pointerScrollSpeedUp, legend: "Scroll +", symbol: .scroll)
        QMKKeymapKit.Semantic(ObbutSemantic.bluetoothHost1, legend: "Bluetooth 1", symbol: .bluetooth)
        QMKKeymapKit.Semantic(ObbutSemantic.bluetoothHost2, legend: "Bluetooth 2", symbol: .bluetooth)
        QMKKeymapKit.Semantic(ObbutSemantic.bluetoothHost3, legend: "Bluetooth 3", symbol: .bluetooth)
        QMKKeymapKit.Semantic(ObbutSemantic.wireless24GHz, legend: "2.4 GHz", symbol: .wireless)
        QMKKeymapKit.Semantic(ObbutSemantic.batteryLevel, legend: "Battery", symbol: .battery)
    }

    /// Presentation for every Obbut visual-style identifier.
    @StyleCatalogBuilder
    public static var styles: Styles {
        QMKKeymapKit.Style(ObbutStyle.standard, color: .rgb(90, 90, 96))
        QMKKeymapKit.Style(ObbutStyle.gaming, color: .rgb(148, 0, 211))
        QMKKeymapKit.Style(ObbutStyle.navigation, color: .rgb(255, 0, 255))
        QMKKeymapKit.Style(ObbutStyle.number, color: .rgb(0, 0, 255))
        QMKKeymapKit.Style(ObbutStyle.symbol, color: .rgb(255, 255, 0))
        QMKKeymapKit.Style(ObbutStyle.function, color: .rgb(0, 220, 220))
        QMKKeymapKit.Style(ObbutStyle.increase, color: .rgb(0, 255, 0))
        QMKKeymapKit.Style(ObbutStyle.decrease, color: .rgb(0, 50, 0))
        QMKKeymapKit.Style(ObbutStyle.destructive, color: .rgb(255, 128, 0))
        QMKKeymapKit.Style(ObbutStyle.bootloader, color: .rgb(255, 68, 68))
        QMKKeymapKit.Style(ObbutStyle.wireless, color: .rgb(0, 220, 220))
        QMKKeymapKit.Style(ObbutStyle.pointer, color: .rgb(0, 180, 220))
        QMKKeymapKit.Style(ObbutStyle.operatingSystem, color: .rgb(255, 255, 255))
    }
}
