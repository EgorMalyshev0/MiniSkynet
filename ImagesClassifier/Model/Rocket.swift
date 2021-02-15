//
//  Rocket.swift
//  ImagesClassifier
//
//  Created by Egor Malyshev on 15.02.2021.
//  Copyright © 2021 Artem Makaroff. All rights reserved.
//

import UIKit

class Rocket: UIImageView {
    
    var isLaunched = false
    
    init() {
        let image = UIImage(named: "rocket")
        super.init(image: image)
    }
    
    convenience init(rocketStartPoint: CGPoint) {
        self.init()
        let rocketSize = CGSize(width: 117, height: 78)
        self.frame = CGRect(origin: .zero, size: rocketSize)
        self.center = rocketStartPoint
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
