//
//  GotoPageCellCollectionViewCell.swift
//  PDF-Demo
//
//  Created by Tom Meehan on 12/14/18.
//  Copyright © 2018 com.tzshlyt.demo. All rights reserved.
//

import UIKit

class GotoPageCellCollectionViewCell: UICollectionViewCell {

    open var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageLab: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
