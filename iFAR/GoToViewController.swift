//
//  GoToViewController.swift
//  PDF-Demo
//
//  Created by Tom Meehan on 12/14/18.
//  Copyright © 2018 com.tzshlyt.demo. All rights reserved.
//

import UIKit
import PDFKit
import Flurry_iOS_SDK


protocol GoToViewControllerDelegate: class{
    func goToViewController(_ goToViewController: GoToViewController, didSelectPage page: PDFPage)
}

struct pageRec {
    
  var text = ""
    var start:Int = 0
    var end:Int = 0

    init(_ txt:String, _ st:Int, _ last:Int){
        text = txt
        start = st
        end = last
     }
}

class GoToViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var pdfdocument:PDFDocument?
    var dataSource:[pageRec] = []
    var pdfpages:[PDFPage]?
    var MAX_PAGE = 0
    
    @IBOutlet weak var SectionInfoLabel: UILabel!
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var myTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myTextField.backgroundColor = UIColor.white
        collectionview?.register(UINib(nibName: "GotoPageCellCollectionViewCell", bundle: nil),forCellWithReuseIdentifier: "GotoCell")
        
        pdfdocument = PDFManager.shared.pdfDocument

        MAX_PAGE = (pdfdocument?.pageCount)! - 1
        
        initDataSource()
        updateInfoLabel()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//      
//    }
 
    
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

    func updateSectionInfoLabel(txt:String){
        if pdfpages == nil {
            let pgcount         = pdfdocument?.pageCount
            SectionInfoLabel.text = "Viewing pages: 0 - " + String(pgcount!)
        } else {
            SectionInfoLabel.text = txt
        }
    }
    
    func updateInfoLabel(_ start:Int = 0, _ end:Int = 0){
        
        let first = String(start + 1)
        var last = String(end + 1)
        var displayString = ""
        
        if pdfpages == nil {
           let pgcount      = pdfdocument?.pageCount
           displayString    = "Viewing pages: 1 - " + String(pgcount!)
        } else {
           displayString    = "Viewing pages: " + first + " - " + last
        }
        
        SectionInfoLabel.text = displayString
    }

    func selectPageRange(_ st:Int, _ ed:Int){
      
        if pdfpages != nil{
            pdfpages?.removeAll()
        } else {
            pdfpages = []
        }
        
        for indx in st...ed{
            pdfpages?.append((pdfdocument?.page(at: indx))!)
        }
        
        //print("page count2: \(pdfpages!.count)")

        updateInfoLabel(st, ed)

        collectionview.reloadData()
    }
    
    func initDataSource(){
        
        let c = PDFManager.shared.sectionCount()
        //print("Init Data Source BEGIN")
        
        for inforec in PDFManager.shared.sectionInfo{
            let startpage = inforec.start
            if startpage > -1 {
                var endpagenum = 0
                var startpagenum = 0
                var sectiontitle = ""
               //print(" Start page index: \(startpage)")

                //    func rangeForPage(pageNum:Int)->(start:Int, end:Int, source:String){

                
                let range = PDFManager.shared.rangeForPage(pageNum: startpage)
                endpagenum = range.end
                startpagenum = range.start
                
                //print(" Range For Page: \(startpagenum) - \(endpagenum)\n")
                sectiontitle = PDFManager.shared.titleForPage(startpage)
                
                //print(" Title For Page: \(startpagenum)" + sectiontitle)

                let currec = pageRec(sectiontitle,startpagenum,endpagenum)
                dataSource.append(currec)
            }
        }
        //print("Init Data Source END")

    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "plaincell", for: indexPath) as! UITableViewCell
        
        let txtLabel  = cell.contentView.viewWithTag(10) as! UILabel
       // let pgLabel   = cell.contentView.viewWithTag(11) as! UILabel
        let pgrec     = dataSource[indexPath.row]
        txtLabel.text = pgrec.text
     /*
        if pgrec.start == pgrec.end {
           pgLabel.text = ""
        } else {
            let startstring = String(pgrec.start)
            let endstring   = String(pgrec.end)
            let rangestring = "Pages: " + startstring + " - " + endstring
            pgLabel.text    = rangestring
        }
    */
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let pgrec = dataSource[indexPath.row]
        let start = pgrec.start - 1
        let end = pgrec.end - 1

        selectPageRange(start,end)
      }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showpage" {
            let page                = sender as! PDFPage
            let pdfcontroller       = segue.destination as! ScrollerViewController
            pdfcontroller.curPage   = page
        }
      }
}

extension GoToViewController: UITextFieldDelegate {
    
    func textAsInt(_ tf:UITextField)->Int{
       var retVal = -1
        
        if tf.text != nil{
            let myText:String = tf.text!
            
            if myText.count > 0 {
                retVal = Int(myText)!
             }
        }
        return retVal
     }
    
    func isDigit(_ s: String) -> Bool {
        let cs = CharacterSet.decimalDigits
        for us in s.unicodeScalars {
            if !cs.contains(us) {
                return false
            }
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
       return isDigit(string)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        
        var intval          = textAsInt(textField)
        let pgcount         = pdfdocument?.pageCount
        var numpages:Int    = 0
        
        if pgcount != nil {
            numpages = pgcount!
        }
        
        if intval > numpages {
            intval = numpages
        }
        
        let pagerange = PDFManager.shared.rangeForPage(pageNum: intval)
        
        let start = pagerange.start
        let end   = pagerange.end
        
        selectPageRange(start-1,end-1)
        
        textField.resignFirstResponder()
       return true
        
    }
 }

extension GoToViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var count = 0
        
        if pdfpages == nil {
           count = (pdfdocument?.pageCount)!
        } else {
           count = pdfpages!.count
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GotoCell", for: indexPath)  as! GotoPageCellCollectionViewCell
        
        let page:PDFPage?
        
        if pdfpages == nil {
           page = pdfdocument?.page(at: indexPath.item)
        } else {
           page = pdfpages![indexPath.item]
        }
        
        if page != nil {
            let thumbnail = page!.thumbnail(of: cell.bounds.size, for: PDFDisplayBox.cropBox)
            cell.image = thumbnail
            cell.pageLab.text = page!.label
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var page:PDFPage?
        
        if pdfpages == nil {
            page = pdfdocument?.page(at: indexPath.item)
        } else {
            page = pdfpages![indexPath.item]
        }

        performSegue(withIdentifier: "showpage", sender: page)
    }
}
