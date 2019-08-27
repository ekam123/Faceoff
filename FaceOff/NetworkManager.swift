//
//  NetworkManager.swift
//  FaceOff
//
//  Created by Ekam Singh Dhaliwal on 2019-08-25.
//  Copyright © 2019 ekam-singh. All rights reserved.
//

import Foundation
import UIKit



class NetworkManager {
    
    func makeRequest(image: UIImage, completion: @escaping (String?) -> Void) {
        let boundaryString:String = "AaB03x"
        let url = NSURL(string: "http://EkamSingh.local:5000/")!
        let request:NSMutableURLRequest = NSMutableURLRequest(url: url as URL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let MPboundary:String = "--\(boundaryString)"
        let endMPboundary:String = "\(MPboundary)--"
        //convert UIImage to NSData
//        let image = UIImage(imageLiteralResourceName: image)
        let imageName = image
        let data = image.pngData()
        //var data:NSData = image.pngData() as! NSData
        let body:NSMutableString = NSMutableString();
        
        //if parameters != nil {
        //    for (key, value) in parameters! {
        //        body.appendFormat("\(MPboundary)\r\n" as NSString)
        //        body.appendFormat("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n" as NSString)
        //        body.appendFormat("\(value)\r\n" as NSString)
        //    }
        //}
        let filename = "file"
        // set upload image, name is the key of image
        body.appendFormat("%@\r\n",MPboundary)
        body.appendFormat("Content-Disposition: form-data; name=\"\(filename)\"; filename=\"\(imageName).png\"\r\n" as NSString)
        body.appendFormat("Content-Type: image/png\r\n\r\n")
        let end:String = "\r\n\(endMPboundary)"
        let myRequestData:NSMutableData = NSMutableData();
        myRequestData.append(body.data(using: String.Encoding.utf8.rawValue)!)
        guard let dataToSend = data else {return}
        myRequestData.append(dataToSend)
        myRequestData.append(end.data(using: String.Encoding.utf8)!)
        let content:String = "multipart/form-data; boundary=\(boundaryString)"
        request.setValue(content, forHTTPHeaderField: "Content-Type")
        request.setValue("\(myRequestData.length)", forHTTPHeaderField: "Content-Length")
        request.httpBody = myRequestData as Data
        request.httpMethod = "POST"
        
        
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
        
            if error != nil { print("POST Request: Communication error: \(error!)") }
            do {

                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
//                    print(json)
                    guard let result = json["result"] else {return}
                    completion(result as? String)
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

 
//    func determineActor(person: String) -> String {
//        return nil
//    }
    
}
