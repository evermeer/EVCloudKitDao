//
//  SearchViewController.swift
//
//  Created by Edwin Vermeer on 3/25/15.
//  Copyright (c) 2015. All rights reserved.
//

import RESideMenu

class SearchViewController  : UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate, RESideMenuDelegate {
    
    var queryRunning:Int = 0
    var data:[Message] = []
    
    // ------------------------------------------------------------------------
    // MARK: - Search filter
    // ------------------------------------------------------------------------
    
    
    
    // You should also filter if a message is from or to the activeUser by adding this to the predecate:
    //   AND (From_ID = %@ OR To_ID = %@)
    
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        if self.searchDisplayController!.searchBar.selectedScopeButtonIndex > 0 {
            self.filterContentForSearchTextV2(searchString)
        } else {
            self.filterContentForSearchText(searchString)
        }
        return false
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        if self.searchDisplayController!.searchBar.selectedScopeButtonIndex > 0 {
            self.filterContentForSearchTextV2(self.searchDisplayController!.searchBar.text)
        } else {
            self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
        }
        return false
    }

    // Token search (search for complete words in the entire record
    func filterContentForSearchText(searchText: String) {
        EVLog("Filter for \(searchText)")
        networkSpinner(1)
        EVCloudKitDao.publicDB.query(Message(), tokens: searchText, completionHandler: { results in
            EVLog("query for tokens '\(searchText)' result count = \(results.count)")
            self.data = results
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.searchDisplayController!.searchResultsTableView.reloadData()
                self.tableView.reloadData()
                self.networkSpinner(-1)
            }
        }, errorHandler: { error in
            EVLog("ERROR: query Message for words \(searchText)")
            self.networkSpinner(-1)
        })
    }

    // Just search the Message.Text field if it contains the searchText
    func filterContentForSearchTextV2(searchText: String) {
        EVLog("Filter for \(searchText)")
        networkSpinner(1)
        EVCloudKitDao.publicDB.query(Message(), predicate: NSPredicate(format: "Text BEGINSWITH %@", searchText)!, completionHandler: { results in
            EVLog("query for tokens '\(searchText)' result count = \(results.count)")
            self.data = results
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.searchDisplayController!.searchResultsTableView.reloadData()
                self.tableView.reloadData()
                self.networkSpinner(-1)
            }
            }, errorHandler: { error in
                EVLog("ERROR: query Message for words \(searchText)")
                self.networkSpinner(-1)
        })
    }
    
    func networkSpinner(adjust: Int) {
        self.queryRunning = self.queryRunning + adjust
        UIApplication.sharedApplication().networkActivityIndicatorVisible = self.queryRunning > 0
    }
    
    
    
    
    // ------------------------------------------------------------------------
    // MARK: - tableView - Search result items
    // ------------------------------------------------------------------------
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Folowin_Search_Cell";
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
                if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
        }
        
        var item:Message = data[indexPath.row]
        cell.textLabel?.text = item.Text
        return cell;
    }
    
}