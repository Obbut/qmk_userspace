/// A layer or encoder declaration accepted by a keymap result builder.
public enum KeymapElement: Sendable {
    case layer(Layer)

    case encoder(Encoder)
}
