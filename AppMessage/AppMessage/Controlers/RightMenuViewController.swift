//
//  RightMenuViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import CloudKit
import EVCloudKitDao

class RightMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    //CKUserIdentity or CKDiscoveredUserInfo
    var contacts: [AnyObject] = []
    
    var tableView: UITableView!
    var leftMenu: LeftMenuViewController!

    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContactsTableViewLayout()
        loadContacts()
    }

    func setupContactsTableViewLayout() {
        let rect = CGRect(x: 0, y: ((self.view.frame.size.height - 54 * 5) / 2.0), width: self.view.frame.size.width, height: 54 * 5)
        self.tableView = UITableView(frame: rect)
        tableView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isOpaque = false
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        tableView.bounces = true
        tableView.scrollsToTop = true
        self.view.addSubview(self.tableView)
    }

    func loadContacts(_ retryCount:Double = 1) {        
        // Look who of our contact is also using this app.        
        EVCloudKitDao.publicDB.allContactsUserInfo({ users in
                EVLog("AllContactUserInfo count = \(users?.count ?? 0)");
                Async.main{
                    self.contacts = users ?? []
                    self.tableView.reloadData()
                }
            }, errorHandler: { error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .retry(let timeToWait):
                    Async.background(after: timeToWait) {
                        self.loadContacts(retryCount + 1)
                    }
                default: // For here there is no need to handle the .Success, .Fail and .RecoverableError
                    break
                }
        })

    }

    // ------------------------------------------------------------------------
    // MARK: - tableView for contacts and open chat
    // ------------------------------------------------------------------------


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    var cellIdentifier = "RightMenuCell";
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.white
            cell.textLabel?.highlightedTextColor = UIColor.lightGray
            cell.selectedBackgroundView = UIView()
            cell.textLabel?.textAlignment = .right
        }
        
        let contact = contacts[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = showNameFor(contact);
        return cell;
    }

    
    func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath) {
        leftMenu.startChat(self.contacts[(indexPath as NSIndexPath).row])
    }

}
