/// One readable, statically typed row of keys.
public struct Row<Content: KeySequence>: KeySequence {
    @usableFromInline internal let content: Content

    /// Creates a row with vertical formatting for longer declarations.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(@KeyRowBuilder content: () -> Content) {
        self.content = content()
    }

    @usableFromInline
    @_alwaysEmitIntoClient
    @inline(__always)
    internal init(content: Content) {
        self.content = content
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var keyCount: Int { content.keyCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func key(at index: Int) -> Key? { content.key(at: index) }
}

extension Row {

    /// Creates a 1-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key) where Content == Key {
        self.init(content: key0)
    }

    /// Creates a 2-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key) where Content == KeySequenceGroup<Key, Key> {
        self.init(content: KeySequenceGroup(key0, key1))
    }

    /// Creates a 3-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key) where Content == KeySequenceGroup<Key, KeySequenceGroup<Key, Key>> {
        self.init(content: KeySequenceGroup(key0, KeySequenceGroup(key1, key2)))
    }

    /// Creates a 4-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key) where Content == KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)))
    }

    /// Creates a 5-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key) where Content == KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))))
    }

    /// Creates a 6-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key) where Content == KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(key3, KeySequenceGroup(key4, key5))))
    }

    /// Creates a 7-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key) where Content == KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(KeySequenceGroup(key3, key4), KeySequenceGroup(key5, key6))))
    }

    /// Creates a 8-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)), KeySequenceGroup(KeySequenceGroup(key4, key5), KeySequenceGroup(key6, key7))))
    }

    /// Creates a 9-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)), KeySequenceGroup(KeySequenceGroup(key4, key5), KeySequenceGroup(key6, KeySequenceGroup(key7, key8)))))
    }

    /// Creates a 10-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))), KeySequenceGroup(KeySequenceGroup(key5, key6), KeySequenceGroup(key7, KeySequenceGroup(key8, key9)))))
    }

    /// Creates a 11-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))), KeySequenceGroup(KeySequenceGroup(key5, KeySequenceGroup(key6, key7)), KeySequenceGroup(key8, KeySequenceGroup(key9, key10)))))
    }

    /// Creates a 12-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(key3, KeySequenceGroup(key4, key5))), KeySequenceGroup(KeySequenceGroup(key6, KeySequenceGroup(key7, key8)), KeySequenceGroup(key9, KeySequenceGroup(key10, key11)))))
    }

    /// Creates a 13-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(key3, KeySequenceGroup(key4, key5))), KeySequenceGroup(KeySequenceGroup(key6, KeySequenceGroup(key7, key8)), KeySequenceGroup(KeySequenceGroup(key9, key10), KeySequenceGroup(key11, key12)))))
    }

    /// Creates a 14-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(KeySequenceGroup(key3, key4), KeySequenceGroup(key5, key6))), KeySequenceGroup(KeySequenceGroup(key7, KeySequenceGroup(key8, key9)), KeySequenceGroup(KeySequenceGroup(key10, key11), KeySequenceGroup(key12, key13)))))
    }

    /// Creates a 15-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(KeySequenceGroup(key3, key4), KeySequenceGroup(key5, key6))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key7, key8), KeySequenceGroup(key9, key10)), KeySequenceGroup(KeySequenceGroup(key11, key12), KeySequenceGroup(key13, key14)))))
    }

    /// Creates a 16-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)), KeySequenceGroup(KeySequenceGroup(key4, key5), KeySequenceGroup(key6, key7))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key8, key9), KeySequenceGroup(key10, key11)), KeySequenceGroup(KeySequenceGroup(key12, key13), KeySequenceGroup(key14, key15)))))
    }

    /// Creates a 17-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)), KeySequenceGroup(KeySequenceGroup(key4, key5), KeySequenceGroup(key6, key7))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key8, key9), KeySequenceGroup(key10, key11)), KeySequenceGroup(KeySequenceGroup(key12, key13), KeySequenceGroup(key14, KeySequenceGroup(key15, key16))))))
    }

    /// Creates a 18-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)), KeySequenceGroup(KeySequenceGroup(key4, key5), KeySequenceGroup(key6, KeySequenceGroup(key7, key8)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key9, key10), KeySequenceGroup(key11, key12)), KeySequenceGroup(KeySequenceGroup(key13, key14), KeySequenceGroup(key15, KeySequenceGroup(key16, key17))))))
    }

    /// Creates a 19-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key, _ key18: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, Key>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, key3)), KeySequenceGroup(KeySequenceGroup(key4, key5), KeySequenceGroup(key6, KeySequenceGroup(key7, key8)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key9, key10), KeySequenceGroup(key11, KeySequenceGroup(key12, key13))), KeySequenceGroup(KeySequenceGroup(key14, key15), KeySequenceGroup(key16, KeySequenceGroup(key17, key18))))))
    }

    /// Creates a 20-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key, _ key18: Key, _ key19: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))), KeySequenceGroup(KeySequenceGroup(key5, key6), KeySequenceGroup(key7, KeySequenceGroup(key8, key9)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key10, key11), KeySequenceGroup(key12, KeySequenceGroup(key13, key14))), KeySequenceGroup(KeySequenceGroup(key15, key16), KeySequenceGroup(key17, KeySequenceGroup(key18, key19))))))
    }

    /// Creates a 21-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key, _ key18: Key, _ key19: Key, _ key20: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))), KeySequenceGroup(KeySequenceGroup(key5, key6), KeySequenceGroup(key7, KeySequenceGroup(key8, key9)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key10, key11), KeySequenceGroup(key12, KeySequenceGroup(key13, key14))), KeySequenceGroup(KeySequenceGroup(key15, KeySequenceGroup(key16, key17)), KeySequenceGroup(key18, KeySequenceGroup(key19, key20))))))
    }

    /// Creates a 22-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key, _ key18: Key, _ key19: Key, _ key20: Key, _ key21: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))), KeySequenceGroup(KeySequenceGroup(key5, KeySequenceGroup(key6, key7)), KeySequenceGroup(key8, KeySequenceGroup(key9, key10)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key11, key12), KeySequenceGroup(key13, KeySequenceGroup(key14, key15))), KeySequenceGroup(KeySequenceGroup(key16, KeySequenceGroup(key17, key18)), KeySequenceGroup(key19, KeySequenceGroup(key20, key21))))))
    }

    /// Creates a 23-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key, _ key18: Key, _ key19: Key, _ key20: Key, _ key21: Key, _ key22: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, Key>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, key1), KeySequenceGroup(key2, KeySequenceGroup(key3, key4))), KeySequenceGroup(KeySequenceGroup(key5, KeySequenceGroup(key6, key7)), KeySequenceGroup(key8, KeySequenceGroup(key9, key10)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key11, KeySequenceGroup(key12, key13)), KeySequenceGroup(key14, KeySequenceGroup(key15, key16))), KeySequenceGroup(KeySequenceGroup(key17, KeySequenceGroup(key18, key19)), KeySequenceGroup(key20, KeySequenceGroup(key21, key22))))))
    }

    /// Creates a 24-key row without allocating an array.
    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ key0: Key, _ key1: Key, _ key2: Key, _ key3: Key, _ key4: Key, _ key5: Key, _ key6: Key, _ key7: Key, _ key8: Key, _ key9: Key, _ key10: Key, _ key11: Key, _ key12: Key, _ key13: Key, _ key14: Key, _ key15: Key, _ key16: Key, _ key17: Key, _ key18: Key, _ key19: Key, _ key20: Key, _ key21: Key, _ key22: Key, _ key23: Key) where Content == KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>, KeySequenceGroup<KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>, KeySequenceGroup<KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>, KeySequenceGroup<Key, KeySequenceGroup<Key, Key>>>>> {
        self.init(content: KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key0, KeySequenceGroup(key1, key2)), KeySequenceGroup(key3, KeySequenceGroup(key4, key5))), KeySequenceGroup(KeySequenceGroup(key6, KeySequenceGroup(key7, key8)), KeySequenceGroup(key9, KeySequenceGroup(key10, key11)))), KeySequenceGroup(KeySequenceGroup(KeySequenceGroup(key12, KeySequenceGroup(key13, key14)), KeySequenceGroup(key15, KeySequenceGroup(key16, key17))), KeySequenceGroup(KeySequenceGroup(key18, KeySequenceGroup(key19, key20)), KeySequenceGroup(key21, KeySequenceGroup(key22, key23))))))
    }
}
