//
//  ViewController.swift
//  FaceOff
//
//  Created by Ekam Singh Dhaliwal on 2019-08-19.
//  Copyright © 2019 ekam-singh. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    private var scaledHeight: CGFloat!
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let image = selectedImage else {return}
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        scaledHeight = view.frame.width / image.size.width * image.size.height
        imageView.frame = CGRect(x: 0, y:(navigationController?.navigationBar.frame.height)!, width: view.frame.width, height: scaledHeight)
        view.addSubview(imageView)
        
        let request = VNDetectFaceRectanglesRequest { (request, err) in
            if let err = err {
                print("Failed to detect any faces: ", err)
            }
            
            request.results?.forEach({ (res) in
                DispatchQueue.main.async {
                    guard let faceObervation = res as? VNFaceObservation else {return}
                    let redView = UIView()
                    redView.backgroundColor = .red
                    redView.frame = self.faceIdentificationBox(faceBoundary: faceObervation)
                    redView.alpha = 0.3
                    self.view.addSubview(redView)
                    print(faceObervation.boundingBox)
                    
                    let touchGesture = UITapGestureRecognizer(target: self, action: #selector(self.onFaceSelected))
                    redView.addGestureRecognizer(touchGesture)
                }
                
                
            })
        }
       
        guard let cgImage = image.cgImage else {return}
        DispatchQueue.global(qos: .background).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [ : ])
            do {
                try handler.perform([request])
            } catch let Err{
                print("Failed to perform request:", Err)
            }
        }
    

    }
    
    func faceIdentificationBox(faceBoundary: VNFaceObservation) -> CGRect {
        let x = self.view.frame.width * faceBoundary.boundingBox.origin.x
        let height = scaledHeight * faceBoundary.boundingBox.height
        let y = scaledHeight * (1 - faceBoundary.boundingBox.origin.y) - height
        let width = self.view.frame.width * faceBoundary.boundingBox.width
        let boxDimensions = CGRect(x: x, y: y, width: width, height: height + (navigationController?.navigationBar.frame.height)!)
        return boxDimensions
    }
    
    @objc func onFaceSelected(_ sender: UITapGestureRecognizer) {
        print("I have been touched")
    }
}

