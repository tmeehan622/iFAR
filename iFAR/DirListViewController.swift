//
//  DirListViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 1/4/19.
//  Copyright © 2019 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK


class DirListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var DocumentsItem:[String] = []
    var UndoItem:[String] = []

    @IBOutlet weak var tblView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUndoItemsList()
        initDocumentsItemsList()
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

    func initUndoItemsList(){
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        let docsDirect = paths[0]
        let docsUrl = URL(fileURLWithPath: docsDirect)
        let undofolder = docsUrl.appendingPathComponent("UndoFolder")
        let undofolderpath = undofolder.path
        var items:[String] = []
        do {
            UndoItem =  try FileManager.default.contentsOfDirectory(atPath: undofolderpath)
        } catch {
            UndoItem.append("No Items Found")
            //print("failed")
        }
        //print(items)
    }
    
    func initDocumentsItemsList(){
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        let docsDirect = paths[0]
//        let docsUrl = URL(fileURLWithPath: docsDirect)
//        let undofolder = docsUrl.appendingPathComponent("UndoFolder")
//        let undofolderpath = undofolder.path
//        var items:[String] = []
        do {
            DocumentsItem =  try FileManager.default.contentsOfDirectory(atPath: docsDirect)
        } catch {
            DocumentsItem.append("No Items Found")
            //print("failed")
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return DocumentsItem.count
        } else {
           return UndoItem.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
             return "Documents Folder Items"
        } else {
             return "Undo Folder Items"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseid = "filecell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseid, for: indexPath)
        
        let displayLabel = cell.contentView.viewWithTag(10) as! UILabel
        
        if(indexPath.section == 0){
            displayLabel.text = DocumentsItem[indexPath.row]
        } else {
            displayLabel.text = UndoItem[indexPath.row]
        }
        return cell
    }

}
