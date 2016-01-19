//
//  ResultCell.swift
//  IAMStar
//
//  Created by xiaomo on 16/1/19.
//  Copyright © 2016年 xiaomo. All rights reserved.
//

import UIKit
import SwiftyJSON
import SDWebImage
class ResultCell: UITableViewCell {

    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    var data:JSON{
        set(newValue){
            image1.sd_setImageWithURL(NSURL(string: ""))
        }
        get{return self.data}
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}