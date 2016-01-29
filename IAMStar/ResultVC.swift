//
//  ResultVC.swift
//  IAMStar
//
//  Created by xiaomo on 16/1/19.
//  Copyright © 2016年 xiaomo. All rights reserved.
//

import UIKit
import SKPhotoBrowser
import SwiftyJSON
import Material
class ResultVC: UIViewController {
    var data:JSON!
    var image:UIImage!
    @IBOutlet weak var tableView: UITableView!
 
    @IBOutlet weak var sourceImgHight: NSLayoutConstraint!
    @IBOutlet weak var sourceImage: ImageCardView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource=self
        tableView.delegate=self
        tableView.rowHeight=UIScreen.mainScreen().applicationFrame.width
        sourceImage.divider=false
        sourceImgHight.constant=100 * self.image.size.height / self.image.size.width
        let imageView=UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: sourceImgHight.constant))
        imageView.image=self.image
        sourceImage.addSubview(imageView)
        // Do any additional setup after loading the view.
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension ResultVC:UITableViewDelegate{
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
                var images = [SKPhoto]()
                for item in data.array!{
                    let name = item["tag"].stringValue
                    let photo = SKPhoto.photoWithImageURL(GlobalVariables.getFaceApiPicByName(name).url)
                    photo.shouldCachePhotoURLImage = true // you can use image cache by true(NSCache)
                    images.append(photo)
                }
    let browser = SKPhotoBrowser(photos: images)
     browser.initializePageIndex(indexPath.row)
     presentViewController(browser, animated: true, completion: {})
    }
}

extension ResultVC:UITableViewDataSource{
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ResultCell") as! ResultCell
        let item = data[indexPath.row]
        let urlname=GlobalVariables.getFaceApiPicByName(item["tag"].stringValue)
        cell.image1.sd_setImageWithURL(NSURL(string:urlname.url))
        cell.content.text="\(urlname.name )  相似度: \(item["similarity"].floatValue)"
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.arrayValue.count
    }
}