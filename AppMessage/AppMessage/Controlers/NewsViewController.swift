//
//  ContactsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit

class NewsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView: UITableView = UITableView()

    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenuTableViewLayout()
    }

    func setupMenuTableViewLayout() {
        let rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        tableView = UITableView(frame: rect)
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

    // ------------------------------------------------------------------------
    // MARK: - tableView - menu items
    // ------------------------------------------------------------------------

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //To prevent copying the dictionary never assign it to a variable first.
        return EVCloudData.publicDB.data["News_All"]!.count
    }

    var cellIdentifier = "NewsCell";
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clearColor()
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.highlightedTextColor = UIColor.lightGrayColor()
            cell.selectedBackgroundView = UIView()
        }

        //This line all you need to get the correct data for the cell
        if let news: News = EVCloudData.publicDB.data["News_All"]![indexPath.row] as? News {
            cell.textLabel?.text = "\(news.Subject)"
            cell.detailTextLabel?.text = "(\(news.creationDate)) - \(news.Body)"
        }

        return cell;
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //This line all you need to get the correct data for cell that is selected
        if let news: News = EVCloudData.publicDB.data["News_All"]![indexPath.row] as? News {
            if let url: NSURL = NSURL(string: news.ActionUrl) {
                UIApplication.sharedApplication().openURL(url)
            }
        }

    }
}
