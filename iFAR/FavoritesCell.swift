//
//  FavoritesCell.swift
//  iFAR
//
//  Created by Tom Meehan on 12/30/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit

class FavoritesCell: UITableViewCell {
    var bookmark:BookMark?
    var viewController:FavoritesViewController?
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBAction func openAction(_ sender: UIButton) {
        //print(bookmark!.title)
        viewController?.editBookMark(bm: bookmark!)
    }
    
    @IBAction func micButton(_ sender: UIButton) {
        viewController?.editAudio(bm: bookmark!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
