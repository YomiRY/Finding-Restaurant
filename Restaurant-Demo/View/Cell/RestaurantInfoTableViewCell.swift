//
//  RestaurantInfoTableViewCell.swift
//  Restaurant-Demo
//
//  Created by yomi on 2017/11/27.
//  Copyright © 2017年 yomi. All rights reserved.
//

import UIKit

class RestaurantInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var mLbNameLabel: UILabel!
    @IBOutlet weak var mLbDistanceLabel: UILabel!
    @IBOutlet weak var mLbAddressLabel: UILabel!
    @IBOutlet weak var mLbTypeLabel: UILabel!
    @IBOutlet weak var mIvPhotoImageView: UIImageView!
    @IBOutlet weak var mLbReviewsLabel: UILabel!
    @IBOutlet weak var mLbPriceLabel: UILabel!
    @IBOutlet weak var mIvRatingImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }

}
