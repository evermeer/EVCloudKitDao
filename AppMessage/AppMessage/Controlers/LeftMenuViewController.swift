//
//  LeftMenuViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import UIKit

class LeftMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RESideMenuDelegate {
    
    var tableView: UITableView!
    var newsController: NewsViewController!
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenuTableViewLayout()

        connectToNews()
        
        // Only already setup CloudKit connect's will receive these notifications (like the News above)
        EVCloudData.instance.fetchChangeNotifications()        
    }
    
    func setupMenuTableViewLayout() {
        var rect = CGRectMake(0, ((self.view.frame.size.height - 54 * 5) / 2.0), self.view.frame.size.width, 54 * 5)
        self.tableView = UITableView(frame: rect)
        tableView.autoresizingMask = .FlexibleTopMargin | .FlexibleBottomMargin | .FlexibleWidth
        tableView.delegate = self
        tableView.dataSource = self
        tableView.opaque = false
        tableView.backgroundColor = UIColor.clearColor()
        tableView.backgroundView = nil
        tableView.separatorStyle = .None
        tableView.bounces = false
        tableView.scrollsToTop = false
        self.view.addSubview(self.tableView)
        
        newsController = self.storyboard?.instantiateViewControllerWithIdentifier("newsViewController") as? NewsViewController
        
    }
    
    deinit {
        EVCloudData.instance.disconnect("News_All")
    }

    // ------------------------------------------------------------------------
    // MARK: - tableView - menu items
    // ------------------------------------------------------------------------

    
    var titles = ["Home", "News", "Settings", "Tests"]
    var images = ["IconHome", "IconProfile", "IconSettings", "IconEmpty"]
    var controllers = ["homeViewController", "newsViewController", "settingsViewController", "testsViewController"]

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 54
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    var cellIdentifier = "LeftMenuCell";
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clearColor()
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.textLabel?.highlightedTextColor = UIColor.lightGrayColor()
            cell.selectedBackgroundView = UIView()
        }
        
        cell.textLabel?.text = titles[indexPath.row]
        cell.imageView?.image = UIImage(named: images[indexPath.row])
        
        return cell;
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        if indexPath.row < controllers.count {
            var controllerName:String = controllers[indexPath.row]
            
            var controller:UIViewController?
            if controllerName == "newsViewController" {
                controller = newsController
            } else {
                controller = self.storyboard?.instantiateViewControllerWithIdentifier(controllerName) as? UIViewController
            }
            if controller != nil {
                self.sideMenuViewController.setContentViewController(UINavigationController(rootViewController: controller!), animated: true)
            }
        }
        self.sideMenuViewController.hideMenuViewController()
    }

    
    // ------------------------------------------------------------------------
    // MARK: - News data and events
    // ------------------------------------------------------------------------
    
    
    func connectToNews() {
        
        EVCloudData.instance.connect(News()
            , predicate: NSPredicate(value: true)
            , filterId: "News_All"
            , configureNotificationInfo: { notificationInfo in
                notificationInfo.alertBody = "News update"
                notificationInfo.shouldSendContentAvailable = true
                // notificationInfo.alertLocalizationKey = "subscriptionMessage"
                // notificationInfo.alertLocalizationArgs = [recordType, filterId]
                // notificationInfo.alertActionLocalizationKey = "subscrioptionActionMessage"
                // notificationInfo.alertLaunchImage = "alertImage"
                // notificationInfo.soundName = "alertSound"
                // notificationInfo.shouldBadge = true
                // notificationInfo.desiredKeys = [""]
            }
            , completionHandler: { results in
                NSLog("There are \(results.count) existing news items")
                self.newsController.tableView.reloadData()
            }, insertedHandler: {item in
                Helper.showStatus("New News item: '\((item as News).Subject)'")
                self.newsController.tableView.reloadData()
            }, updatedHandler: {item in
                Helper.showStatus("Updated News item:'\((item as News).Subject)'")
                self.newsController.tableView.reloadData()
            }, deletedHandler: {recordId in
                Helper.showStatus("News item was removed")
                self.newsController.tableView.reloadData()
            }, errorHandler: {error in
                Helper.showError("Could not load news: \(error.description)")
        })
    }
    
}