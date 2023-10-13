//
//  RootViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/10/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK


class RootViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var rawData:Dictionary<String, AnyObject>?
    var masterList:Array<AnyObject>?
    let appDelegate     = UIApplication.shared.delegate as! AppDelegate
   
    override func viewDidLoad() {
        super.viewDidLoad()
        if rawData == nil {
          rawData = appDelegate.rawData
        }
//        let splashImage = UIImage(named:"Default@1242x2208.png")
//        
//        let splashView = UIImageView()
//        splashView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
//        splashView.contentMode = .scaleAspectFit
//        splashView.image = splashImage
//        self.view.addSubview(splashView)
     }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        masterList = (rawData!["children"] as! Array<AnyObject>)
    
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterList!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let reuseid = "plaincell"
        
         let cell = tableView.dequeueReusableCell(withIdentifier: reuseid, for: indexPath)
        cell.textLabel!.text = masterList![indexPath.row]["title"] as! String
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let d = masterList![indexPath.row] as! Dictionary<String, AnyObject>
        let a = d["children"]
        
        if a != nil {
            if let nextController = storyboard?.instantiateViewController(withIdentifier: "rootview") as? RootViewController {
                nextController.rawData = masterList![indexPath.row] as? Dictionary<String, AnyObject>
                navigationController?.pushViewController(nextController, animated: true)
            }
        } else {
            let p = d["page"]
            //print(p)
            performSegue(withIdentifier: "pdfdirect", sender: p)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destController = segue.destination as? ScrollerViewController{
            let pagenumstring = sender as! String
            
            let pagen = Int(pagenumstring)
            
            var curPageNum:Int = 0
            
            if pagen != nil {
                curPageNum = pagen!
            }
           let curPage = PDFManager.shared.pdfDocument?.page(at: curPageNum - 1)
            destController.curPage = curPage
            destController.pagenum = curPageNum
            
           // destController.pagenum = Int(pagenumstring)!
        }
    }
    
    @IBAction func aboutAction(_ sender: UIButton) {
          performSegue(withIdentifier: "flipper", sender: sender)
    }

//    @objc func flip() {
//        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
//
//        UIView.transition(with: firstView, duration: 1.0, options: transitionOptions, animations: {
//            self.firstView.isHidden = true
//        })
//
//        UIView.transition(with: secondView, duration: 1.0, options: transitionOptions, animations: {
//            self.secondView.isHidden = false
//        })
//    }
}

extension Dictionary {
    static func contentsOf(path: URL) -> Dictionary<String, AnyObject> {
        let data = try! Data(contentsOf: path)
        let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
        
        return plist as! [String: AnyObject]
    }
}

