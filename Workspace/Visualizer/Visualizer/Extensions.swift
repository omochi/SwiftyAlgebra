//
//  SceneKitExtensions.swift
//  Visualizer
//
//  Created by Taketo Sano on 2017/09/29.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Foundation
import SceneKit

let PI = CGFloat(Double.pi)
let PI_2 = CGFloat(Double.pi / 2)

func clamp(_ x: CGFloat, _ x0: CGFloat, _ x1: CGFloat) -> CGFloat {
    return max(x0, min(x, x1))
}

func len(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
    return CGFloat( sqrt(x*x + y*y) )
}

extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
    
    static func -(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(p1.x - p2.x, p1.y - p2.y)
    }
}

extension CGRect {
    init(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        self.init(x: x, y: y, width: w, height: h)
    }
}

extension SCNVector3 {
    init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
        self.init(x: x, y: y, z: z)
    }
    static var zero: SCNVector3 {
        return SCNVector3Zero
    }
    
    static func *(a: CGFloat, v: SCNVector3) -> SCNVector3 {
        return SCNVector3(a * v.x, a * v.y, a * v.z)
    }
}

extension SCNVector4 {
    init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) {
        self.init(x: x, y: y, z: z, w: w)
    }
    static var zero: SCNVector4 {
        return SCNVector4Zero
    }
    
    static func *(a: CGFloat, v: SCNVector4) -> SCNVector4 {
        return SCNVector4(a * v.x, a * v.y, a * v.z, a * v.w)
    }
}

extension SCNGeometry {
    var color: NSColor? {
        get {
            return firstMaterial?.diffuse.contents as? NSColor
        } set {
            firstMaterial?.diffuse.contents = newValue
        }
    }
}

typealias Vec3 = SCNVector3
typealias Vec4 = SCNVector4
