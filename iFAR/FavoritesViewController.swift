//
//  FavoritesViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/10/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK


class FavoritesViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    

   @IBOutlet weak var tblView: UITableView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblView.register(UINib(nibName: "FavoritesCell", bundle: nil), forCellReuseIdentifier: "FavoritesCell")
 }
   
    @IBAction func AboutAction(_ sender: UIButton) {
        performSegue(withIdentifier: "flipper2", sender: sender)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tblView.reloadData()
        Flurry.logEvent("Favorites Opened", withParameters: nil);
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
        return BookmarkManager.shared.numBookmarks()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bm   = BookmarkManager.shared.bookMarks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritesCell", for: indexPath) as! FavoritesCell
        
        cell.titleLabel.text    = bm.title
        cell.viewController     = self
        cell.bookmark           = bm

//        if bm.hasAudio() {
//          cell.contentView.backgroundColor = UIColor.green
//        } else {
//          cell.contentView.backgroundColor = UIColor.white
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bm   = BookmarkManager.shared.bookMarks[indexPath.row]
        performSegue(withIdentifier: "gotolinkedpage", sender:bm)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let bm   = BookmarkManager.shared.bookMarks[indexPath.row]
            let bmId = bm.uuid
            
            BookmarkManager.shared.deleteBookMarkWithUUID(uuid: bmId!)            
            tableView.deleteRows(at: [indexPath], with: .fade)
         }
    }

    func editBookMark(bm:BookMark){
        self.performSegue(withIdentifier: "editbookmark", sender: bm)
    }
    
    func editAudio(bm:BookMark){
        self.performSegue(withIdentifier: "editaudio", sender: bm)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editbookmark"{
            if let destController = segue.destination as? CreateFavoriteViewController{
                let bm = sender as! BookMark
                destController.curBookmark = bm
            }
        }
        
        if segue.identifier == "editaudio"{
            if let destController = segue.destination as? VoiceRecorderViewController {
                let bm = sender as! BookMark
                destController.bookmark = bm
            }
        }

        if segue.identifier == "gotolinkedpage"{
            if let destController = segue.destination as? ScrollerViewController {
                let bm = sender as! BookMark
                let pageIndex = bm.pageIndx
                var indx:Int = -1
                
                if pageIndex != nil {
                    indx = pageIndex!
                }
                
                let c = PDFManager.shared.pdfDocument?.pageCount
                
                if indx > c! - 1 || indx < 0 {
                    indx = 0
                }
                let curPage = PDFManager.shared.pdfDocument?.page(at: indx)

                destController.curPage = curPage
                destController.pagenum = indx + 1
            }
        }
    }
}

