//
//  FaceView.swift
//  ImagesClassifier
//
//  Created by Egor Malyshev on 18.01.2021.
//  Copyright © 2021 Artem Makaroff. All rights reserved.
//

import UIKit

class FaceView: UIView {

    var boundingBox = CGRect.zero
    
    override func draw(_ rect: CGRect){
        guard let context = UIGraphicsGetCurrentContext() else {
          return
        }
        context.saveGState()
        defer {
          context.restoreGState()
        }
        context.addRect(boundingBox)
        UIColor.orange.setStroke()
        context.strokePath()
    }
    
    func clear() {
      
      boundingBox = .zero
      
      DispatchQueue.main.async {
        self.setNeedsDisplay()
      }
    }

}
