import UIKit
import Flurry_iOS_SDK

class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchFooter: SearchFooter!
    
    //var listItems:[Any]?
    
    let searchController = UISearchController(searchResultsController: nil)
    var keys:[String] = []
    var filteredkeys:[String] = []
    var indexItems:NSDictionary = [:]
    var outlineItems:NSDictionary = [:]

    func setupdata(){
        let path = Bundle.main.path(forResource: outlineFileName, ofType: "plist")
        outlineItems = NSDictionary(contentsOfFile: path!)!

        let path2 = Bundle.main.path(forResource: indexFileName, ofType: "plist")
        indexItems = NSDictionary(contentsOfFile: path2!)!
        keys = indexItems.allKeys as! [String]
        keys.sort()
        
    }
    
    // MARK: - View Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        setupdata()
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Text"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Flurry.logEvent("Search Opened", withParameters: nil);
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


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredkeys.count
        }
          return filteredkeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content: String
        if isFiltering() {
            let term = filteredkeys[indexPath.row]
            let termList:[NSNumber] = indexItems.object(forKey: term) as! [NSNumber]
            let c = termList.count
            
            content = filteredkeys[indexPath.row]
            if c > 0{
             content = content + " (" + String(c) + ")"
            }
        } else {
            content = keys[indexPath.row]
        }
        cell.textLabel!.text = content
        cell.detailTextLabel?.text = ""
        return cell
    }
    var param_term = ""
    var param_value:[NSNumber] = []
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let term = filteredkeys[indexPath.row]
        let termList:[NSNumber] = indexItems.object(forKey: term) as! [NSNumber]
        
        if(termList.count > 1){
            let searchResultsCntrl = SearchResultsViewController()
            
            param_term = term
            param_value = termList
            
            searchResultsCntrl.outlineitems = outlineItems as? Dictionary<String, Any>
            searchResultsCntrl.searchTerm = term
            searchResultsCntrl.list = termList
            
            performSegue(withIdentifier: "searchresults", sender: self)
        
        } else {
            if(termList.count == 1){
                //print("spage: \(termList[0])")
            } else {
                //print("no page")
            }
        }
    }

    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredkeys = keys.filter({( key : String) -> Bool in
              if searchBarIsEmpty() {
                return false
            } else {
                var rslt = key.lowercased().contains(searchText.lowercased())
                
                if rslt == true{
                    
                   print ("got one")
                }
                return key.lowercased().contains(searchText.lowercased())
            }
        })
        tableView.reloadData()
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {

        return !searchBarIsEmpty()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destController = segue.destination as? SearchResultsViewController{
            //print("hello")
            destController.searchTerm = self.param_term
            destController.list = self.param_value
            destController.outlineitems = outlineItems as? Dictionary<String, Any>
            
       
//            let searchResultsCntrl = SearchResultsViewController()
//            searchResultsCntrl.outlineitems = outlineItems as? Dictionary<String, Any>
//            searchResultsCntrl.searchTerm = term
//            searchResultsCntrl.list = termList

        
        }
        
      }

    
    
    
    
}

extension MasterViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension MasterViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

