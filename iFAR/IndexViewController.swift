//
//  IndexViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/21/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK


class IndexViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var rawData:Dictionary<String, AnyObject>?
    var masterList:Array<AnyObject>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterList!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseid = "plaincell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseid, for: indexPath)
        cell.textLabel!.text = "Row: \(indexPath.row)"
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
