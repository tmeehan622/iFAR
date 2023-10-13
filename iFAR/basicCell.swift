//
//  basicCell.swift
//  iFAR
//
//  Created by Tom Meehan on 12/11/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit

class basicCell: UITableViewCell {

    @IBOutlet weak var textlabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
