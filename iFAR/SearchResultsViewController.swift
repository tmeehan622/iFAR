
import UIKit
import Flurry_iOS_SDK


//struct pageRec2 {
//  var pagenum = ""
//  var title = ""
//
//    init(page:String,ttl:String){
//      pagenum = page
//      title = ttl
//     }
//}

class SearchResultsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tblView: UITableView!
    var searchTerm = ""
    var list:[NSNumber]?
    var outlineitems:Dictionary<String, Any>?
    var displayList:[Dictionary<String, String>] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDisplayList()
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
        performSegue(withIdentifier: "flipper1", sender: sender)
    }
    
    func setupDisplayList(){
         for num in list! {
            let pageint         = num.intValue + 1
            let pageTitle       = PDFManager.shared.titleForPage(pageint)
            let pageNumberText  = String(pageint)
            
            let pageDict:Dictionary = ["pageNumber":pageNumberText, "title":pageTitle]
            displayList.append(pageDict)
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
            // destController.pagenum = Int(pagenumstring)!
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseid = "plaincell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseid, for: indexPath)
        let dict = displayList[indexPath.row] as Dictionary
        let title = dict["title"]
        let ppg = dict["pageNumber"]

        let displayText = "Pg. " + ppg! + ": " + title!
        cell.textLabel!.text = displayText
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let dict = displayList[indexPath.row] as Dictionary
        let ppg = dict["pageNumber"]
        Flurry.logEvent("Selected Page From Search", withParameters: nil);

        performSegue(withIdentifier: "searchdirect", sender: ppg)
    }
}
