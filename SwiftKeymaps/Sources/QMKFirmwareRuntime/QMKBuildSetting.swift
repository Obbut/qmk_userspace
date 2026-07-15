/// One generated QMK Makefile or configuration-header setting.
public enum QMKBuildSetting: Equatable, Sendable {
    /// A `rules.mk` variable assignment.
    case make(variable: String, value: String)

    /// A C preprocessor definition in `config.h`.
    case define(name: String, value: String?)

    /// A C preprocessor undefinition in `config.h`.
    case undefine(name: String)

    /// A generated configuration-header include.
    case include(path: String)

    /// A QMK C or Embedded Swift source registered with Make.
    case source(path: String)
}
