//
//  RightMenuViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit

class RightMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 54
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int{
        return 3
    }
    
    var cellIdentifier = "RightMenuCell";
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!{
        
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        
        if !cell {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clearColor()
            cell.textLabel.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel.textColor = UIColor.whiteColor()
            cell.textLabel.highlightedTextColor = UIColor.lightGrayColor()
            cell.selectedBackgroundView = UIView()
        }
        
        var titles = ["Nothing", "Here", "Yet"]
        cell.textLabel.text = titles[indexPath.row];
        cell.textLabel.textAlignment = .Right
        
        return cell;
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        var controllers: [String] = []
        if indexPath.row < controllers.count {
            var controller = self.storyboard.instantiateViewControllerWithIdentifier(controllers[indexPath.row]) as? UIViewController
            self.sideMenuViewController.setContentViewController(UINavigationController(rootViewController: controller), animated: true)
        }
        self.sideMenuViewController.hideMenuViewController()
    }
}