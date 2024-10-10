//
//  ARDelegate.swift
//  VisionRocketController
//
//  Created by Oscar Castillo on 9/10/24.
//

import ARKit
import Combine
import RealityKit

class ARDelegate: NSObject, ARSessionDelegate {
    private weak var arView: ARView?
    var didUpdateFrame = PassthroughSubject<ARFrame, Never>()
    
    init(arView: ARView) {
        self.arView = arView
        super.init()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        didUpdateFrame.send(frame)
    }
}
