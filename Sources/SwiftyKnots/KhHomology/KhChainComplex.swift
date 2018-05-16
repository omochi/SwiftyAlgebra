//
//  KhovanovHomology.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import Foundation
import SwiftyMath
import SwiftyHomology

public struct KhCube {
    public struct Vertex {
        public let state: KauffmanState
        public let components: [Link.Component]
        public let basis: [KhTensorElement]
    }
    
    public let vertices: [KauffmanState : Vertex]
    private let minEdgeId: Int
    
    public init(_ L: Link) {
        let n = L.crossingNumber
        self.vertices = Dictionary(keys: KauffmanState.all(n)) { s -> Vertex in
            let sL = L.spliced(by: s)
            let comps = sL.components
            let basis = KhTensorElement.generateBasis(state: s, power: comps.count)
            return Vertex(state: s, components: comps, basis: basis)
        }
        
        self.minEdgeId = L.edges.map{ $0.id }.min() ?? -1
    }
    
    public subscript(s: KauffmanState) -> Vertex {
        return vertices[s]!
    }
    
    public func vertices(degree: Int) -> [Vertex] {
        return vertices.values.filter{ $0.state.degree == degree }
    }
    
    public func basis(degree: Int) -> [KhTensorElement] {
        return vertices(degree: degree).flatMap { v in v.basis }
    }
    
    public func basis(degree i: Int, _ j: Int) -> [KhTensorElement] {
        return basis(degree: i).filter{ $0.degree == j }
    }
    
    public func reducedBasis(degree: Int) -> [KhTensorElement] {
        return vertices(degree: degree).flatMap { v -> [KhTensorElement] in
            if let i = v.components.index(where: { $0.edges.contains{ $0.id == minEdgeId } }) {
                return v.basis.filter{ t in t.factors[i] == .X }
            } else {
                return v.basis
            }
        }
    }
    
    public func map<R: Ring>(_ x: KhTensorElement, _ μ: KhBasisElement.Product<R>, _ Δ: KhBasisElement.Coproduct<R>) -> FreeModule<KhTensorElement, R> {
        let s = x.state
        return s.next.sum { (sgn, next) in
            let (c1, c2) = (self[s].components, self[next].components)
            let (d1, d2) = (c1.filter{ !c2.contains($0) }, c2.filter{ !c1.contains($0) })
            
            switch (d1.count, d2.count) {
            case (2, 1): // apply μ
                let (i1, i2, j) = (c1.index(of: d1[0])!, c1.index(of: d1[1])!, c2.index(of: d2[0])!)
                return R(from: sgn) * x.product(μ, (i1, i2), j, next)
                
            case (1, 2): // apply Δ
                let (i, j1, j2) = (c1.index(of: d1[0])!, c2.index(of: d2[0])!, c2.index(of: d2[1])!)
                return R(from: sgn) * x.coproduct(Δ, i, (j1, j2), next)
                
            default:
                fatalError()
            }
        }
    }
    
    public func map<R: Ring>(_ x: FreeModule<KhTensorElement, R>, _ μ: KhBasisElement.Product<R>, _ Δ: KhBasisElement.Coproduct<R>) -> FreeModule<KhTensorElement, R> {
        return x.elements.sum { (a, r) in r * self.map(a, μ, Δ) }
    }
}

public extension Link {
    public var KhCube: SwiftyKnots.KhCube {
        return SwiftyKnots.KhCube(self)
    }
    
    public func KhChainComplex<R: EuclideanRing>(_ type: R.Type, unnormalized: Bool = false, reduced: Bool = false) -> CochainComplex<KhTensorElement, R> {
        return KhChainComplex(KhCube, KhBasisElement.μ, KhBasisElement.Δ, R.self, unnormalized: unnormalized, reduced: reduced)
    }

    public func KhChainComplex<R: EuclideanRing>(_ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, unnormalized: Bool = false, reduced: Bool = false) -> CochainComplex<KhTensorElement, R> {
        return KhChainComplex(KhCube, μ, Δ, R.self, unnormalized: unnormalized, reduced: reduced)
    }
    
    internal func KhChainComplex<R: EuclideanRing>(_ cube: KhCube, _ μ: @escaping KhBasisElement.Product<R>, _ Δ: @escaping KhBasisElement.Coproduct<R>, _ type: R.Type, unnormalized: Bool, reduced: Bool) -> CochainComplex<KhTensorElement, R> {
        typealias C = CochainComplex<KhTensorElement, R>
        
        let (n, n⁺, n⁻) = (crossingNumber, crossingNumber⁺, crossingNumber⁻)
        
        let name = "CKh(\(self.name); \(R.symbol))"
        let chain = (0 ... n).map { i -> (C.ChainBasis, C.BoundaryMap) in
            let chainBasis = (!reduced ? cube.basis(degree: i) : cube.reducedBasis(degree: i))
            let boundaryMap = C.BoundaryMap { (x: KhTensorElement) in cube.map(x, μ, Δ) }
            return (!unnormalized ? chainBasis.map{ $0.shifted(n⁺ - 2 * n⁻)} : chainBasis, boundaryMap)
        }
        
        return CochainComplex(name: name, chain: chain, offset: !unnormalized ? -n⁻ : 0)
    }
}
