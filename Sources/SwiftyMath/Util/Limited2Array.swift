import Foundation

public struct Limited2Array<Element> {
    internal enum State {
        case _0
        case _1(Element)
        case _2(Element, Element)
    }
    
    internal var state: State
    
    internal init(state: State) {
        self.state = state
    }
    
    public init() {
        self.init(state: ._0)
    }
    
    public init<S>(_ s: S) where S: Sequence, S.Element == Element {
        switch s.count {
        case 0:
            self.init(state: ._0)
        case 1:
            var it = s.makeIterator()
            self.init(state: ._1(it.next()!))
        case 2:
            var it = s.makeIterator()
            self.init(state: ._2(it.next()!, it.next()!))
        default:
            preconditionFailure("too large")
        }
    }
    
    public var count: Int {
        switch state {
        case ._0: return 0
        case ._1: return 1
        case ._2: return 2
        }
    }
    
    public subscript(index: Int) -> Element {
        get {
            switch state {
            case ._0: preconditionFailure("out of range")
            case ._1(let e0):
                guard index == 0 else { preconditionFailure("out of range") }
                return e0
            case ._2(let e0, let e1):
                switch index {
                case 0: return e0
                case 1: return e1
                default: preconditionFailure("out of range")
                }
            }
        }
        set {
            switch state {
            case ._0: preconditionFailure("out of range")
            case ._1:
                guard index == 0 else { preconditionFailure("out of range") }
                self.state = ._1(newValue)
            case ._2(let e0, let e1):
                switch index {
                case 0: self.state = ._2(newValue, e1)
                case 1: self.state = ._2(e0, newValue)
                default: preconditionFailure("out of range")
                }
            }
        }
    }
}

extension Limited2Array : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension Limited2Array : Sequence {
    public struct Iterator : IteratorProtocol {
        public var array: Limited2Array<Element>
        public var index: Int
        public init(_ array: Limited2Array<Element>) {
            self.array = array
            self.index = 0
        }
        public mutating func next() -> Element? {
            guard index < array.count else { return nil }
            let e = array[index]
            index += 1
            return e
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}
