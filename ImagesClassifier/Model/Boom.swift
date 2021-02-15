//
//  Explosion.swift
//  ImagesClassifier
//
//  Created by Egor Malyshev on 15.02.2021.
//  Copyright © 2021 Artem Makaroff. All rights reserved.
//

import UIKit

class Boom: UIImageView {
    
    var isLaunched = false {
        didSet{
            guard isLaunched else { return }
            playAnimation()
        }
    }
    
    var animationInProgress = false
    
     init() {
        let image = UIImage(named: "boom")
        super.init(image: image)
        let boomSize = CGSize(width: 200, height: 200)
        self.frame = CGRect(origin: .zero, size: boomSize)
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func playAnimation(){
        if !animationInProgress {
            animationInProgress = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
                self.alpha = 1
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            } completion: { (_) in
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
                    self.alpha = 0
                    self.transform = CGAffineTransform(scaleX: 2, y: 2)
                } completion: { _ in
                    self.animationInProgress = false
                }
            }
        }
        isLaunched = false
    }
}
