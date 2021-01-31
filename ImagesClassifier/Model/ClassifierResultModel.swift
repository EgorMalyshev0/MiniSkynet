//
//  ClassifierResultModel.swift
//  ImagesClassifier
//
//  Created by Artem Makaroff on 12.02.2020.
//  Copyright © 2020 Artem Makaroff. All rights reserved.
//

import Foundation

struct ClassifierResultModel {
  let identifier: String
  let confidence: Int
  
  var description: String {
    return "This is \(identifier) with \(confidence)% confidence"
  }
}
