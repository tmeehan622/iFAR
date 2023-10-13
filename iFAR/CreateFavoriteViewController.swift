//
//  CreateFavoriteViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/29/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

struct oldvalues {
    
    var title:String
    var text:String
    var hasAudio:Bool
    var audioSize:UInt64
    
    init(ttl:String = "-", txt:String = "-", audio:Bool = false, sz:UInt64 = 0){
        title = ttl
        text = txt
        hasAudio = audio
        audioSize = sz
      }
}

class CreateFavoriteViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var titleTF: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var txtViewBottom: NSLayoutConstraint!
    @IBOutlet weak var titleLBL: UILabel!
    @IBOutlet weak var textView: UITextView!
    var mytitle = "default"
    var range:(start:Int, end:Int, source:String)?
    var linkedPageNum:Int?
    var curBookmark:BookMark?
    var audioURL:URL?
    var NewBookMark:BookMark?
    var newAudioRecorded = false
    var manualBackOut = false
    var changesSaved = false
    var checksum:Int = -1
    var savedValues:oldvalues = oldvalues()
    var restoreURL:URL?
    var blockRestore = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: "saveButtonTapped")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: "backAction")

          
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),for: UIControl.Event.editingChanged)

        if curBookmark != nil {
            //print("Saving bookmark values for possible restoring if note isn't saved.")
            savedValues.title = (curBookmark?.title)!
            savedValues.text = (curBookmark?.text)!
            savedValues.hasAudio = (curBookmark?.hasAudio())!
            savedValues.audioSize = (curBookmark?.sizeOfAudioFile())!
            checksum =  curBookmark!.checksum()
            copyAudioFileForUndo()
        } else {
           checksum = -1
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Flurry.logEvent("Create/View Favorites Open", withParameters: nil);

        blockRestore = false
        
        if curBookmark != nil {
            let fsize = curBookmark!.sizeOfAudioFile()
            let indx = curBookmark!.pageIndx
            var pageIndex:Int = -1

            if indx != nil{
                pageIndex = indx!
              
                if pageIndex > -1{
                   pageIndex = pageIndex + 1
                }
      
                if pageIndex > 0 {
                    pageIndex = pageIndex + 1
                    let indxString = String(pageIndex)
                    titleLBL.text = "Page: " + indxString
                }
            } else {
                titleLBL.text = "Page: ??"
            }
             titleTF.text = curBookmark?.title
             textView.text = curBookmark!.text
        } else {
            NewBookMark = BookMark(indx: linkedPageNum!, url: nil, ttl: mytitle, txt: "")
            titleLBL.text = mytitle
            textView.text = ""
            titleTF.text = mytitle
        }
        updateButtonState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        if blockRestore == true {
//            return
//        }
        
        if manualBackOut == true {
            if(curBookmark != nil){
                if (changesSaved == false){
                    //print("apparently we exited without saving.... restoring original bookmard from undo folder")
                    restoreOriginalBookMark()
                }
            }
            
            clearUndoFolder()
        }
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


    @IBAction func micButtonAction(_ sender: UIButton) {

        if curBookmark != nil {
            performSegue(withIdentifier: "gotoaudio", sender: curBookmark)
        } else {
            performSegue(withIdentifier: "gotoaudio", sender: NewBookMark)
        }
    }
    
    func dismiss(){
        navigationController?.popViewController(animated: true)
    }
    
    func noteSavedAlert(){
        
        let bmsavedalert = UIAlertController(title: nil, message: "You're bookmark has been saved.", preferredStyle: .alert)
        
        let okaction = UIAlertAction(title: "Ok", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.dismiss()
        })
        
        bmsavedalert.addAction(okaction)
        self.present(bmsavedalert, animated: true, completion: nil)
    }

    @objc func saveButtonTapped() {
        if curBookmark != nil {
            curBookmark?.title = titleTF.text
            curBookmark?.text = textView.text
            BookmarkManager.shared.updateBookmarkWithUUID(uid: (curBookmark?.uuid)!, bm: curBookmark!)
        } else {
            NewBookMark?.title = titleTF.text
            NewBookMark?.text = textView.text
            BookmarkManager.shared.addBookMark(bm:NewBookMark!)
        }
        BookmarkManager.shared.saveBookMarksToUserPrefs()
        changesSaved = true
        noteSavedAlert()
        Flurry.logEvent("Favorites Saved", withParameters: nil);

     }
   
    
    func restoreOriginalBookMark(){
     //print("restoreOriginalBookMark - IN")
        if savedValues.title != "-" {
           //print("we have saved values")
           curBookmark?.title = savedValues.title
           curBookmark!.text = savedValues.text
            if savedValues.hasAudio == true {
                //print("saved values indicate the origian bm had an audio file")
                if newAudioRecorded == true {
                    //print("newAudioRecorded = true")
                    let url = curBookmark?.getAudioFileUrl()
                    //print("attempt to delted audio file in documents folder before moving file from undo folder to documents folder")
                    let result = curBookmark!.deleteExistingAudio()
                    
                    if (result == false){
                        //print("error deleting audio in documents folder")
                    }
                    do {
                        try FileManager.default.moveItem(at: restoreURL!, to: url!)
                        //print("successful file move")
                    } catch {
                        //print("error moving audio from UndoFolder to documents folder")
                    }
                } else {
                    //print("newAudioRecorded = false, no need to move anything")
                }
            } else {
                //print("saved values indicate the origian bm did not have audio file")
            }
        } else {
            //print("we don't have any saved values to restore from.... something is wrong")
        }
        //print("restoreOriginalBookMark - OUT")
     }
    
    @objc func backAction() {
        //print("backAction")
        manualBackOut = true
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = UIEdgeInsets.zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        textView.scrollIndicatorInsets = textView.contentInset
        
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "gotoaudio"{
            if let destController = segue.destination as? VoiceRecorderViewController{
                let bm = sender as! BookMark
                destController.bookmark = bm
                destController.viewController = self
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
    
    func undoFolderUrl()->URL?{
        var retURL:URL?
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        let pathURL = URL.init(string: paths[0])
        let dataURL = pathURL!.appendingPathComponent("UndoFolder")

        if folderExists(dataURL){
          retURL = dataURL
        }
        
        return retURL
    }
    
    func PATHitemExists(path:String)->Bool{
        
        var found = false
        
        if (FileManager.default.fileExists(atPath: path)) {
            //print("File exist at path")
            found = true
        } else {
            //print("File does not exist at path")
        }
        return found
    }
    
    func URLitemExists(url:URL)->Bool{
        
        let path = url.path
        var found = false
        
        if (FileManager.default.fileExists(atPath: path)) {
            //print("File exist at url")
            found = true
        } else {
            //print("File does not exist at url")
        }
        return found
    }

    func listDirectoryContents(){
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)

        do {
            let items =  try FileManager.default.contentsOfDirectory(atPath: paths[0])
        } catch {
          //print("failed")
        }
    }
    
    func copyAudioFileForUndo(){
        //print("copyAudioFileForUndo - IN")
        //print(" copy existing audio (if exists) to the Undo Folder")
        if (curBookmark?.hasAudio())! {
            //print(" hasAudio = true")
            let url      = curBookmark!.getAudioFileUrl()
            let fname    = url.lastPathComponent
            let tempURL  = undoFolderUrl()
            let destURL  = tempURL!.appendingPathComponent(fname)
            let destPath = destURL.path
            let realDest = URL(fileURLWithPath: destPath)
            
            if URLitemExists(url:realDest){
                do {
                    try FileManager.default.removeItem(at: realDest)
                    //print("successfully removed existing file in UndoFolder")
                } catch {
                    //print("error removing existing file in UndoFolder")
                }
            }
            
            do {
                try FileManager.default.copyItem(at: url, to: realDest)
                restoreURL = realDest
                //print("successfully copied existing file in documents folder to UndoFolder")
                
            } catch {
                //print("error moving audio from documents folder to UndoFolder")
            }
        } else {
            //print(" hasAudio = false, do nothing")
        }
        //print("copyAudioFileForUndo - OUT")
    }
    
    func clearUndoFolder(){
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDirect = paths[0]
        let docsUrl = URL(fileURLWithPath: docsDirect)
        let undofolderUrl = docsUrl.appendingPathComponent("UndoFolder")
        let undofolderpath = undofolderUrl.path
        var items:[String] = []
        do {
            items =  try FileManager.default.contentsOfDirectory(atPath: undofolderpath)
            
            for fitem in items {
                
                let fpurl = undofolderUrl.appendingPathComponent(fitem)
                do {
                try FileManager.default.removeItem(at: fpurl)
                    //print("item removed: " + fitem)

                } catch {
                    //print("failed to remove item: " + fitem)
                }
            }
            
        } catch {
            //print("failed")
        }
    }

    
    
    func folderExists(_ folderURL:URL)->Bool{
        if FileManager.default.fileExists(atPath:folderURL.path ){
            return true
        } else {
            return false
        }
    }

    func thingsChanged()->Bool{
        let ttl = textField.text
        let body = textView.text
        let audio = curBookmark?.hasAudio()
        let asize = curBookmark?.sizeOfAudioFile()
        
        if ttl != savedValues.title {
            return true
        }
        if body != savedValues.text {
            return true
        }
        if audio != savedValues.hasAudio {
            return true
        }
        if asize != savedValues.audioSize {
            return true
        }
        return false
    }
    
    func updateButtonState(){
        self.navigationItem.rightBarButtonItem?.isEnabled = thingsChanged()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateButtonState()
        //print("textFieldShouldBeginEditing")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateButtonState()
        //print("text field changed")
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //print("we are done editing")
        updateButtonState()
    }
    
    func textViewDidChange(_ textView: UITextView) {
         //print("change")
        updateButtonState()
    }
}



