//
//  Complex.swift
//  SwiftyMath
//
//  Created by Taketo Sano on 2018/03/16.
//  Copyright © 2018年 Taketo Sano. All rights reserved.
//

import Foundation

public typealias ComplexNumber = Complex<𝐑>
public typealias 𝐂 = ComplexNumber

public struct Complex<R: Ring>: Ring {
    private let x: R
    private let y: R
    
    public init(from x: 𝐙) {
        self.init(R(from: x))
    }
    
    public init(_ x: R) {
        self.init(x, .zero)
    }
    
    public init(_ x: R, _ y: R) {
        self.x = x
        self.y = y
    }
    
    public static var imaginaryUnit: Complex<R> {
        return Complex(.zero, .identity)
    }
    
    public var realPart: R {
        return x
    }
    
    public var imaginaryPart: R {
        return y
    }
    
    public var conjugate: Complex<R> {
        return Complex(x, -y)
    }

    public var inverse: Complex? {
        let r2 = x * x + y * y
        if let inv = r2.inverse {
            return Complex(x * inv, -y * inv)
        } else {
            return nil
        }
    }
    
    public static func ==(lhs: Complex<R>, rhs: Complex<R>) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y)
    }
    
    public static func +(a: Complex<R>, b: Complex<R>) -> Complex<R> {
        return Complex(a.x + b.x, a.y + b.y)
    }
    
    public static prefix func -(a: Complex<R>) -> Complex<R> {
        return Complex(-a.x, -a.y)
    }
    
    public static func *(a: Complex<R>, b: Complex<R>) -> Complex<R> {
        return Complex(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)
    }
    
    public var hashValue: Int {
        let p = 104743
        return (x.hashValue % p) &+ (y.hashValue % p) * p
    }
    
    public var description: String {
        return (x != .zero && y != .zero) ? "\(x) + \(y)i" :
                         (y == .identity) ? "i" :
                             (y != .zero) ? "\(y)i"
                                          : "\(x)"
    }
    
    public static var symbol: String {
        if R.self == 𝐑.self {
            return "𝐂"
        } else {
            return "\(R.symbol)[i]"
        }
    }
}

// このとき、Complex: EuclideanRing が成り立たないとコンパイルできない。
// これは、RealNumber: MakeComplexEuclideanElement なので、
// 後述するextensionによって満たされるのでOK。
extension Complex: Field, NormedSpace where R == 𝐑 {
    public init(from r: 𝐐) {
        self.init(r)
    }

    public init(_ x: 𝐙) {
        self.init(𝐑(x), 0)
    }

    public init(_ x: 𝐐) {
        self.init(𝐑(x), 0)
    }

    public init(r: 𝐑, θ: 𝐑) {
        self.init(r * cos(θ), r * sin(θ))
    }

    public var abs: 𝐑 {
        return √(x * x + y * y)
    }

    public var norm: 𝐑 {
        return abs
    }

    public var arg: 𝐑 {
        let r = self.norm
        if(r == 0) {
            return 0
        }

        let t = acos(x / r)
        return (y >= 0) ? t : 2 * π - t
    }
}

public typealias GaussInt = Complex<𝐙>

// マーカープロトコル
public protocol MakeComplexEuclideanElement {}

// 本当は extension GaussInt : MakeComplexEuclideanElement {} と書きたいが、
// 仕様上できないようなので分解して書き下す。
extension Complex : MakeComplexEuclideanElement where R == Int {}

extension RealNumber : MakeComplexEuclideanElement {}

extension Complex {
    // Complex<R>からComplex<P>にキャストする
    public func forceCast<P: Ring>(to type: P.Type) -> Complex<P> {
        return Complex<P>(realPart as! P,
                          imaginaryPart as! P)
    }
}

extension Complex: EuclideanRing where R : MakeComplexEuclideanElement {
    public func eucDiv(by b: Complex<R>) -> (q: Complex<R>, r: Complex<R>) {
        // 手動でディスパッチ
        switch R.self {
        case is GaussInt.Type:
            let a = self.forceCast(to: GaussInt.self)
            let b = b.forceCast(to: GaussInt.self)
            let (q, r) = _eucDev(a, b)
            return (q: q.forceCast(to: R.self),
                    r: r.forceCast(to: R.self))
        case is RealNumber.Type:
            let a = self.forceCast(to: RealNumber.self)
            let b = b.forceCast(to: RealNumber.self)
            let (q, r) = _eucDev(a, b)
            return (q: q.forceCast(to: R.self),
                    r: r.forceCast(to: R.self))
        default:
            fatalError("unimplemented")
        }
    }
    
    public var eucDegree: Int {
        // 手動でディスパッチ
        switch R.self {
        case is GaussInt.Type:
            let a = self.forceCast(to: GaussInt.self)
            return _eucDegree(a)
        case is RealNumber.Type:
            let a = self.forceCast(to: RealNumber.self)
            return _eucDegree(a)
        default:
            fatalError("unimplemented")
        }
    }
}

fileprivate func _eucDev(_ a: Complex<GaussInt>, _ b: Complex<GaussInt>) -> (q: Complex<GaussInt>, r: Complex<GaussInt>) {
    fatalError("実装してください")
}

fileprivate func _eucDegree(_ a: Complex<GaussInt>) -> Int {
    fatalError("実装してください")
}

// Fieldからの自動実装を手動で実装・・・。
fileprivate func _eucDev(_ a: Complex<RealNumber>, _ b: Complex<RealNumber>) -> (q: Complex<RealNumber>, r: Complex<RealNumber>) {
    return (a / b, .zero)
}

fileprivate func _eucDegree(_ a: Complex<RealNumber>) -> Int {
    return a == .zero ? 0 : 1
}

extension Complex: ExpressibleByIntegerLiteral where R: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = R.IntegerLiteralType
    public init(integerLiteral n: R.IntegerLiteralType) {
        self.init(R(integerLiteral: n))
    }
}

extension Complex: ExpressibleByFloatLiteral where R: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = R.FloatLiteralType
    public init(floatLiteral x: R.FloatLiteralType) {
        self.init(R(floatLiteral: x))
    }
}
