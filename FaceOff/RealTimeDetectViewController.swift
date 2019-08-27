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
    
    var predictedObject: UILabel = UILabel()
    var frameToSend: CVImageBuffer?
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    //hold drawings, a reference for all the drawings on the screen
    private var drawings: [CAShapeLayer] = []
    private var boxes: [UIView] = []
    private var touchGestures: [UITapGestureRecognizer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addCameraInput()
        self.showCameraFeed()
        self.captureSession.startRunning()
        self.getCameraFrames()
        
        predictedObject.text = "Value"
        predictedObject.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1)
        predictedObject.textAlignment = .center
        predictedObject.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        predictedObject.frame = CGRect(x: view.frame.width / 2 , y: view.frame.height - 50, width: 100, height: 20)
        view.addSubview(predictedObject)
        

        
    }
    override func viewDidAppear(_ animated: Bool) {
        captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
       self.clearDrawings()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
                fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }
    
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Unable to get image")
            return
        }
        self.detectFace(in: frame)
        self.frameToSend = frame
        
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionResults(results)
                } else {
                    self.clearDrawings()
                }
            }
        })
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        let imagePredictionRequest = VNCoreMLRequest(model: model) { (request, Err) in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNClassificationObservation] else {return}
                guard let firstObservation = results.first else {return}
//                print(firstObservation.identifier, firstObservation.confidence)
                self.predictedObject.text = firstObservation.identifier
            }
           
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest, imagePredictionRequest ])
    }
    
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        self.clearDrawings()
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.map({ (observedFace: VNFaceObservation) -> CAShapeLayer in
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let redView = UIView()
            redView.backgroundColor = .red
            redView.frame = faceBoundingBoxOnScreen
            redView.alpha = 0.3
            self.view.addSubview(redView)
            self.boxes.append(redView)
            //            let touchGesture = UITapGestureRecognizer(target: self, action: #selector(self.onFaceSelected))
            //            redView.addGestureRecognizer(touchGesture)
            //            redView.isUserInteractionEnabled = true
            //            self.addTapGesture(on: redView)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            return faceBoundingBoxShape
        })
        facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
        self.drawings = facesBoundingBoxes
    }
    
    private func faceIdentificationBox(faceBoundary: VNFaceObservation) -> CGRect {
        let x = view.frame.width * faceBoundary.boundingBox.origin.x
        let height = view.frame.height * faceBoundary.boundingBox.height
        let y = view.frame.height * (1 - faceBoundary.boundingBox.origin.y) - height
        let width =  view.frame.width * faceBoundary.boundingBox.width
        let boxDimensions = CGRect(x: x, y: y, width: width, height: height)
        return boxDimensions
    }
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
        self.boxes.forEach({boxes in boxes.removeFromSuperview()})
        //        self.boxes.forEach({gestures in gestures.removeGestureRecognizer(gestures)})
    }
    
    
    @objc func onFaceSelected(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Purchase an item from this character", message: "Press continue to purchase an item worn by this character.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func captureImage(sampleBuffer: CVImageBuffer?) -> UIImage {
        guard let sampleBuffer = sampleBuffer else {return UIImage(named: "b2049test")!}
        CVPixelBufferLockBaseAddress(sampleBuffer, CVPixelBufferLockFlags.readOnly);
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(sampleBuffer);
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(sampleBuffer);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(sampleBuffer);
        let height = CVPixelBufferGetHeight(sampleBuffer);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(sampleBuffer, CVPixelBufferLockFlags.readOnly);
        
        // Create an image object from the Quartz image
        let image = UIImage.init(cgImage: quartzImage!);
        
        return (image);
        
    }
    
    @IBAction func presentLastImage(_ sender: UIBarButtonItem) {
         captureSession.stopRunning()
    
        performSegue(withIdentifier: "viewImage", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewImage" {
            if let nextVC = segue.destination as? ViewController {
                let image = self.captureImage(sampleBuffer: frameToSend)
                nextVC.selectedImage = image
            }
        }
        
    }
    
    
}

