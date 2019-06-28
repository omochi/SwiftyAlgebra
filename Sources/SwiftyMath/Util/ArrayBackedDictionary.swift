import Foundation

public struct ArrayBackedDictionary<Key, Value>
    where Key : Equatable
{
    @usableFromInline
    internal struct Entry {
        public var key: Key
        public var value: Value
        public init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    private var entries: [Entry]
    
    @inlinable
    public init() {
        self.init(entries: [])
    }
    
    public init<S>(_ keyAndValues: S) where S : Sequence, S.Element == (Key, Value) {
        self.init()
        for pair in keyAndValues {
            self[pair.0] = pair.1
        }
    }
    
    @inlinable
    public init(_ keyValuePairs: KeyValuePairs<Key, Value>) {
        self.init(keyValuePairs.lazy.map { $0 })
    }

    @usableFromInline
    internal init(entries: [Entry]) {
        self.entries = entries
    }
    
    public var count: Int { return entries.count }
    
    public subscript(key: Key) -> Value? {
        get {
            guard let index = index(for: key) else { return nil }
            return entries[index].value
        }
        set {
            guard let newValue = newValue else {
                if let index = index(for: key) {
                    entries.remove(at: index)
                }
                return
            }
            
            if let index = index(for: key) {
                entries[index].value = newValue
            } else {
                entries.append(Entry(key: key, value: newValue))
            }
        }
    }
    
    private func index(for key: Key) -> Int? {
        return entries.firstIndex { $0.key == key }
    }
}

// standard extensions
extension ArrayBackedDictionary {
    public var keys: [Key] {
        return entries.map { $0.key }
    }
    
    @inlinable
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            return self[key] ?? defaultValue()
        }
        set {
            self[key] = newValue
        }
    }
    
    public func mapValues<NewValue>(_ transform: (Value) throws -> NewValue) rethrows -> ArrayBackedDictionary<Key, NewValue> {
        let newEntries: [ArrayBackedDictionary<Key, NewValue>.Entry] = try entries.map { (e) in
            let key: Key = e.key
            let newValue: NewValue = try transform(e.value)
            return ArrayBackedDictionary<Key, NewValue>.Entry(key: key, value: newValue)
        }
        return ArrayBackedDictionary<Key, NewValue>(entries: newEntries)
    }
    
    public mutating func merge(_ other: ArrayBackedDictionary<Key, Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        for (k, v2) in other {
            if let index = self.index(for: k) {
                let v1 = self.entries[index].value
                let v = try combine(v1, v2)
                self.entries[index].value = v
            } else {
                self.entries.append(Entry(key: k, value: v2))
            }
        }
    }
}

extension ArrayBackedDictionary : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements)
    }
}

extension ArrayBackedDictionary : Sequence {
    public typealias Element = (key: Key, value: Value)
    
    public struct Iterator : IteratorProtocol {
        public let storage: ArrayBackedDictionary<Key, Value>
        private var index: Int
        public init(storage: ArrayBackedDictionary<Key, Value>) {
            self.storage = storage
            self.index = 0
        }
        
        public mutating func next() -> ArrayBackedDictionary<Key, Value>.Element? {
            guard index < storage.entries.count else {
                return nil
            }
            let ent = storage.entries[index]
            index += 1
            return (key: ent.key, value: ent.value)
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(storage: self)
    }
}

extension ArrayBackedDictionary.Entry : Equatable where Value : Equatable {}

extension ArrayBackedDictionary : Equatable where Value : Equatable {}

// user extensions
extension ArrayBackedDictionary {
    public func mapKeys<NewKey>(_ transform: (Key) throws -> NewKey) rethrows -> ArrayBackedDictionary<NewKey, Value> {
        let elements = try self.map { (k, v) in (try transform(k), v) }
        return ArrayBackedDictionary<NewKey, Value>(elements)
    }
    
    public mutating func merge(_ other: ArrayBackedDictionary<Key, Value>, overwrite: Bool = false) {
        self.merge(other, uniquingKeysWith: { (v1, v2) in !overwrite ? v1 : v2 })
    }
}
