//
//  ViewController.swift
//  FaceOff
//
//  Created by Ekam Singh Dhaliwal on 2019-08-19.
//  Copyright © 2019 ekam-singh. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewAccessibilityDelegate, UIPickerViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else
    {
    presentPhotoPicker(sourceType: .photoLibrary)
    return
    }
    
    let photoSourcePicker = UIAlertController()
    let takePhoto = UIAlertAction(title: "Take Photo",
                                  style: .default) { [unowned self] _ in
                                    self.presentPhotoPicker(sourceType: .camera)
    }
    let choosePhoto = UIAlertAction(title: "Choose Photo",
                                    style: .default) { [unowned self] _ in
                                        self.presentPhotoPicker(sourceType: .photoLibrary)
    }
    
    photoSourcePicker.addAction(takePhoto)
    photoSourcePicker.addAction(choosePhoto)
    photoSourcePicker.addAction(UIAlertAction(title: "Cancel",
    style: .cancel,
    handler: nil))
    
    present(photoSourcePicker, animated: true)
}

func presentPhotoPicker(sourceType: UIImagePickerController.SourceType)
{
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    present(picker, animated: true)
}



func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
{
    picker.dismiss(animated: true)
    
    // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
    let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
    imageView.image = image

}


}

