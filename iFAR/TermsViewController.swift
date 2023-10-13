//
//  TermsViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 1/2/19.
//  Copyright © 2019 Thomas Meehan. All rights reserved.
//

import UIKit
import WebKit
import Flurry_iOS_SDK


class TermsViewController: UIViewController {
    @IBOutlet  var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var oKButtonBottom: NSLayoutConstraint!
    let appDelegate     = UIApplication.shared.delegate as! AppDelegate

    var context:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.sizeToFit()
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        loadWebContent()
        Flurry.logEvent("Terms of Use Page Opened", withParameters: nil);

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


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            //print(String(progressView.progress))
            if progressView.progress == 1.0 {
                
               progressLabel.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if context == 0 {
            okButton.isHidden = true
            declineButton.isHidden = false
            acceptButton.isHidden = false
        } else {
            okButton.isHidden = false
            declineButton.isHidden = true
            acceptButton.isHidden = true
        }
    }
    
    func loadWebContent(){
        let path = Bundle.main.path(forResource: "termsOfUse", ofType: "html")
        let contentUrl = URL(fileURLWithPath: path!)
        
        webView.load(URLRequest(url: contentUrl))
     }
    
    func quit(){
        
        perform(#selector(appDelegate.quitApplication), with: nil, afterDelay: 1)

        
    }
    
    func byebyeAlert(){
        
        let optionMenu = UIAlertController(title: "Warning", message: "Terms must be agreed to prior to using iFAR. To continue using iFAR, please tap 'Cance' to dismiss this alert and then tap 'Agree' on the Terms and Conditions screen.", preferredStyle: .alert)
        
        let YESAction = UIAlertAction(title: "Quit Application", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.quit()
        })
        
        let NOAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
           
        })
        
        optionMenu.addAction(YESAction)
        optionMenu.addAction(NOAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }

    @IBAction func declineAction(_ sender: UIButton) {
        byebyeAlert()
    }
    
    @IBAction func acceptAction(_ sender: UIButton) {
        UserDefaults.standard.set(100, forKey: "termsAccepted")
        UserDefaults.standard.synchronize()
        
        self.dismiss(animated: true, completion: {
            self.appDelegate.resumeNormalFlow()
        })
        appDelegate.resumeNormalFlow()
    }
    
    @IBAction func okAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
