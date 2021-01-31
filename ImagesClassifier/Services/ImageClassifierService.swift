//
//  ImageClassifierService.swift
//  ImagesClassifier
//
//  Created by Artem Makaroff on 12.02.2020.
//  Copyright © 2020 Artem Makaroff. All rights reserved.
//

import UIKit
import Vision
import AVKit

enum ImageClassifierServiceState {
  case startRequest, requestFailed, receiveResult(resultModel: ClassifierResultModel)
}

class ImageClassifierService {
  var onDidUpdateState: ((ImageClassifierServiceState) -> Void)?
  var requestOptions: [VNImageOption: Any] = [:]

  func classifyImage(_ image: UIImage) {
    onDidUpdateState?(.startRequest)
    
    guard let model = makeImageClassifierModel(), let ciImage = CIImage(image: image) else {
      onDidUpdateState?(.requestFailed)
      return
    }
    makeClassifierRequest(for: model, ciImage: ciImage)
  }
    
    func classifyImageInRealtime(pixelBuffer: CVImageBuffer) {
        onDidUpdateState?(.startRequest)
        
        guard let model = makeImageClassifierModel() else {
          onDidUpdateState?(.requestFailed)
          return
        }
        makeClassifierRequest2(for: model, pixelBuffer: pixelBuffer)
    }
  
  private func makeImageClassifierModel() -> VNCoreMLModel? {
    let config = MLModelConfiguration()
    return try? VNCoreMLModel(for: MyImageClassifier(configuration: config).model)
  }
  
  private func makeClassifierRequest(for model: VNCoreMLModel, ciImage: CIImage) {
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      self?.handleClassifierResults(request.results)
    }
    
    let handler = VNImageRequestHandler(ciImage: ciImage)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        self.onDidUpdateState?(.requestFailed)
      }
    }
  }
    
    private func makeClassifierRequest2(for model: VNCoreMLModel, pixelBuffer: CVImageBuffer) {
      let request = VNCoreMLRequest(model: model) { [weak self] request, error in
        self?.handleClassifierResults(request.results)
      }
      
      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
      DispatchQueue.global(qos: .userInteractive).async {
        do {
          try handler.perform([request])
        } catch {
          self.onDidUpdateState?(.requestFailed)
        }
      }
    }
  
  private func handleClassifierResults(_ results: [Any]?) {
    
    guard let foundResults = results?.compactMap({$0 as? VNClassificationObservation})
            .first(where: {$0.confidence > 0.8}) else {
        onDidUpdateState?(.requestFailed)
        return
    }
    
    DispatchQueue.main.async { [weak self] in
      let confidence = (foundResults.confidence * 100).rounded()
      let resultModel = ClassifierResultModel(identifier: foundResults.identifier, confidence: Int(confidence))
      self?.onDidUpdateState?(.receiveResult(resultModel: resultModel))
    }
  }
}
