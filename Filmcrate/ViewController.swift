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
    var labelName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelName = UILabel()
        labelName.frame = CGRect(x: view.center.x - 100 , y: view.frame.height - 50, width: 200, height: 30)
        labelName.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        labelName.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.addSubview(labelName)
        
        guard let image = selectedImage else {return}
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        scaledHeight = view.frame.width / image.size.width * image.size.height
        imageView.frame = CGRect(x: 0, y:(navigationController?.navigationBar.frame.height)!, width: view.frame.width, height: scaledHeight)
        view.addSubview(imageView)
        
//        detectFaces(image: image)
    
        let networkManager = NetworkManager()
        networkManager.makeRequest(image: image) { (actorName) in
            
                        guard let actorName = actorName else {return}
                        DispatchQueue.main.async {
                            self.labelName.text = actorName
                        }
                    }
        
        
    }
    
    func detectFaces(image: UIImage) {
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

