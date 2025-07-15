
protocol Clonable: AnyObject {
    func clone() -> Self
}

@dynamicMemberLookup
struct CoW<C> where C: Clonable {
    private var value: C

    init(value: C) {
        self.value = value
    }

    subscript<U>(dynamicMember keyPath: KeyPath<C, U>) -> U {
        get {
            self.value[keyPath: keyPath]
        }
    }

    subscript<U>(dynamicMember keyPath: WritableKeyPath<C, U>) -> U {
        get {
            self.value[keyPath: keyPath]
        }
        mutating set(newValue) {
            if !isKnownUniquelyReferenced(&self.value) {
                self.value = value.clone()
            }
            self.value[keyPath: keyPath] = newValue
        }
    }
}
