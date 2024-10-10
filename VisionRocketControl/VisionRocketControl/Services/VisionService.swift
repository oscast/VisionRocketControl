//
//  VisionService.swift
//  VisionRocketController
//
//  Created by Oscar Castillo on 9/10/24.
//

import Vision
import RealityKit
import Combine

enum ThumbOrientation {
    case right
    case left
    case unknown
}

class VisionService: NSObject {
    private let wristConfidence: Float = 0.3
    private let thumbConfidence: Float = 0.5
    
    var thumbState: (lastState: ThumbOrientation, framesInState: Int) = (.unknown, 0)
    
    weak var arView: ARView?
    
    lazy var handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            self?.processHandPoseResults(request: request, error: error)
        }
        request.maximumHandCount = 1
        return request
    }()
    
    init(arView: ARView) {
        self.arView = arView
    }
    
    func performHandDetectionAsync(on pixelBuffer: CVPixelBuffer) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try requestHandler.perform([handPoseRequest])
        } catch {
            print("Error performing hand pose request: \(error)")
        }
    }
    
    private func processHandPoseResults(request: VNRequest, error: Error?) {
        guard let observation = request.results?.first as? VNHumanHandPoseObservation else {
            setNeutralState()
            return
        }
        
        do {
            guard let thumbTip = try observation.recognizedPoints(.thumb)[.thumbTip],
                  let wrist = try observation.recognizedPoints(.all)[.wrist],
                  thumbTip.confidence > thumbConfidence,
                  wrist.confidence > wristConfidence else {
                setNeutralState()
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let arView = self.arView else { return }
                
                let viewWidth = Int(arView.bounds.width)
                let viewHeight = Int(arView.bounds.height)
                
                let thumbTipPoint = self.normalizeVisionPoint(thumbTip.location, viewWidth: viewWidth, viewHeight: viewHeight)
                let wristPoint = self.normalizeVisionPoint(wrist.location, viewWidth: viewWidth, viewHeight: viewHeight)
                
                let handOrientation = self.determineHandOrientation(thumbTip: thumbTipPoint, wrist: wristPoint)
                updateGestureState(currentGesture: handOrientation)
            }
        } catch {
            print("Error processing hand pose points: \(error)")
        }
    }
    
    // Vision Coordinates and UIKit Coordinates are not the same
    // Also The normalized points are different with ARKit Coordinates T_T
    // so we have to put point y in x and point x in y. vvlv
    private func normalizeVisionPoint(_ point: CGPoint, viewWidth: Int, viewHeight: Int) -> CGPoint {
        return VNImagePointForNormalizedPoint(CGPoint(x: point.y, y: point.x), viewWidth, viewHeight)
    }

    
    private func setNeutralState() {
        if thumbState.lastState != .unknown {
            thumbState.lastState = .unknown
        }
        thumbState.framesInState += 1
    }
    
    private func updateGestureState(currentGesture: ThumbOrientation) {
        if currentGesture == thumbState.lastState {
            thumbState.framesInState += 1
        } else {
            thumbState = (currentGesture, 1)
        }
    }
    
    func determineHandOrientation(thumbTip: CGPoint, wrist: CGPoint) -> ThumbOrientation {
        // Determine hand orientation based on the relative position of the thumb and wrist
        if thumbTip.x > wrist.x {
            return .right
        } else if thumbTip.x < wrist.x {
            return .left
        } else {
            return .unknown
        }
    }
}
