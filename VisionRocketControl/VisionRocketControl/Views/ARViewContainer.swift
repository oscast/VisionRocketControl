//
//  ARViewContainer.swift
//  VisionRocketController
//
//  Created by Oscar Castillo on 9/10/24.
//

import SwiftUI
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    
    @Environment(ARViewModel.self) var arViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let visionService = VisionService(arView: arView)
        let arDelegate = ARDelegate(arView: arView)
        
        arViewModel.setup(arView: arView, arDelegate: arDelegate, visionDelegate: visionService)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
