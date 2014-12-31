//
//  RightMenuViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import CloudKit

class RightMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var contacts: [CKDiscoveredUserInfo]! = []
    var tableView: UITableView!
    
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContactsTableViewLayout()
        loadContacts()
    }
    
    func setupContactsTableViewLayout() {
        var rect = CGRectMake(0, ((self.view.frame.size.height - 54 * 5) / 2.0), self.view.frame.size.width, 54 * 5)
        self.tableView = UITableView(frame: rect)
        tableView.autoresizingMask = .FlexibleTopMargin | .FlexibleBottomMargin | .FlexibleWidth
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
    
    func loadContacts() {
        // Look who of our contact is also using this app.
        EVCloudKitDao.publicDB.allContactsUserInfo({ users in
                NSLog("AllContactUserInfo count = \(users.count)");
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.contacts = users
                    self.tableView.reloadData()
                })
            }, errorHandler: { error in
                Helper.showError("Could not load contacts: \(error.description)")
        })

    }
    
    // ------------------------------------------------------------------------
    // MARK: - tableView for contacts and open chat
    // ------------------------------------------------------------------------

    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 54
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    var cellIdentifier = "RightMenuCell";
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clearColor()
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.textLabel?.highlightedTextColor = UIColor.lightGrayColor()
            cell.selectedBackgroundView = UIView()
            cell.textLabel?.textAlignment = .Right
        }
        cell.textLabel?.text = "\(contacts[indexPath.row].firstName) \(contacts[indexPath.row].lastName)" ;
        return cell;
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        var controller : ChatViewController! = self.storyboard?.instantiateViewControllerWithIdentifier("chatViewController") as? ChatViewController
            if controller != nil {
                controller.setContact(contacts[indexPath.row])
                self.sideMenuViewController.setContentViewController(UINavigationController(rootViewController: controller!), animated: true)
            }
        self.sideMenuViewController.hideMenuViewController()
    }
}