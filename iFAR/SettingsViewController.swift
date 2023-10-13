//
//  SettingsViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/10/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import MessageUI
import Flurry_iOS_SDK


class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,MFMailComposeViewControllerDelegate {
    

    var outlineitems:Dictionary<String, Any>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let path = Bundle.main.path(forResource: "outlineItems", ofType: "plist")
    }
    
    override func viewWillAppear(_ animated: Bool) {
    
        super.viewWillAppear(animated)
        Flurry.logEvent("Settings Page Opened", withParameters: nil);
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


    @IBAction func AboutAction(_ sender: UIButton) {
        performSegue(withIdentifier: "flipper3", sender: sender)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingcell", for: indexPath)
        cell.textLabel!.text = settingsItems[indexPath.row]
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "terms" {
           let destController = segue.destination as? TermsViewController
            destController?.context = 1
          }
     }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row == 0{
            presentEmailUI()
        }
        if indexPath.row == 1{
            performSegue(withIdentifier: "flipper3", sender: self)
        }
        if indexPath.row == 2{
            performSegue(withIdentifier: "disclaimer", sender: self)
        }
        if indexPath.row == 3{
            performSegue(withIdentifier: "terms", sender: self)
        }
        if indexPath.row == 4{
            performSegue(withIdentifier: "dirlist", sender: self)
        }
    }
    
func presentEmailUI(){
    
        if MFMailComposeViewController.canSendMail() {
          // let bodyText = "<html><head></head><body><p>Go to <a href=\"http://www.visualsoftinc.com\">www.visualsoftinc.com</a> and find out how to try FAR.</p><p>FAR is the Federal Acquisition Authority on iPhone.</p></body></html>"
         
        let bodyText = "<html><head></head><body><p>Check out iFAR.  Available for free on the app store.<br><br>Go to: <a href=\"https://itunes.apple.com/us/app/ifar/id362412401?mt=8\">https://itunes.apple.com/us/app/iFAR</a></p><p>iFAR is the Federal Acquisition Authority on iPhone.</p></body></html>"

            let mailComposeViewController = MFMailComposeViewController()
            
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setMessageBody(bodyText, isHTML: true)
            mailComposeViewController.setSubject("Try iFAR FREE")
            mailComposeViewController.setBccRecipients(["info@visualsoftinc.com"])

            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            let mailalert = UIAlertController(title: nil, message: "There appears to be no email account setup on this device.  Unable to send email", preferredStyle: .alert)
            
            let okaction = UIAlertAction(title: "Ok", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
            })
        
            mailalert.addAction(okaction)
            
            self.present(mailalert, animated: true, completion: nil)
        }
    }
    //https://itunes.apple.com/us/app/ifar/id362412401?mt=8
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            //print("User cancelled")
            break
        case .saved:
            //print("Mail is saved by user")
            break
        case .sent:
            //print("Mail is sent successfully")
            break
        case .failed:
            //print("Sending mail is failed")
            break
        default:
            break
        }
        
        controller.dismiss(animated: true)
    }
}

