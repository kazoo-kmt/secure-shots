//
//  ViewController.swift
//  pics-security
//
//  Created by 小林和宏 on 11/11/16.
//  Copyright © 2016 mycompany. All rights reserved.
//

import UIKit
import AVFoundation
import KeychainAccess

class ViewController: UIViewController {
  var device: AVCaptureDevice!
  var session: AVCaptureSession!
  var output: AVCaptureStillImageOutput!
  
  var timer: Timer!
  var count: Int = 0
  let numberOfShots = 10


  
  let keychain = Keychain(service: "com.mycompany.pics-security")

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    // Create session
    session = AVCaptureSession()
    // Choose front cam
    for d in AVCaptureDevice.devices() {
      if (d as AnyObject).position == AVCaptureDevicePosition.front {
        device = d as? AVCaptureDevice
        print("\(device!.localizedName) found.")
      }
      
    }
    // Create capture input
    let input: AVCaptureDeviceInput?
    do {
      input = try AVCaptureDeviceInput(device: device)
    } catch {
      print("Caught exception!")
      return
    }
    session.addInput(input)
    output = AVCaptureStillImageOutput()
    session.addOutput(output)
    session.sessionPreset = AVCaptureSessionPresetPhoto
    
    // Create preview layer
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer?.frame = view.bounds
    view.layer.addSublayer(previewLayer!)
    
    // Start session
    session.startRunning()
    
    // Creat a shot button
    let button = UIButton()
    button.setTitle("Shot", for: .normal)
    button.contentMode = .center
    button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    button.backgroundColor = UIColor.red
    button.layer.position = CGPoint(x: view.frame.width / 2, y: self.view.bounds.size.height - 80)
    button.addTarget(self, action: #selector(ViewController.multipleShots(_:)), for: .touchUpInside)
    view.addSubview(button)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func shot(_ sender: AnyObject) {
    let connection = output.connection(withMediaType: AVMediaTypeVideo)
    output.captureStillImageAsynchronously(from: connection) {(imageDataBuffer, error) -> Void in
      let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
//      let image = UIImage(data: imageData)!
      let imageDataStrBase64: String = imageData.base64EncodedString()
//      print(#line, imageDataStrBase64)
      
      // Store image
//      UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
      do {
        try self.keychain.set(imageDataStrBase64, key: "\(self.count)")
        print("\(self.count)")
      }
      catch let error {
        print(error)
      }
      self.count += 1
      
      if (self.count >= self.numberOfShots) {
        self.timer.invalidate()
      }
    }
  }
  
  func multipleShots(_ sender: AnyObject) {
    self.count = 0
    timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(shot(_:)), userInfo: nil, repeats: true)
  }
}
