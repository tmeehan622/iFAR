//
//  ScrollerViewController.swift
//  PDF-Demo
//
//  Created by Tom Meehan on 12/13/18.
//  Copyright © 2018 com.tzshlyt.demo. All rights reserved.
//

import UIKit
import PDFKit
import MessageUI
import Flurry_iOS_SDK


protocol ScrollerViewControllerDelegate: class{
    func scrollerViewController(_ scrollerViewController: ScrollerViewController, didSelectPage page: PDFPage)
}

class ScrollerViewController: UIViewController, MFMailComposeViewControllerDelegate{
   @IBOutlet weak var pdfviewer: PDFView!
    //var pdfviewer: PDFView!
    var viewwillappearshown = false
    var pagenum:Int = 0
    var range:(start:Int, end:Int, source:String)?
    var curPage:PDFPage?
    var pdfpages:[PDFPage]?
    var pdfdocument:PDFDocument?
    let appDelegate     = UIApplication.shared.delegate as! AppDelegate

    weak var delegate: ScrollerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        viewwillappearshown = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange(notification:)), name: Notification.Name.PDFViewPageChanged, object: nil)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Options", style: .plain, target: self, action: "optionButtonTapped")

        pdfdocument = PDFManager.shared.pdfDocument
        
        pdfviewer.document = pdfdocument
        pdfviewer.displayMode = PDFDisplayMode.singlePage
        pdfviewer.autoScales = true
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        pdfviewer.addGestureRecognizer(leftSwipe)
        pdfviewer.addGestureRecognizer(rightSwipe)
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Flurry.logEvent("PDF Page Opened", withParameters: nil);

        if curPage == nil {
            //print("curPage = nil")
            curPage = pdfdocument?.page(at: 0)
        }
        
        pagenum = Int(curPage!.label!)!
        range = PDFManager.shared.rangeForPage(pageNum: pagenum)
        //print(range!.source)
        viewwillappearshown = true

        pdfviewer.go(to: curPage!)
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

    @IBAction func AboutAction(_ sender: UIButton) {
        performSegue(withIdentifier: "flipper4", sender: sender)
    }
    
    func selectPageRange(_ st:Int, _ ed:Int){
        
        if pdfpages != nil{
            pdfpages?.removeAll()
        } else {
            pdfpages = []
        }
        
        let start = st - 1
        let last = ed - 1
        
        for indx in start...last{
            pdfpages?.append((pdfdocument?.page(at: indx))!)
        }
        
        //print("page count2: \(pdfpages!.count)")
    }

    func getAttachmentFilePaths()->[String]{
        var filepaths:[String] = []

        if pdfpages != nil {
            for pdfpage in pdfpages! {
                //print("Page Label: " + pdfpage.label! )
                let pi = pdfdocument?.index(for: pdfpage)
                
                let pIndex = pi!
                //print("Page Index: " + String(pIndex) )
                let pth = PDFManager.shared.getCreateFileFromPDFPage(pdfpage)
                if pth.count > 10 {
                    filepaths.append(pth)
                }
            }
        }
        
        return filepaths
    }
    
    func getArrayOfPDFFilesAsData()->[(name:String, data:Data)]{
        var dataArray:[(name:String, data:Data)] = []
        let filepaths = getAttachmentFilePaths()
        var errCount  = 0
        var tpl:(name:String, data:Data)
        
        if filepaths.count > 0 {
            for fpath in filepaths {
                let url = URL(fileURLWithPath: fpath)
                let fname = url.lastPathComponent
                do {
                    let attachmentData = try Data(contentsOf: url)
                    tpl.name = fname
                    tpl.data = attachmentData
                    dataArray.append(tpl)
                } catch let error {
                    //print("We have encountered error \(error.localizedDescription)")
                    errCount = errCount + 1
                }
            }
        }
        return dataArray
    }
    
    func presentEmailUI(includeAttachments:Bool){
        var attachmentArray:[(name:String, data:Data)] = []

        let htmlFileName = range?.source
        
        let bodyText = PDFManager.shared.htmlFileAsString(fileName:htmlFileName!)
        
        if includeAttachments == true {
             attachmentArray = getArrayOfPDFFilesAsData()
        }
        
        if MFMailComposeViewController.canSendMail() {
            Flurry.logEvent("Email UI Opened", withParameters: nil);

            let mailComposeViewController = MFMailComposeViewController()
            
            mailComposeViewController.mailComposeDelegate = self
            let htmlFileName = range?.source
            
            let bodyText = PDFManager.shared.htmlFileAsString(fileName:htmlFileName!)
            
            mailComposeViewController.setMessageBody(bodyText, isHTML: true)
            
            if attachmentArray.count > 0 {
                for tpl in attachmentArray{
                    mailComposeViewController.addAttachmentData(tpl.data, mimeType: "application/pdf", fileName: tpl.name)
                }
            }
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func InitiateEmailFlow(){
        
        if MFMailComposeViewController.canSendMail() {
            let startpage = range?.start
            let endpage = range?.end
            
            selectPageRange(startpage!,endpage!)
            
            //print("pages count   \(pdfpages!.count)")
       
            let count = pdfpages!.count
            
            presentAttachmentPreferenceUI(numAttachments:count)
        } else {
            let mailalert = UIAlertController(title: nil, message: "There appears to be no email account setup on this device.  Unable to send email", preferredStyle: .alert)
            
            mailalert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem

            let okaction = UIAlertAction(title: "Ok", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            mailalert.addAction(okaction)
            
            self.present(mailalert, animated: true, completion: nil)
        }
    }
    
    @objc private func handlePageChange(notification: Notification)
    {
        //print("Page changed")
        
        if viewwillappearshown == true {
            curPage = pdfviewer.currentPage
            let l = curPage?.label
            var pageInt = -1
            
            if l != nil {
                let pnum = Int(l!)!
                pageInt = pnum
            }
            
            if(pageInt > -1){
              pagenum = pageInt
            }
            
            let range = PDFManager.shared.rangeForPage(pageNum: pagenum)
            //print(range.source)
            //print("Range Start: \(range.start)")
            //print("Range End: \(range.end)")
        }
    }

    var counter:Int = 0
    
    func grabPage(_ pgeNum:Int){
//        let pdffile = pdfdocument?.page(at: pgeNum)
//        let i = pdfdocument?.index(for: pdffile!)
//        let lbl = pdffile?.label
        
        
       // selectPageRange(pgeNum,pgeNum)
        
       // let pdffile = pdfpages![0]
        
        let pth = PDFManager.shared.pagePathForPage(pgeNum)
     }
    
    func presentAttachmentPreferenceUI(numAttachments:Int){
        
        let ctString = String(numAttachments)
        let mess = "This email will contain " + ctString + " attachments.  Would you like to include these attachments?"
        let optionMenu = UIAlertController(title: mess, message: nil, preferredStyle: .actionSheet)
        
        let YESAction = UIAlertAction(title: "Yes", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.presentEmailUI(includeAttachments:true)
        })
        
        let NOAction = UIAlertAction(title: "No", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.presentEmailUI(includeAttachments:false)
        })
        
       // let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        optionMenu.addAction(YESAction)
        optionMenu.addAction(NOAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func mungeTitle(ttl:String)->String{
        var retString = ""
        
        let tempString1 = ttl.replacingOccurrences(of: "_", with: ".")//subpart.3.1.html
        let tempString2 = tempString1.replacingOccurrences(of: ".html", with: "")//subpart.3.1
        retString = tempString2.replacingOccurrences(of: "subpart.", with: "Page ")//subpart.3.1

        return retString
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "createbookmark"{
            let infoDict = sender as! (pagenum:Int,title:String)
            
            if let destController = segue.destination as? CreateFavoriteViewController{
                destController.mytitle = infoDict.title
                destController.linkedPageNum = infoDict.pagenum
            }
        }
    }
    
    @objc func optionButtonTapped() {
            //print(range?.source)
            let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        
            optionMenu.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
            let emailAction = UIAlertAction(title: "Send Email", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.InitiateEmailFlow()
            })

            let saveFavoriteAction = UIAlertAction(title: "Save as Favorite", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                let st        = self.range?.start
                let curpage = self.pdfviewer.currentPage
                let pageindx:Int = (self.pdfdocument?.index(for: curpage!))!
                let secInfo   = PDFManager.shared.sectionRecForPageNum(pageNum: st!)
                let TitleText = "Page " + (curpage?.label!)!
                let infoDict = (pagenum:pageindx, title:TitleText)

                self.performSegue(withIdentifier: "createbookmark", sender: infoDict)
            })
//(start:Int, end:Int, source:String)?
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            optionMenu.addAction(emailAction)
            optionMenu.addAction(saveFavoriteAction)
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
            //print("options tapped")
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        
        if (sender.direction == .left) {
            //print("Swipe Left")
            Flurry.logEvent("PDF Swipe Left", withParameters: nil);

            pdfviewer.goToNextPage(sender)
        }
        
        if (sender.direction == .right) {
            //print("Swipe Right")
            pdfviewer.goToPreviousPage(sender)
            Flurry.logEvent("PDF Swipe Right", withParameters: nil);
      }
    }

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
                Flurry.logEvent("Email Sent", withParameters: nil);

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

extension ScrollerViewController: ScrollerViewControllerDelegate {
    func scrollerViewController(_ scrollerViewController: ScrollerViewController, didSelectPage page: PDFPage) {
        pdfviewer.go(to: page)
    }
}
