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
    private var rocket: UIView?
    private var boom: UIView?
    
    var rocketWasLaunched = false {
        didSet{
            if rocketWasLaunched == true{
                print("rocket is in the air")
            } else {
                print("rocket was boom")
            }
        }
    }

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
        rocketWasLaunched = true
        guard self.boom == nil else { return }
        createViews()
//        let face = results.first!
//        let frame = self.previewLayer.layerRectConverted(fromMetadataOutputRect: face.boundingBox)
//        animateRocketTo(frame: frame)
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
        
        if rocketWasLaunched, let face = faceObservations.first {
            let frame = self.previewLayer.layerRectConverted(fromMetadataOutputRect: face.boundingBox)
            print("go")
            animateRocketTo(frame: frame)
        }
    }
    
    private func createViews(){
        let rocket = UIImageView(image: UIImage(named: "rocket"))
        let rocketSize = CGSize(width: 117, height: 78)
        rocket.frame = CGRect(origin: CGPoint.zero, size: rocketSize)
        rocket.center = CGPoint(x: view.frame.width / 2, y: boomButton.frame.origin.y + boomButton.frame.height/2)
        let boom = UIImageView(image: UIImage(named: "boom"))
        let boomSize = CGSize(width: 200, height: 200)
        boom.frame = CGRect(origin: CGPoint.zero, size: boomSize)
        boom.alpha = 0
        boom.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        self.rocket = rocket
        self.boom = boom
        view.addSubview(rocket)
        view.addSubview(boom)
    }
    
    private func animateRocketTo(frame: CGRect){
        guard self.boom != nil, self.rocket != nil, self.rocketWasLaunched == true else { return }
        self.view.layer.removeAllAnimations()
        self.boom!.center = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height / 2)
        let distance = view.frame.width / min(frame.width, frame.height)
        let duration = Double(distance) * 0.5
        print("animation started")
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.rocket!.center = self.boom!.center
        } completion: { (_) in
            print("completion")
            self.rocket!.alpha = 0
            self.rocketWasLaunched = false
//            self.rocket = nil
            print("Mission complete")
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
                self.boom!.alpha = 1
                self.boom!.transform = CGAffineTransform(scaleX: 1, y: 1)
            } completion: { (_) in
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
                    self.boom!.alpha = 0
                    self.boom!.transform = CGAffineTransform(scaleX: 2, y: 2)
                } completion: { (_) in
//                    self.boom = nil
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        self.detectFace(in: pixelBuffer)
    }
}
