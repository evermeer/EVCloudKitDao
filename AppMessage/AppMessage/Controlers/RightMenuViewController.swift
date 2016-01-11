//
//  RightMenuViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import CloudKit
import Async

class RightMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var contacts: [CKDiscoveredUserInfo]! = []
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
        let rect = CGRectMake(0, ((self.view.frame.size.height - 54 * 5) / 2.0), self.view.frame.size.width, 54 * 5)
        self.tableView = UITableView(frame: rect)
        tableView.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleWidth]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.opaque = false
        tableView.backgroundColor = UIColor.clearColor()
        tableView.backgroundView = nil
        tableView.separatorStyle = .None
        tableView.bounces = true
        tableView.scrollsToTop = true
        self.view.addSubview(self.tableView)
    }

    func loadContacts(retryCount:Double = 1) {        
        // Look who of our contact is also using this app.        
        EVCloudKitDao.publicDB.allContactsUserInfo({ users in
                EVLog("AllContactUserInfo count = \(users.count)");
                Async.main{
                    self.contacts = users
                    self.tableView.reloadData()
                }
            }, errorHandler: { error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .Retry(let timeToWait):
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


    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    var cellIdentifier = "RightMenuCell";
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clearColor()
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.textLabel?.highlightedTextColor = UIColor.lightGrayColor()
            cell.selectedBackgroundView = UIView()
            cell.textLabel?.textAlignment = .Right
        }
        var firstName: String = ""
        var lastName: String = ""
        if #available(iOS 9.0, *) {
            firstName = contacts[indexPath.row].displayContact?.givenName ?? ""
            lastName = contacts[indexPath.row].displayContact?.familyName ?? ""
        } else {
            firstName = contacts[indexPath.row].firstName ?? ""
            lastName = contacts[indexPath.row].lastName ?? ""
        }
        
        cell.textLabel?.text = "\(firstName) \(lastName)" ;
        return cell;
    }

    func tableView(tableView: UITableView,didSelectRowAtIndexPath indexPath: NSIndexPath) {
        leftMenu.startChat(self.contacts[indexPath.row])
    }
}
