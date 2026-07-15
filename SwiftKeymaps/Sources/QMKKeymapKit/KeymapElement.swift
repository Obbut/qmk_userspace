/// A layer or encoder declaration accepted by a keymap result builder.
public enum KeymapElement<Domain: KeymapDomain>: Sendable {
    case layer(Layer<Domain>)

    case encoder(Encoder<Domain>)
}
