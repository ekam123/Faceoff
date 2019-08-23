//
//  RealTimeDetectViewController.swift
//  FaceOff
//
//  Created by Ekam Singh Dhaliwal on 2019-08-22.
//  Copyright © 2019 ekam-singh. All rights reserved.
//

import UIKit
import AVKit
import Vision

class RealTimeDetectViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCameraFeed()
        getDataOutput()
    
    }
    

    func setupCameraFeed() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back)
            else {fatalError("No front video camera available") }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(cameraInput)
            captureSession.startRunning()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        // Display output of camera feed in view controller
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
//        let redView = UIView()
//        redView.backgroundColor = .red
//        redView.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
//        redView.alpha = 0.3
//        view.addSubview(redView)
        
    
    }
    
    func getDataOutput() {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)

    }
    

    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        let request = VNCoreMLRequest(model: model) { (request, Err) in
            guard let results = request.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            print(firstObservation.identifier, firstObservation.confidence)
            
        }
        
        
        let requestTwo = VNDetectFaceRectanglesRequest { (request, err) in
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
        
       
        DispatchQueue.global(qos: .background).async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [ : ])
            do {
                try handler.perform([requestTwo])
            } catch let Err{
                print("Failed to perform request:", Err)
            }
        }

       
    }
    
    func faceIdentificationBox(faceBoundary: VNFaceObservation) -> CGRect {
        let x = view.frame.width * faceBoundary.boundingBox.origin.x
        let height = view.frame.height * faceBoundary.boundingBox.height
        let y = view.frame.height * (1 - faceBoundary.boundingBox.origin.y) - height
        let width =  view.frame.width * faceBoundary.boundingBox.width
        let boxDimensions = CGRect(x: x, y: y, width: width, height: height)
        return boxDimensions
    }
    
    @objc func onFaceSelected(_ sender: UITapGestureRecognizer) {
        print("I have been touched")
    }
    


}


// ******** How to get rid of the red box when it is moved away from the face.


