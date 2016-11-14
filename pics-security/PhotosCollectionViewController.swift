//
//  PhotosCollectionViewController.swift
//  pics-security
//
//  Created by 小林和宏 on 11/13/16.
//  Copyright © 2016 mycompany. All rights reserved.
//

import UIKit
import RNCryptor

private let reuseIdentifier = "Cell"

class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  
  var images = [UIImage]()
  var passwordForDecryption: String!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Register cell classes
    self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    
    // Do any additional setup after loading the view.
    // Fetch the decrypted images from document directory by using password passed from ViewController
    prepareData()
    
    // If tapped, unwind to ViewController
    self.collectionView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PhotosCollectionViewController.collectionViewTapped)))
  }
  
  func collectionViewTapped() {
    self.performSegue(withIdentifier: "unwindToMain", sender: self)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func prepareData() {
    let fileManager = FileManager()
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let directoryName = Bundle.main.infoDictionary?["CFBundleName"] as! String
    let directoryPath = documentPath.appending("/").appending(directoryName)
    
    do {
      let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
      for fileName in contents {
        let encryptedData: Data = fileManager.contents(atPath: directoryPath.appending("/").appending(fileName))!
        do {
          let decryptedData = try RNCryptor.decrypt(data: encryptedData, withPassword: passwordForDecryption)
          let decryptedImage = UIImage(data: decryptedData)!
          self.images.append(decryptedImage)
        } catch {
          print(#line, error)
        }
      }
    } catch {
      print(#line, error)
    }
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using [segue destinationViewController].
   // Pass the selected object to the new view controller.
   }
   */
  
  // MARK: UICollectionViewDataSource
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }
  
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of items
    // Set the maximum number of element
    return 10
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    // Configure the cell if there are images
    if self.images.count > 0 {
      let numberOfCellInRow : Int = 2
      let padding : Int = 5
      let collectionCellWidth: CGFloat = (self.view.frame.size.width / CGFloat(numberOfCellInRow)) - CGFloat(padding)
      let cellImageView : UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: collectionCellWidth, height: collectionCellWidth))
      cellImageView.contentMode = .scaleAspectFit
      cellImageView.image = self.images[indexPath.row]
      cell.addSubview(cellImageView)
      //    cell.backgroundColor = UIColor(red: CGFloat(drand48()),
      //                                   green: CGFloat(drand48()),
      //                                   blue: CGFloat(drand48()),
      //                                   alpha: 1.0)
    }
    return cell
  }
  
  
  // MARK: UICollectionViewLayoutDelegate
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let numberOfCellInRow : Int = 2
    let padding : Int = 0
    let collectionCellWidth: CGFloat = (self.view.frame.size.width / CGFloat(numberOfCellInRow)) - CGFloat(padding)
    return CGSize(width: collectionCellWidth , height: collectionCellWidth)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0.0
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0.0
  }
  
  
  // MARK: UICollectionViewDelegate
  
  /*
   // Uncomment this method to specify if the specified item should be highlighted during tracking
   override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
   return true
   }
   */
  
  /*
   // Uncomment this method to specify if the specified item should be selected
   override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
   return true
   }
   */
  
  /*
   // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
   override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
   return false
   }
   
   override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
   return false
   }
   
   override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
   
   }
   */
  
}
