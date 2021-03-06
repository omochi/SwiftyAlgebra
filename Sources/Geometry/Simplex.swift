//
//  Simplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/03.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct Simplex: GeometricCell {
    public   let vertices: [Vertex] // ordered list of vertices.
    internal let vSet: Set<Vertex>  // unordered set of vertices.
    internal let id: String
    
    public init<S: Sequence>(_ vs: S) where S.Iterator.Element == Vertex {
        let vertices = vs.sorted()
        let vSet = Set(vertices)
        assert(vertices.count == vSet.count)
        
        self.vertices = vertices
        self.vSet = vSet
        self.id = "(\(self.vertices.map{$0.description}.joined(separator: ", ")))"
    }
    
    public init<S: Sequence>(_ V: VertexSet, indices: S) where S.Iterator.Element == Int {
        let vertices = indices.map{ V.vertex(at: $0) }
        self.init(vertices)
    }
    
    public init(_ vs: Vertex...) {
        self.init(vs)
    }
    
    public init(_ V: VertexSet, indices: Int...) {
        self.init(V, indices: indices)
    }
    
    public var dim: Int {
        return vertices.count - 1
    }
    
    public func index(ofVertex v: Vertex) -> Int? {
        return vertices.index(of: v)
    }
    
    public func face(_ index: Int) -> Simplex {
        var vs = vertices
        vs.remove(at: index)
        return Simplex(vs)
    }
    
    public func faces() -> [Simplex] {
        if dim == 0 {
            return []
        } else {
            return (0 ... dim).map{ face($0) }
        }
    }
    
    public func contains(_ v: Vertex) -> Bool {
        return vSet.contains(v)
    }
    
    public func contains(_ s: Simplex) -> Bool {
        return s.vSet.isSubset(of: self.vSet)
    }
    
    public func allSubsimplices() -> [Simplex] {
        var queue = [self]
        var i = 0
        while(i < queue.count) {
            let s = queue[i]
            if s.dim > 0 {
                queue += queue[i].faces()
            }
            i += 1
        }
        return queue.unique()
    }
    
    public func join(_ s: Simplex) -> Simplex {
        return Simplex(self.vSet.union(s.vSet))
    }
    
    public func subtract(_ s: Simplex) -> Simplex {
        return Simplex(self.vSet.subtracting(s.vSet))
    }
    
    public func subtract(_ v: Vertex) -> Simplex {
        return Simplex(self.vSet.subtracting([v]))
    }
    
    public func boundary<R: Ring>() -> SimplicialChain<R> {
        let values: [(R, Simplex)] = faces().enumerated().map { (i, t) -> (R, Simplex) in
            let e = R(intValue: (-1).pow(i))
            return (e, t)
        }
        return SimplicialChain(values)
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
    
    public var description: String {
        return id
    }
    
    public static func ==(a: Simplex, b: Simplex) -> Bool {
        return a.id == b.id // should be `a.verticesSet == b.verticesSet` but for performance.
    }
}

public extension Vertex {
    public func join(_ s: Simplex) -> Simplex {
        return Simplex([self] + s.vertices)
    }
    
    public func join<R>(_ chain: SimplicialChain<R>) -> SimplicialChain<R> {
        return SimplicialChain(chain.basis.map{ (s) -> (R, Simplex) in
            let t = self.join(s)
            let e = R(intValue: (-1).pow(t.vertices.index(of: self)!))
            return (e * chain[s], t)
        })
    }
}

public typealias SimplicialChain<R: Ring>   = FreeModule<R, Simplex>
public typealias SimplicialCochain<R: Ring> = FreeModule<R, Dual<Simplex>>

public extension SimplicialChain where A == Simplex {
    public func boundary() -> SimplicialChain<R> {
        return self.reduce(SimplicialChain<R>.zero) { (res, next) -> SimplicialChain<R> in
            let (s, r) = next
            return res + r * s.boundary()
        }
    }
    
    public func cap(_ d: SimplicialCochain<R>) -> SimplicialChain<R> {
        typealias C = SimplicialChain<R>
        
        return self.reduce(C.zero) { (res, next) -> C in
            let (s, r1) = next
            let eval = d.reduce(C.zero) { (res, next) -> C in
                let (f, r2) = next
                let (i, j) = (s.dim, f.base.dim)
                assert(i >= j)
                
                let (s1, s2) = (Simplex(s.vertices[0 ... j]), Simplex(s.vertices[j ... i]))
                if s1 == f.base {
                    let e = R(intValue: (-1).pow(s1.dim * s2.dim))
                    return res + e * r2 * SimplicialChain<R>(s2)
                } else {
                    return res
                }
            }
            return res + r1 * eval
        }
    }
}

public extension SimplicialCochain where A == Dual<Simplex> {
    public func cup(_ f: SimplicialCochain<R>) -> SimplicialCochain<R> {
        typealias D = Dual<Simplex>
        let pairs = self.basis.allCombinations(with: f.basis)
        let elements: [(R, D)] = pairs.flatMap{ (d1, d2) -> (R, D)? in
            let (s1, s2) = (d1.base, d2.base)
            let (n1, n2) = (s1.dim, s2.dim)
            
            let s = Simplex(s1.vSet.union(s2.vSet))
            if (s1.vertices.last! == s2.vertices.first!) && (s.vertices == s1.vertices + s2.vertices.dropFirst()) {
                let e = R(intValue: (-1).pow(n1 * n2))
                return (e * self[d1] * f[d2], Dual(s))
            } else {
                return nil
            }
        }
        return SimplicialCochain<R>(elements)
    }
    
    public func cap(_ z: SimplicialChain<R>) -> SimplicialChain<R> {
        return z.cap(self)
    }
}

public func ∩<R>(a: SimplicialChain<R>, b: SimplicialCochain<R>) -> SimplicialChain<R> {
    return a.cap(b)
}

public func ∩<R>(a: SimplicialCochain<R>, b: SimplicialChain<R>) -> SimplicialChain<R> {
    return a.cap(b)
}

public func ∪<R>(a: SimplicialCochain<R>, b: SimplicialCochain<R>) -> SimplicialCochain<R> {
    return a.cup(b)
}

