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
    
    @IBOutlet weak var note: UILabel!
    @IBOutlet weak var progress: UIActivityIndicatorView!

    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "presentImagePickerSheet:")
        view.addGestureRecognizer(tapRecognizer)
        progress.hidesWhenStopped=true
        //          self.imageView.sd_setImageWithURL(NSURL(string: "http://www.faceplusplus.com.cn/assets/demo-img2/安吉丽娜 朱莉/9.jpg"))
        //        var tempstr = "http://www.faceplusplus.com.cn/assets/demo-img2/安吉丽娜 朱莉/9.jpg" as NSString
        //    "
        //        a.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        //        self.imageView.sd_setImageWithURL(NSURL(string:tempstr as String), completed: { (UIImage, NSError, SDImageCacheType, NSURL) -> Void in
        //            let a = UIImage
        //            let b = NSError
        //            let c = SDImageCacheType
        //            let d = NSURL
        //        })
        
    }
    
    func printNote(note:String,progressing :Bool){
        if progressing{
            progress.startAnimating()
        }else{
            progress.stopAnimating()
        }
        self.note.text=note
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
            controller.allowsEditing=true
            self.presentViewController(controller, animated: true, completion: nil)
        }
        
        let controller = ImagePickerSheetController(mediaType: .Image)
        controller.maximumSelection=1
        controller.addAction(ImagePickerAction(title: NSLocalizedString("拍照", comment: "Action Title"), secondaryTitle: NSLocalizedString("使用", comment: "Action Title"), handler: { _ in
            presentImagePickerController(.Camera)
            }, secondaryHandler: { photo, numberOfPhotos in
                self.afterSelected(controller.selectedImageAssets)
        }))
        controller.addAction(ImagePickerAction(title: NSLocalizedString("相册", comment: "Action Title"), secondaryTitle:"", handler: { _ in
            presentImagePickerController(.PhotoLibrary)
            }, secondaryHandler: { _, numberOfPhotos in
                self.afterSelected(controller.selectedImageAssets)
                print("Send \(controller.selectedImageAssets)")
        }))
        controller.addAction(ImagePickerAction(title: NSLocalizedString("取消", comment: "Action Title"), style: .Cancel, handler: { _ in
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
        
        if  photos.count < 1
        {return}
        
        PHCachingImageManager().requestImageForAsset(photos[0], targetSize: CGSize(width: 200,height: 200), contentMode: PHImageContentMode.AspectFill, options: nil) { (img, info) -> Void in
            self.loadt(img!)
        }
        
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        picker.dismissViewControllerAnimated(true, completion: nil)
        //        info[""]
        
        //        let data = UIImagePNGRepresentation(info["UIImagePickerControllerOriginalImage"] as! UIImage,0.2)
        loadt(info["UIImagePickerControllerOriginalImage"] as! UIImage)
    }
    //
    
    
    func loadt( imge:UIImage){
        //        let fileURL = NSBundle.mainBundle().URLForResource("facehead", withExtension: "jpg") as NSURL?
        let imgTemp = FixOrientation.fixOrientation(imge)
        let img = UIImageJPEGRepresentation(imgTemp,1)
        self.printNote("查找中", progressing: true)
        if img == nil {
         self.printNote("选择图片失败", progressing: false)
            return
        }
        Alamofire.upload(
            .POST,
            "http://apicn.faceplusplus.com/v2/detection/detect?api_key=DEMO_KEY&api_secret=DEMO_SECRET&mode=commercial",headers: ["Host": "apicn.faceplusplus.com","Content-Type":"multipart/form-data; boundary=----WebKitFormBoundaryUPkUm83ZOvVxCO22","Origin":"http://www.faceplusplus.com.cn","Accept-Encoding":"Accept-Encoding","Connection":"keep-alive","Accept":"*/*","User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9","Referer":"http://www.faceplusplus.com.cn/demo-search/","Accept-Language":"zh-cn"],
            multipartFormData: { multipartFormData in
                //                multipartFormData.appendBodyPart(fileURL: fileURL!, name: "img")
                multipartFormData.appendBodyPart(data: img!, name: "img",fileName: "img", mimeType: "jpg")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        if response.result.error != nil{
//                            debugPrint("下载出错\(response.result.error)")
                            self.printNote("链接服务器失败", progressing: false)
                            return
                        }
                        let json=JSON(response.result.value!)
                        let faceid = json["face"][0]["face_id"]
                        if faceid.error != nil
                        {
                            self.printNote("姿势不对哦", progressing: false)
                            debugPrint("解析出错")
                            return
                        }
                        Alamofire.request(Alamofire.Method.GET, "http://apicn.faceplusplus.com/v2/recognition/search?api_key=DEMO_KEY&api_secret=DEMO_SECRET&key_face_id=\(faceid)&faceset_name=starlib3&count=8&mode=commercial", headers: ["Host": "apicn.faceplusplus.com","Content-Type":"multipart/form-data; boundary=----WebKitFormBoundaryUPkUm83ZOvVxCO22","Origin":"http://www.faceplusplus.com.cn","Accept-Encoding":"Accept-Encoding","Connection":"keep-alive","Accept":"*/*","User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9","Referer":"http://www.faceplusplus.com.cn/demo-search/","Accept-Language":"zh-cn"]).responseString { response in
                            var serial : NSDictionary
                            do {
                                serial =   try NSJSONSerialization.JSONObjectWithData(response.data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                            }catch _{
                                debugPrint("解析出错")
                                self.printNote("搜索失败", progressing: false)
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
            self.printNote("搜索失败", progressing: false)
            return
        }
        self.printNote("", progressing: false)
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("ResultVC") as! ResultVC
        vc.data = data["candidate"]
        vc.title="结果"
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
