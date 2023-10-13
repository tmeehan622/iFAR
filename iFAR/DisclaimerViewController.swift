//
//  DisclaimerViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 1/2/19.
//  Copyright © 2019 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK


class DisclaimerViewController: UIViewController {

    @IBOutlet weak var logoWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoIMV: UIImageView!
    @IBOutlet weak var txtView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        intializeConstraints()
        navigationItem.title = "Disclaimer"
        Flurry.logEvent("Disclaimer Page Opened", withParameters: nil);

        // Do any additional setup after loading the view.
    }
    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        get {
//            return .portrait
//        }
//    }
//
//    func shouldAutorotate() -> Bool {
//        return false
//    }
//

    func setTextViewFontSize(){
        
        if screenWidth < 750 {
          txtView.font = UIFont.systemFont(ofSize: 18.0)
          return
        }
        
        if screenWidth < 1125 {
            txtView.font = UIFont.systemFont(ofSize: 24.0)
            return
        }
        
        txtView.font = UIFont.systemFont(ofSize: 26.0)
    }
    
    func intializeConstraints(){
        
        let w = screenWidth * 0.875
        let h = w * 0.1785714
        let s = scaleFactorNative
        
        //print("w: \(w)")
        //print("h: \(h)")
        
        logoWidthConstraint.constant = w/s
        logoHeightConstraint.constant = h/s
        
        setTextViewFontSize()
    }

}
