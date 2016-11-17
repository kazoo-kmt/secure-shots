//
//  ViewController.swift
//  SecurePics
//
//  Created by 小林和宏 on 11/16/16.
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
  let keyForPassword = "keyforpassword"
  
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
    let shotButton = UIButton()
    shotButton.setTitle("Shot", for: .normal)
    shotButton.contentMode = .center
    shotButton.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    shotButton.backgroundColor = UIColor.red
    shotButton.layer.position = CGPoint(x: view.frame.width / 2, y: self.view.bounds.size.height - 80)
    shotButton.addTarget(self, action: #selector(ViewController.multipleShots(_:)), for: .touchUpInside)
    view.addSubview(shotButton)
    
    // Create a count label
    label = UILabel()
    label.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    label.text = String(self.count)
    label.textAlignment = NSTextAlignment.center
    label.adjustsFontSizeToFitWidth = true
    label.layer.position = CGPoint(x: view.frame.width / 2, y: 80)
    view.addSubview(label)
    
    // Creat a button for segue
    let albumButton = UIButton()
    albumButton.setTitle("Album", for: .normal)
    albumButton.contentMode = .center
    albumButton.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
    albumButton.backgroundColor = UIColor.blue
    albumButton.layer.position = CGPoint(x: view.frame.width / 2 + 100, y: self.view.bounds.size.height - 80)
    //    albumButton.addTarget(self, action: #selector(segueToAlbum), for: .touchUpInside)
    albumButton.addTarget(self, action: #selector(verifyPassword), for: .touchUpInside)
    view.addSubview(albumButton)
    
  }
  
  func segueToAlbum() {
    performSegue(withIdentifier: "toAlbum", sender: self)
    print(#line, "Tap screen to go back main view from photo collection view.")
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    var password: String? = getPassword()
    if password == nil {
      password = getPassword()
    }
    let photoCollectionViewController: PhotosCollectionViewController = segue.destination as! PhotosCollectionViewController
    photoCollectionViewController.passwordForDecryption = password!
  }
  
  @IBAction func unwindToMain(segue:UIStoryboardSegue){
    //    print(#line, "Unwind from Album to Main")
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    getPassword()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: Directory for image data
  
  func setupDirectory() {
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
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
  
  
  // MARK: Create a password to encrypt images if not existed in Keychain
  func getPassword() -> String? {
    do {
      let existingPassword = try self.keychain.get("\(self.keyForPassword)")
      //      print(#line, "Current password in Keychain: \(existingPassword)")
      if existingPassword == nil {
        setupPassword()
      } else {
        return existingPassword
      }
    } catch {
      print(#line, error)
    }
    return nil
  }
  
  
  // MARK: Alert for password setting
  
  weak var actionToEnable: UIAlertAction?
  func setupPassword() {
    let alert = UIAlertController(title: "Password setting", message: "Set a password to encrypt your photos", preferredStyle: .alert)
    alert.addTextField { (textField) in
      textField.isSecureTextEntry = true
      textField.placeholder = "New password"
      textField.addTarget(self, action: #selector(self.textDoesExist), for: .editingChanged)
    }
    let action = UIAlertAction(title: "OK", style: .default, handler: { (_) in
      // Get a password inputted by user
      let textField = alert.textFields![0]
      print(#line, "Password: \(textField.text)")
      // Store the password to Keychain
      do {
        try self.keychain.set(textField.text!, key: "\(self.keyForPassword)")
      } catch {
        print(#line, error)
      }
    })
    alert.addAction(action)
    
    self.actionToEnable = action
    action.isEnabled = false
    
    self.present(alert, animated: true, completion: nil)
  }
  
  func textDoesExist(sender: UITextField) {
    self.actionToEnable?.isEnabled = !(sender.text?.isEmpty)!
  }
  
  
  // MARK: Alert for password verification
  func verifyPassword() {
    let alert = UIAlertController(title: "Password verification", message: "Type a password to see your photos", preferredStyle: .alert)
    alert.addTextField { (textField) in
      textField.isSecureTextEntry = true
      textField.placeholder = "Your password"
    }
    let action = UIAlertAction(title: "Verify", style: .default, handler: { (_) in
      // Get a password inputted by user
      let textField = alert.textFields![0]
      print(#line, "Password: \(textField.text)")
      // Store the password to Keychain
      do {
        let passwordInKeychain = try self.keychain.get("\(self.keyForPassword)")
        if passwordInKeychain == textField.text {
          self.segueToAlbum()
        } else {
          self.checkAgainAlert()
        }
      } catch {
        print(#line, error)
      }
    })
    alert.addAction(action)
    
    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
      alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(cancel)
    
    self.present(alert, animated: true, completion: nil)
  }
  
  func checkAgainAlert() {
    let message = UIAlertController(title: "Check your password again", message: "", preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
    message.addAction(ok)
    self.present(message, animated: true, completion: nil)
  }
  
  
  // MARK: Camera shot
  
  func shot(_ sender: AnyObject) {
    let connection = output.connection(withMediaType: AVMediaTypeVideo)
    output.captureStillImageAsynchronously(from: connection) {(imageDataBuffer, error) -> Void in
      let imageData: Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
      
      // Get a password to encrypt images from Keychain
      let password = (self.keychain["\(self.keyForPassword)"])!
      let encryptedData = RNCryptor.encrypt(data: imageData, withPassword: password)
      
      let fileName = String(self.count)
      if let directoryPath = self.directoryPath {
        let filePath = directoryPath.appending("/").appending(fileName)
        do {
          print(#line, filePath)
          try encryptedData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
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
