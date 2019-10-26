//
//  SmithEliminator.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2017/11/08.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

final class SmithEliminator<R: EuclideanRing>: MatrixEliminator<R> {
    var currentIndex = 0
    
    override func prepare() {
        subrun(DiagonalEliminator.self)
        components.sort(by: { $0.row < $1.row })
    }
    
    override func isDone() -> Bool {
        currentIndex >= components.count
    }
    
    @_specialize(where R == 𝐙)
    override func iteration() {
        guard let pivot = findPivot() else {
            return exit()
        }
        
        let i0 = pivot.row
        var a0 = pivot.value
        
        if !a0.isNormalized {
            apply(.MulRow(at: i0, by: a0.normalizingUnit))
            a0 = a0.normalized
        }
        
        if !a0.isIdentity {
            var again = false

            for i in (currentIndex ..< components.count) where i != i0 {
                let a = components[i].value
                if !a.isDivible(by: a0) {
                    diagonalGCD((i0, a0), (i, a))
                    again = true

                }
            }
            
            if again {
                return
            }
        }
        
        if i0 != currentIndex {
            swapDiagonal(i0, currentIndex)
        }
        
        currentIndex += 1
    }
    
    private func apply(_ s: RowElementaryOperation<R>) {
        switch s {
        case let .MulRow(at: i, by: a):
            components[i].value = a * components[i].value
        default:
            fatalError()
        }
        
        append(s)
    }
    
    private func findPivot() -> MatrixComponent<R>? {
        components
            .filter{ (i, _, _) in i >= currentIndex }
            .min { (c1, c2) in c1.value.euclideanDegree < c2.value.euclideanDegree }
    }
    
    private func diagonalGCD(_ d1: (Int, R), _ d2: (Int, R)) {
        let (i, a) = d1
        let (j, b) = d2
        
        // d = gcd(a, b) = pa + qb
        // m = lcm(a, b) = -a * b / d
        
        let (p, q, d) = extendedGcd(a, b)
        let m = -(a * b) / d
        
        components[i].value = d
        components[j].value = m
        
        append(.AddRow(at: i, to: j, mul: p))     // [a, 0; pa, b]
        append(.AddCol(at: j, to: i, mul: q))     // [a, 0;  d, b]
        append(.AddRow(at: j, to: i, mul: -a/d))  // [0, m;  d, b]
        append(.AddCol(at: i, to: j, mul: -b/d))  // [0, m;  d, 0]
        append(.SwapRows(i, j))                   // [d, 0;  0, m]
        
        log("DiagonalGCD:  (\(i), \(i)), (\(j), \(j))")
    }
    
    private func swapDiagonal(_ i: Int, _ j: Int) {
        (components[i].value, components[j].value) = (components[j].value, components[i].value)

        append(.SwapRows(i, j))
        append(.SwapCols(i, j))
        
        log("SwapDiagonal: (\(i), \(i)), (\(j), \(j))")
    }
}