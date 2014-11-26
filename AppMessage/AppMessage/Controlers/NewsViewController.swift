//
//  ContactsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

class NewsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, RESideMenuDelegate {
    
    var tableView: UITableView = UITableView()
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMenuTableViewLayout()
    }
    
    func setupMenuTableViewLayout() {
        var rect = CGRectMake(0, ((self.view.frame.size.height - 54 * 5) / 2.0), self.view.frame.size.width, 54 * 5)
        tableView = UITableView(frame: rect)
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
    
    // ------------------------------------------------------------------------
    // MARK: - tableView - menu items
    // ------------------------------------------------------------------------
    
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 54
    }
    
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EVCloudData.instance.data["News_All"]!.count
    }
    
    var cellIdentifier = "NewsCell";
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var allnews:Dictionary<String, News> = EVCloudData.instance.data["News_All"]! as Dictionary<String, News>
        var news:News = allnews[indexPath.row]!
        
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clearColor()
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.highlightedTextColor = UIColor.lightGrayColor()
            cell.selectedBackgroundView = UIView()
        }
        
        cell.textLabel?.text = news.Subject
        cell.detailTextLabel?.text = news.Body
        return cell;
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        var allnews:Dictionary<String, News> = EVCloudData.instance.data["News_All"]! as Dictionary<String, News>
        var news:News = allnews[indexPath.row]!
        let url:NSURL! = NSURL(string: news.ActionUrl)
        UIApplication.sharedApplication().openURL(url)
    }
}