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
import RNCryptor

class ViewController: UIViewController {
  var device: AVCaptureDevice!
  var session: AVCaptureSession!
  var output: AVCaptureStillImageOutput!
  
  var directoryPath: String!
  
  var timer: Timer!
  var count: Int = 0
  let numberOfShots = 10

  let keychain = Keychain(service: "com.mycompany.pics-security")
  let password = "passwordpassword" // NTR
  
  var label: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create a directory to store images
    setupDirectory()
    
    // Create session
    session = AVCaptureSession()
    // Choose front cam
    for d in AVCaptureDevice.devices() {
      if (d as AnyObject).position == AVCaptureDevicePosition.front {
        device = d as? AVCaptureDevice
//        print("\(device!.localizedName) found.")
      }
      
    }
    // Create capture input
    let input: AVCaptureDeviceInput?
    do {
      input = try AVCaptureDeviceInput(device: device)
    } catch {
      print(#line, error)
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
    
    // Create a count label
    label = UILabel()
    label.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    label.text = String(self.count)
    label.textAlignment = NSTextAlignment.center
    label.adjustsFontSizeToFitWidth = true
    label.layer.position = CGPoint(x: view.frame.width / 2, y: 80)
    view.addSubview(label)

  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: Directory for image data
  
  func setupDirectory() {
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//    let directoryName = "pics-security"
    let directoryName = Bundle.main.infoDictionary?["CFBundleName"] as! String

    self.directoryPath = documentPath.appending("/").appending(directoryName)
    print(self.directoryPath)
    let fileManager = FileManager()
    if (fileManager.fileExists(atPath: self.directoryPath)) {
      print("\(self.directoryPath) already present.")
    } else {
      do {
        try fileManager.createDirectory(atPath: self.directoryPath, withIntermediateDirectories: false, attributes: nil)
      } catch {
        print(#line, error)
      }
    }
  }
  
  
  // MARK: Camera shot
  
  func shot(_ sender: AnyObject) {
    let connection = output.connection(withMediaType: AVMediaTypeVideo)
    output.captureStillImageAsynchronously(from: connection) {(imageDataBuffer, error) -> Void in
      let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
      let encryptedImageData = RNCryptor.encrypt(data: imageData, withPassword: self.password)  //NTR
      
      let fileName = String(self.count)
      if let directoryPath = self.directoryPath {
        let filePath = directoryPath.appending("/").appending(fileName)
        do {
          print(#line, filePath)
          try encryptedImageData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
        } catch {
          print(#line, error)
        }
      }
      
      self.count += 1
      self.label.text = String(self.count)
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
