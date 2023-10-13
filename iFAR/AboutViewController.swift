//
//  AboutViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/31/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

class AboutViewController: UIViewController {
    var textsize:CGFloat = 15.0
   
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlLabel: UILabel!
    
    @IBOutlet weak var copyrightLabel: UILabel!
    @IBOutlet weak var certifiedLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setFontSizeForDevice()
        initConstraints()
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        perform(#selector(goaway), with: nil, afterDelay: g_aboutBoxDuration)
        Flurry.logEvent("Aboutbox Viewed", withParameters: nil);
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

    
    @objc func goaway(){
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func viewTapped() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func initConstraints(){
        let baseW:CGFloat = 280.0
        let baseH:CGFloat = 50.0
        let M:CGFloat =  0.17857142
        
        if screenWidth < 751.0{
            logoWidthConstraint.constant = baseW
            logoHeightConstraint.constant = baseH
        } else {
            logoWidthConstraint.constant = 358.0
            logoHeightConstraint.constant = 358.0 * M
        }
       
        if UIDevice.current.userInterfaceIdiom == .pad{
            logoWidthConstraint.constant = 560.0
            logoHeightConstraint.constant = 560.0 * M
      }
    }
    
    func setFontSizeForDevice(){
        
        var certifiedSize:CGFloat = 12.0
        var copyrightSize:CGFloat = 14.0
        var urlsize:CGFloat = 14.0
        var versionsize:CGFloat = 14.0

        if screenWidth < 751.0{
           textsize = 14.0
        } else {
           textsize = 19.0
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad{
            textsize = 30.0
            copyrightSize = 18.0
            certifiedSize = 20.0
            urlsize = 20.0
            versionsize = 18.0
            
            copyrightLabel.font = UIFont.systemFont(ofSize: copyrightSize)
            certifiedLabel.font = UIFont.systemFont(ofSize: certifiedSize)
            urlLabel.font = UIFont.systemFont(ofSize: urlsize)
            versionLabel.font = UIFont.systemFont(ofSize: versionsize)
         }
       // textView.font = UIFont.systemFont(ofSize: textsize)
      }
}
