//
//  ViewController.swift
//  Visualizer
//
//  Created by Taketo Sano on 2017/09/29.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Cocoa
import SceneKit

let PI = Double.pi
let PI_2 = Double.pi / 2

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
}

extension SCNVector4 {
    init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) {
        self.init(x: x, y: y, z: z, w: w)
    }
    static var zero: SCNVector4 {
        return SCNVector4Zero
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

class ViewController : NSViewController {
    var scene: SCNScene!
    var sceneView:  SCNView!
    var cameraNode: SCNNode!
    var cameraTargetNode: SCNNode!
    var axesNode:   SCNNode!
    
    override func loadView() {
        scene = SCNScene()
        
        sceneView = {
            let sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
            sceneView.scene = scene
            sceneView.autoenablesDefaultLighting = true
            return sceneView
        }()
        
        cameraNode = {
            let cameraNode = SCNNode()
            let camera = SCNCamera()
            cameraNode.camera = {
                camera.usesOrthographicProjection = true
                camera.orthographicScale = 5
                return camera
            }()
            cameraNode.position = Vec3(20, 20, 20)
            //            cameraNode.rotation = Vec4(0, 1, 0, PI_2)
            
            return cameraNode
        }()
        
        scene.rootNode.addChildNode(cameraNode)
        
        // xyz-axis
        axesNode = {
            let axesNode = SCNNode()
            
            let dirs = [SCNVector4(0, 0, 1, -PI_2), SCNVector4.zero, SCNVector4(1, 0, 0, PI_2)]
            for d in dirs {
                let axis = SCNCylinder(radius: 0.01, height: 10)
                axis.color = NSColor.black
                axis.radialSegmentCount = 6
                let axisNode = SCNNode(geometry: axis)
                
                axisNode.rotation = d
                axesNode.addChildNode(axisNode)
                
                let cone = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.2)
                cone.color = NSColor.black
                cone.radialSegmentCount = 6
                let coneNode = SCNNode(geometry: cone)
                coneNode.position = Vec3(0, 5, 0)
                axisNode.addChildNode(coneNode)
            }
            
            let originNode = SCNNode(geometry: {
                let origin = SCNSphere(radius: 0.1)
                origin.color = NSColor.black
                return origin
            }())
            
            axesNode.addChildNode(originNode)
            cameraTargetNode = originNode
            
            let points = [(Vec3(1, 0, 0), NSColor.red),
                          (Vec3(0, 1, 0), NSColor.blue),
                          (Vec3(0, 0, 1), NSColor.green)]
            
            for (p, c) in points {
                let n = SCNNode(geometry: {
                    let pt = SCNSphere(radius: 0.1)
                    pt.color = c
                    return pt
                }())
                n.position = p
                axesNode.addChildNode(n)
            }
            
            return axesNode
        }()
        
        scene.rootNode.addChildNode(axesNode)
        
        let target = SCNLookAtConstraint(target: cameraTargetNode)
        target.isGimbalLockEnabled = true
        cameraNode.constraints = [target]
        
        self.view = sceneView
    }
}
