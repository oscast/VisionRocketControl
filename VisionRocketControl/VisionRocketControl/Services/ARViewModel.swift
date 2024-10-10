//
//  ARViewModel.swift
//  VisionRocketController
//
//  Created by Oscar Castillo on 9/10/24.
//

import RealityKit
import ARKit
import Combine

@Observable
class ARViewModel {
    weak var arView: ARView?
    
    private var arDelegate: ARDelegate?
    var visionDelegate: VisionService?
    private var cancellables = Set<AnyCancellable>()
    private let minimumFramesForStableGesture = 5
    private var frameCounter = 0
    private let framesInterval = 10
    
    var entity: ModelEntity?
    
    @ObservationIgnored
    var initialEntityYPosition: Float?
    
    @ObservationIgnored
    var anchor: AnchorEntity?
    
    var entityMoved: Bool = false
    
    var thumbState: (lastState: ThumbOrientation, framesInState: Int) = (.unknown, 0)
    
    func setup(arView: ARView, arDelegate: ARDelegate, visionDelegate: VisionService) {
        self.arView = arView
        self.visionDelegate = visionDelegate
        self.arDelegate = arDelegate
        
        setupScreenGestures(for: arView)
        setupLight()
        
        arView.session.delegate = arDelegate
        setupWordTrackingConfiguration(for: arView)
        bindObservables()
        
        self.arView = arView
    }
    
    func setupLight() {
        let pointLight = PointLight()
        pointLight.light.color = .white
        pointLight.light.intensity = 1500000
        pointLight.light.attenuationRadius = 7.0
        pointLight.position = [0,3,1]
        let lightAnchor = AnchorEntity(world: [0,0,0])
        lightAnchor.addChild(pointLight)
        
        arView?.scene.addAnchor(lightAnchor)
    }
    
    func bindObservables() {
        arDelegate?.didUpdateFrame.sink(receiveValue: { [weak self] arFrame in
            guard let self = self else { return }
            
            self.performHandRequestOnFrameIntervals(for: arFrame)
            self.updateEntityPositionBasedOnGesture()
        }).store(in: &cancellables)
    }
    
    func updateEntityPositionBasedOnGesture() {
        guard let entity = entity, let initialYPosition = initialEntityYPosition, let anchor = anchor, let visionDelegate else { return }
        
        let currentPosition = entity.position(relativeTo: anchor)
        
        if visionDelegate.thumbState.lastState == .right && visionDelegate.thumbState.framesInState >= minimumFramesForStableGesture {
            moveEntityUp(entity: entity, anchor: anchor, oldPosition: currentPosition, by: 0.02)
        } else if visionDelegate.thumbState.lastState == .left && visionDelegate.thumbState.framesInState >= minimumFramesForStableGesture {
            if currentPosition.y > initialYPosition {
                moveEntityUp(entity: entity, anchor: anchor, oldPosition: currentPosition, by: -0.02)
            }
        }
    }
    
    func performHandRequestOnFrameIntervals(for arFrame: ARFrame) {
        guard let visionDelegate else { return }
        
        frameCounter += 1
        
        if frameCounter % framesInterval == 0 {
            let pixelBuffer = arFrame.capturedImage
            visionDelegate.performHandDetectionAsync(on: pixelBuffer)
            frameCounter = 0
        }
    }
    
    func setupWordTrackingConfiguration(for arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.frameSemantics = .personSegmentationWithDepth
        arView.session.run(config)
    }
    
    func setupScreenGestures(for arView: ARView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard entity == nil, let arView else { return }
        
        let tapLocation = sender.location(in: arView)
        if let raycastResult = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal).first,
           let rocketEntity = try? ModelEntity.loadModel(named: "Rocket") {
            
            let anchor = AnchorEntity(world: raycastResult.worldTransform)
            self.anchor = anchor
            entity = rocketEntity
            anchor.addChild(rocketEntity)
            arView.scene.addAnchor(anchor)
            initialEntityYPosition = rocketEntity.position(relativeTo: anchor).y
        }
    }
    
    func moveEntityUp(entity: Entity, anchor: AnchorEntity, oldPosition: SIMD3<Float>, by constant: Float) {
        var newPosition = oldPosition
        newPosition.y += constant
        entity.setPosition(newPosition, relativeTo: anchor)
        
        if entityMoved == false {
            entityMoved = true
        }
    }
}
