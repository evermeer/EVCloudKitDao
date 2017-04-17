//
//  ContactsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import EVCloudKitDao

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
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        tableView = UITableView(frame: rect)
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

    // ------------------------------------------------------------------------
    // MARK: - tableView - menu items
    // ------------------------------------------------------------------------

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //To prevent copying the dictionary never assign it to a variable first.
        return EVCloudData.publicDB.data["News_All"]!.count
    }

    var cellIdentifier = "NewsCell";
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.black
            cell.textLabel?.highlightedTextColor = UIColor.lightGray
            cell.selectedBackgroundView = UIView()
        }

        //This line all you need to get the correct data for the cell
        if let news: News = EVCloudData.publicDB.data["News_All"]![(indexPath as NSIndexPath).row] as? News {
            cell.textLabel?.text = "\(news.Subject)"
            cell.detailTextLabel?.text = "(\(news.creationDate)) - \(news.Body)"
        }

        return cell;
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //This line all you need to get the correct data for cell that is selected
        if let news: News = EVCloudData.publicDB.data["News_All"]![(indexPath as NSIndexPath).row] as? News {
            if let url: URL = URL(string: news.ActionUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }

    }
}
