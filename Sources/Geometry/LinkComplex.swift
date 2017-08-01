//
//  DualComplex.swift
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/07/15.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation

public struct LinkCell: GeometricCell {
    public let dim: Int
    public let base: Simplex
    public let chain: SimplicialChain<IntegerNumber>
    
    public init(dim: Int, base: Simplex, chain: SimplicialChain<IntegerNumber>) {
        self.dim = dim
        self.base = base
        self.chain = chain
    }
    
    public init(dim: Int, base: Simplex, components: [Simplex]) {
        let chain = { () -> SimplicialChain<IntegerNumber> in
            let V = base.vertices[0].vertexSet
            
            if dim > 1 {
                let Lk = SimplicialComplex(V, maximalCells:components, lowerBound: dim - 2)
                guard let z = Lk.preferredOrientation() else {
                    fatalError("invalid link-cell. base: \(base), components: \(components)")
                }
                return z
                
            } else if dim == 1 {
                guard components.count == 2 else {
                    fatalError("invalid link-cell. base: \(base), components: \(components)")
                }
                
                return SimplicialChain<IntegerNumber>(basis: components, components: [-1, 1])
                
            } else {
                let e = Simplex(V, []) // dim = -1
                return SimplicialChain<IntegerNumber>(e)
            }
        }()
        
        self.init(dim: dim, base: base, chain: chain)
    }
    
    public var hashValue: Int {
        return base.hashValue
    }
    
    public var description: String {
        return "lk\(base)"
    }
    
    public var debugDescription: String {
//        return "lk\(base) : \(chain)"
        return description
    }
    
    public static func ==(a: LinkCell, b: LinkCell) -> Bool {
        return a.base == b.base
    }
}

public final class LinkComplex: GeometricComplex {
    public typealias Cell = LinkCell
    
    internal let K: SimplicialComplex
    internal let cells: [[Cell]] // [0: [0-dim cells], 1: [1-dim cells], ...]
    
    // root initializer
    public init(_ K: SimplicialComplex, _ cells: [[Cell]]) {
        self.K = K
        self.cells = cells
    }
    
    public convenience init(_ K: SimplicialComplex) {
        let n = K.dim
        let cells = (0 ... n).reversed().map { (i) -> [LinkCell] in
            return K.allCells(ofDim: i).map { s in LinkCell(dim: n - i, base: s, components: K.link(s)) }
        }
        self.init(K, cells)
    }
    
    public var dim: Int {
        return K.dim
    }
    
    public func skeleton(_ dim: Int) -> LinkComplex {
        let sub = Array(cells[0 ... dim])
        return LinkComplex(K, sub)
    }
    
    public func allCells(ofDim i: Int) -> [LinkCell] {
        return (0...dim).contains(i) ? cells[i] : []
    }
    
    public func boundary<R: Ring>(ofCell t1: LinkCell) -> FreeModule<R, LinkCell> {
        let vertices = t1.chain.basis.reduce(Set<Vertex>()) { (set, s) in set.union(s.vertices) }
        let elements = vertices.map{ (v) -> (R, LinkCell) in
            let s = t1.base.join(v)
            let t2 = LinkCell(dim: t1.dim - 1, base: s, components: K.link(s))
            let e = R(intValue: (-1).pow(s.dim - s.index(ofVertex: v)!))
            return (e, t2)
        }
        return FreeModule(elements)
    }
    
    public func linkCell(for s: Simplex) -> LinkCell? {
        return cells[K.dim - s.dim].first{ $0.base == s }
    }
}

public extension SimplicialComplex {
    public func linkComplex() -> LinkComplex {
        return LinkComplex(self)
    }
}
