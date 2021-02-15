//
//  SecondViewController.swift
//  ImagesClassifier
//
//  Created by Egor Malyshev on 11.01.2021.
//  Copyright © 2021 Artem Makaroff. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class SecondViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var boomButton: UIButton!
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()

    private var drawings: [CAShapeLayer] = []
    private var rocket: Rocket?
    private var boom: Boom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCamera()
        
        boomButton.layer.cornerRadius = boomButton.frame.height / 2
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = self.view.frame
        self.view.bringSubviewToFront(boomButton)
    }
    
    @IBAction func makeBoom(_ sender: Any) {
        guard self.boom == nil else { return }
        rocket?.isLaunched = true
        createViews()
    }
    
    private func configureCamera() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
               fatalError("No back camera device found")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
        
        self.captureSession.startRunning()
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleDetectedFaces(results)
                } else {
                    self.drawings.forEach { drawing in
                        drawing.removeFromSuperlayer()
                    }
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    private func handleDetectedFaces(_ faceObservations: [VNFaceObservation]){
        self.drawings.forEach { drawing in
            drawing.removeFromSuperlayer()
        }
        
        let facesBoundingBoxes: [CAShapeLayer] = faceObservations.map({ (observedFace: VNFaceObservation) -> CAShapeLayer in
                let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
                let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
                let faceBoundingBoxShape = CAShapeLayer()
                faceBoundingBoxShape.path = faceBoundingBoxPath
                faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
                faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
                return faceBoundingBoxShape
            })
            facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
            self.drawings = facesBoundingBoxes
        
        if let rocket = self.rocket, rocket.isLaunched, !faceObservations.isEmpty {
            var faces: [CGRect] = []
            faceObservations.forEach { (face) in
                let frame = self.previewLayer.layerRectConverted(fromMetadataOutputRect: face.boundingBox)
                faces.append(frame)
            }
            faces.sort {
                return distance($0.origin, rocket.center) > distance($1.origin, rocket.center)
            }
            print("go")
            animateRocketTo(frame: faces.first!)
        }
    }
    
    private func createViews(){
        let rocketStartPoint = CGPoint(x: view.frame.width / 2, y: boomButton.frame.origin.y + boomButton.frame.height/2)
        let rocket = Rocket(rocketStartPoint: rocketStartPoint)
        let boom = Boom()
        self.rocket = rocket
        self.boom = boom
        view.addSubview(rocket)
        view.addSubview(boom)
    }
    
    private func animateRocketTo(frame: CGRect){
        print("animation started")
        guard let boom = self.boom, let rocket = self.rocket, rocket.isLaunched == true else { return }
        boom.center = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height / 2)
        let distance = view.frame.width / min(frame.width, frame.height)
        let duration = Double(distance) * 0.5
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            rocket.center = boom.center
        } completion: { (isCompleted) in
            print("completion")
            rocket.alpha = 0
            rocket.isLaunched = false
            self.rocket = nil
            print("Mission complete")
            boom.isLaunched = true
            self.boom = nil
//            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
//                boom.alpha = 1
//                boom.transform = CGAffineTransform(scaleX: 1, y: 1)
//            } completion: { (_) in
//                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
//                    boom.alpha = 0
//                    boom.transform = CGAffineTransform(scaleX: 2, y: 2)
//                } completion: { (_) in
//                    self.boom = nil
//                }
//            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        self.detectFace(in: pixelBuffer)
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
}
