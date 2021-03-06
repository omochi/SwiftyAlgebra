//: Playground - noun: a place where people can play

import Foundation
import SwiftyAlgebra

// Aliases populary used in Math.

typealias Z = IntegerNumber
typealias Q = RationalNumber
typealias R = RealNumber

// Construct an algebraic extension over Q:
// K = Q(√2) = Q[x]/(x^2 - 2).

// 1. Static
do {
    struct p: _Polynomial {                            // p = x^2 - 2, as a struct
        typealias K = Q
        static let value = Polynomial<Q>(-2, 0, 1)
    }
    
    typealias I = PolynomialIdeal<p>                   // I = (x^2 - 2), static
    typealias K = QuotientField<Polynomial<Q>, I>      // K = Q[x]/I
    
    let a = Polynomial<Q>(0, 1).asQuotient(in: K.self) // a = x mod I
    a * a == 2
}

// 2. Dynamic
do {
    let p = Polynomial<Q>(-2, 0, 1)                    // p = x^2 - 2, as a value
    
    typealias I = DynamicIdeal<Polynomial<Q>, _0>
    I.register(p.asIdeal)                              // I = (x^2 - 2), dynamic
    
    typealias K = QuotientField<Polynomial<Q>, I>      // K = Q[x]/I
    
    let a = Polynomial<Q>(0, 1).asQuotient(in: K.self) // a = x mod I
    a * a == 2
}
