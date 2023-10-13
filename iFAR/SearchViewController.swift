//
//  SearchViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/10/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK


class SearchViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    // MARK: - Properties
    @IBOutlet var tableView: UITableView!
    
    //var listItems:[Any]?
    
    let searchController = UISearchController(searchResultsController: nil)
    var keys:[String] = []
    var filteredkeys:[String] = []
    var indexItems:NSDictionary?
    
    func setupdata(){
        
        let path = Bundle.main.path(forResource: "index", ofType: "plist")
        indexItems = NSDictionary(contentsOfFile: path!)
        keys = indexItems!.allKeys as! [String]
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
        
        // Setup the search footer
        // tableView.tableFooterView = searchFooter
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            //searchFooter.setIsFilteringToShow(filteredItemCount: filteredCandies.count, of: candies.count)
            return filteredkeys.count
        }
        
       // searchFooter.setNotFiltering()
        
        return filteredkeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let content: String
        if isFiltering() {
            content = filteredkeys[indexPath.row]
        } else {
            content = keys[indexPath.row]
        }
        cell.textLabel!.text = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {


//            let term = filteredkeys[indexPath.row]
//            let termList = indexItems?.object(forKey: term)
//




    }
    

    
    // MARK: - Segues
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == "showDetail" {
    //            if let indexPath = tableView.indexPathForSelectedRow {
    //                let candy: Candy
    //                if isFiltering() {
    //                    candy = filteredCandies[indexPath.row]
    //                } else {
    //                    candy = candies[indexPath.row]
    //                }
    //                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
    //                controller.detailCandy = candy
    //                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
    //                controller.navigationItem.leftItemsSupplementBackButton = true
    //            }
    //        }
    //    }
    
    // MARK: - Private instance methods
    
    //    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
    //        filteredCandies = candies.filter({( candy : Candy) -> Bool in
    //            let doesCategoryMatch = (scope == "All") || (candy.category == scope)
    //
    //            if searchBarIsEmpty() {
    //                return doesCategoryMatch
    //            } else {
    //                return doesCategoryMatch && candy.name.lowercased().contains(searchText.lowercased())
    //            }
    //        })
    //        tableView.reloadData()
    //    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredkeys = keys.filter({( key : String) -> Bool in
            if searchBarIsEmpty() {
                return false
            } else {
                return key.lowercased().contains(searchText.lowercased())
            }
        })
        tableView.reloadData()
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        //        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        //        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
        
        return !searchBarIsEmpty()
    }
}

extension SearchViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension SearchViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        //let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

