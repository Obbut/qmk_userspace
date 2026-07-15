/// A layer or encoder declaration accepted by a keymap result builder.
public enum KeymapElement<Domain: KeymapDomain>: Sendable {
    /// A complete layer declaration.
    case layer(Layer<Domain>)

    /// A complete encoder declaration.
    case encoder(Encoder<Domain>)
}
