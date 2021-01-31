//
//  ViewController.swift
//  ImagesClassifier
//
//  Created by Artem Makaroff on 15.01.2020.
//  Copyright © 2020 Artem Makaroff. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  // MARK: - Outlets
  
  @IBOutlet private weak var imageView: UIImageView!
  @IBOutlet private weak var addButton: UIButton!
  @IBOutlet private weak var descriptionLabel: UILabel!
  
  private let classifierService = ImageClassifierService()
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bindToImageClassifierService()
    setup()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layoutSubviews()
  }
  
  // MARK: - Private Methods
  
  private func bindToImageClassifierService() {
    classifierService.onDidUpdateState = { [weak self] state in
      self?.setupWithImageClassifierState(state)
    }
  }
  
  private func setup() {
    addButton.setTitle("Add Image", for: .normal)
    descriptionLabel.isHidden = true
  }
  
  private func layoutSubviews() {
    addButton.layer.masksToBounds = true
    addButton.layer.cornerRadius = 16
  }
  
  private func setupWithImageClassifierState(_ state: ImageClassifierServiceState) {
    descriptionLabel.isHidden = false
    switch state {
    case .startRequest:
      descriptionLabel.text = "Сlassification in progress"
    case .requestFailed:
      descriptionLabel.text = "Classification is failed"
    case .receiveResult(let result):
      descriptionLabel.text = result.description
    }
  }
  
  private func showAlert() {
    let alertController = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
    let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
      self.showImagePicker(sourceType: .camera)
    }
    
    let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
      self.showImagePicker(sourceType: .photoLibrary)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cameraAction)
    alertController.addAction(photoLibraryAction)
    alertController.addAction(cancelAction)
    present(alertController, animated: true)
  }
  
  private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
    let imagePickerViewController = UIImagePickerController()
    imagePickerViewController.delegate = self
    imagePickerViewController.sourceType = sourceType
    present(imagePickerViewController, animated: true)
  }
}

// MARK: - Actions

extension ViewController {
  @IBAction private func onAddButtonTap(_ sender: UIButton) {
    showAlert()
  }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
    let imageKey = UIImagePickerController.InfoKey.originalImage
    guard let image = info[imageKey] as? UIImage else {
      dismiss(animated: true, completion: nil)
      return
    }
    dismiss(animated: true, completion: nil)
    classifierService.classifyImage(image)
    imageView.image = image
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}
