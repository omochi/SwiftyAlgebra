//
//  ViewController.swift
//  Visualizer
//
//  Created by Taketo Sano on 2017/09/29.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

import Cocoa
import SceneKit

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
            cameraNode.position = Vec3(20, 10, 20)
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
    
    override func mouseDragged(with event: NSEvent) {
        let p = cameraNode.position
        let t = atan2(p.z, p.x) + event.deltaX / 100
        let s = clamp(atan2(p.y, len(p.x, p.z) ) + event.deltaY / 100, -PI_2, PI_2)
        print(s / PI_2)
        cameraNode.position = 20 * Vec3(cos(s) * cos(t), sin(s), cos(s) * sin(t))
    }
    
    override func scrollWheel(with event: NSEvent) {
        let camera = cameraNode.camera!
        let s0 = CGFloat(camera.orthographicScale)
        let s1 = clamp(CGFloat(s0) + event.deltaY / 10, 1, 10)
        camera.orthographicScale = s1.native
    }
}
