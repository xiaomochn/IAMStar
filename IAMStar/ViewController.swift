//
//  ViewController.swift
//  IAMStar
//
//  Created by xiaomo on 16/1/18.
//  Copyright © 2016年 xiaomo. All rights reserved.
//

//
//  ViewController.swift
//  Example
//
//  Created by Laurin Brandner on 26/05/15.
//  Copyright (c) 2015 Laurin Brandner. All rights reserved.
//

import UIKit
import Photos
import ImagePickerSheetController
import Alamofire
import SwiftyJSON
import SKPhotoBrowser
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "presentImagePickerSheet:")
        view.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: Other Methods
    
    func presentImagePickerSheet(gestureRecognizer: UITapGestureRecognizer) {
        let presentImagePickerController: UIImagePickerControllerSourceType -> () = { source in
            let controller = UIImagePickerController()
            controller.delegate = self
            var sourceType = source
            if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
                sourceType = .PhotoLibrary
                print("Fallback to camera roll as a source since the simulator doesn't support taking pictures")
            }
            controller.sourceType = sourceType
            
            self.presentViewController(controller, animated: true, completion: nil)
        }
        
        let controller = ImagePickerSheetController(mediaType: .ImageAndVideo)
        controller.addAction(ImagePickerAction(title: NSLocalizedString("Take Photo Or Video", comment: "Action Title"), secondaryTitle: NSLocalizedString("Add comment", comment: "Action Title"), handler: { _ in
            presentImagePickerController(.Camera)
            }, secondaryHandler: { photo, numberOfPhotos in
//                self.afterSelected(photo)
                self.afterSelected(controller.selectedImageAssets)
//               let a = controller.selectedImageAssets
//                print("Comment \(numberOfPhotos) photos\(a.count)")
        }))
        controller.addAction(ImagePickerAction(title: NSLocalizedString("Photo Library", comment: "Action Title"), secondaryTitle: { NSString.localizedStringWithFormat(NSLocalizedString("ImagePickerSheet.button1.Send %lu Photo", comment: "Action Title"), $0) as String}, handler: { _ in
            presentImagePickerController(.PhotoLibrary)
            }, secondaryHandler: { _, numberOfPhotos in
                self.afterSelected(controller.selectedImageAssets)
                print("Send \(controller.selectedImageAssets)")
        }))
        controller.addAction(ImagePickerAction(title: NSLocalizedString("Cancel", comment: "Action Title"), style: .Cancel, handler: { _ in
            print("Cancelled")
        }))
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            controller.modalPresentationStyle = .Popover
            controller.popoverPresentationController?.sourceView = view
            controller.popoverPresentationController?.sourceRect = CGRect(origin: view.center, size: CGSize())
        }
        
        presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func afterSelected( photos: [PHAsset]){
        photos[0]
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        picker.dismissViewControllerAnimated(true, completion: nil)
//        info[""]
        let data = UIImagePNGRepresentation(info["UIImagePickerControllerOriginalImage"] as! UIImage)
        loadt(data!)
    }
//
    
    
    func loadt(img:NSData){
        let fileURL = NSBundle.mainBundle().URLForResource("facehead", withExtension: "jpg") as NSURL?
        Alamofire.upload(
            .POST,
            "http://apicn.faceplusplus.com/v2/detection/detect?api_key=DEMO_KEY&api_secret=DEMO_SECRET&mode=commercial",headers: ["Host": "apicn.faceplusplus.com","Content-Type":"multipart/form-data; boundary=----WebKitFormBoundaryUPkUm83ZOvVxCO22","Origin":"http://www.faceplusplus.com.cn","Accept-Encoding":"Accept-Encoding","Connection":"keep-alive","Accept":"*/*","User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9","Referer":"http://www.faceplusplus.com.cn/demo-search/","Accept-Language":"zh-cn"],
            multipartFormData: { multipartFormData in
//                multipartFormData.appendBodyPart(fileURL: fileURL!, name: "img")
                multipartFormData.appendBodyPart(data: img, name: "img",fileName: "img", mimeType: "jpg")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        if response.result.error != nil{
                            debugPrint("下载出错\(response.result.error)")
                            return
                        }
                        let json=JSON(response.result.value!)
                        let faceid = json["face"][0]["face_id"]
                        Alamofire.request(Alamofire.Method.GET, "http://apicn.faceplusplus.com/v2/recognition/search?api_key=DEMO_KEY&api_secret=DEMO_SECRET&key_face_id=\(faceid)&faceset_name=starlib3&count=8&mode=commercial", headers: ["Host": "apicn.faceplusplus.com","Content-Type":"multipart/form-data; boundary=----WebKitFormBoundaryUPkUm83ZOvVxCO22","Origin":"http://www.faceplusplus.com.cn","Accept-Encoding":"Accept-Encoding","Connection":"keep-alive","Accept":"*/*","User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9","Referer":"http://www.faceplusplus.com.cn/demo-search/","Accept-Language":"zh-cn"]).responseString { response in
                            var serial : NSDictionary
                            do {
                                 serial =   try NSJSONSerialization.JSONObjectWithData(response.data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                            }catch _{
                                debugPrint("解析出错")
                                return;
                            }
                            let tempJson = JSON(serial)

                            self.toResultVC(tempJson)

                        }
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                }
            }
        )

    }
    func toResultVC(data :JSON){
        if data["candidate"].error != nil{
            debugPrint("解析出错")
            return
        }
        var images = [SKPhoto]()
        for item in data["candidate"].array!{
//            http://www.faceplusplus.com.cn/assets/demo-img2/
            var name = item["tag"].stringValue
            
            let photo = SKPhoto.photoWithImageURL(GlobalVariables.getFaceApiPicByName(name))
//             let photo = SKPhoto.photoWithImageURL("http://h.hiphotos.baidu.com/image/h%3D300/sign=ece3e0add658ccbf04bcb33a29d8bcd4/aa18972bd40735fab9f007a699510fb30f2408a8.jpg")
            debugPrint(photo.photoURL)
//            photo.shouldCachePhotoURLImage = true // you can use image cache by true(NSCache)
            images.append(photo)
        }
    
        // create PhotoBrowser Instance, and present.
        let browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(0)
        presentViewController(browser, animated: true, completion: {})
    }
}
