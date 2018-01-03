//
//  LeftMenuViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import UIKit
import CloudKit
import EVCloudKitDao

class LeftMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView: UITableView!
    var newsController: NewsViewController!
    var chatViewController: ChatViewController?

    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenuTableViewLayout()

        connectToNews()

        connectToMessagesToMe()

        // Only already setup CloudKit connect's will receive these notifications (like the News above)
        EVCloudData.publicDB.fetchChangeNotifications({
            EVLog("All change notifications are processed")
            EVCloudKitDao.publicDB.setBadgeCounter(0)
        })
    }

    func setupMenuTableViewLayout() {
        let rect = CGRect(x: 0, y: ((self.view.frame.size.height - 54 * 5) / 2.0), width: self.view.frame.size.width, height: 54 * 5)
        self.tableView = UITableView(frame: rect)
        tableView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isOpaque = false
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        tableView.bounces = false
        tableView.scrollsToTop = false
        self.view.addSubview(self.tableView)

        newsController = self.storyboard?.instantiateViewController(withIdentifier: "newsViewController") as? NewsViewController
    }

    deinit {
        EVCloudData.publicDB.disconnect("News_All")
        EVCloudData.publicDB.disconnect("Message_ToMe")
    }

    // ------------------------------------------------------------------------
    // MARK: - tableView - menu items
    // ------------------------------------------------------------------------


    var titles = ["Home", "News", "Settings", "Search", "Tests"]
    var images = ["IconHome", "IconProfile", "IconSettings", "IconEmpty", "IconEmpty"]
    var controllers = ["homeViewController", "newsViewController", "settingsViewController", "searchViewController", "testsViewController"]

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }

    var cellIdentifier = "LeftMenuCell"
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 21)
            cell.textLabel?.textColor = UIColor.white
            cell.textLabel?.highlightedTextColor = UIColor.lightGray
            cell.selectedBackgroundView = UIView()
        }

        cell.textLabel?.text = titles[(indexPath as NSIndexPath).row]
        cell.imageView?.image = UIImage(named: images[(indexPath as NSIndexPath).row])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row < controllers.count {
            let controllerName: String = controllers[(indexPath as NSIndexPath).row]

            var controller: UIViewController?
            if controllerName == "newsViewController" {
                controller = newsController
            } else {
                controller = self.storyboard?.instantiateViewController(withIdentifier: controllerName)
            }
            if controller != nil {
                self.sideMenuViewController?.contentViewController = UINavigationController(rootViewController: controller!)
            }
        }
        self.sideMenuViewController?.hideMenuViewController()
    }

    func startChat(_ user: AnyObject) {
        if #available(iOS 10.0, *) {
            let firstName: String = (user as! CKUserIdentity).nameComponents?.givenName ?? ""
            let lastName: String = (user as! CKUserIdentity).nameComponents?.familyName ?? ""
            startChat((user as! CKUserIdentity).userRecordID!.recordName, firstName: firstName, lastName: lastName)
        } else {
            let firstName: String = (user as! CKDiscoveredUserInfo).firstName ?? ""
            let lastName: String = (user as! CKDiscoveredUserInfo).lastName ?? ""
            startChat((user as! CKDiscoveredUserInfo).userRecordID!.recordName, firstName: firstName, lastName: lastName)
        }
    }

    func startChat(_ recordId: String, firstName: String, lastName: String) {
        if self.chatViewController == nil {
            self.chatViewController = self.storyboard?.instantiateViewController(withIdentifier: "chatViewController") as? ChatViewController
        }
        self.sideMenuViewController?.contentViewController = UINavigationController(rootViewController: self.chatViewController!)
        if self.chatViewController!.chatWithId != recordId {
            chatViewController!.setContact(recordId, firstName: firstName, lastName: lastName)
        }
        self.sideMenuViewController!.hideMenuViewController()
    }
    
    // ------------------------------------------------------------------------
    // MARK: - News data and events
    // ------------------------------------------------------------------------

    func connectToNews(_ retryCount: Double = 1) {
        EVCloudData.publicDB.connect(
            News(), predicate: NSPredicate(value: true), orderBy: Ascending(field: "Subject").Descending("creationDate"), filterId: "News_All", configureNotificationInfo: { notificationInfo in
                //notificationInfo.alertBody = "News update"
                notificationInfo.shouldSendContentAvailable = true // is already the default
                notificationInfo.alertLocalizationKey = "News: %1$@"
                notificationInfo.alertLocalizationArgs = ["Subject"]
                notificationInfo.shouldBadge = true
                // notificationInfo.alertActionLocalizationKey = "subscrioptionActionMessage"
                // notificationInfo.alertLaunchImage = "alertImage"
                // notificationInfo.soundName = "alertSound"
                // notificationInfo.desiredKeys = [""]
            }, completionHandler: { results, status in
                EVLog("There are \(results.count) existing news items")
                return status == CompletionStatus.partialResult && results.count < 200 // Continue reading if we have less than 200 records and if there are more.
            }, insertedHandler: {item in
                EVLog("New News item: '\(item.Subject)'")
                Helper.showStatus("New News item: '\(item.Subject)'")
            }, updatedHandler: {item, dataIndex in
                EVLog("Updated News item:'\(item.Subject)'")
                Helper.showStatus("Updated News item:'\(item.Subject)'")
            }, deletedHandler: {recordId, dataIndex in
                EVLog("News item was removed")
                Helper.showStatus("News item was removed")
            }, dataChangedHandler : {
                EVLog("Some News data was changed")
                self.newsController.tableView.reloadData()
            }, errorHandler: {error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .retry(let timeToWait):
                    Async.background(after: timeToWait) {
                        self.connectToNews(retryCount + 1)
                    }
                case .fail:
                    Helper.showError("Could not load news: \(error.localizedDescription)")
                default: // For here there is no need to handle the .Success and .RecoverableError
                    break
                }
        })
    }

    func connectToMessagesToMe(_ retryCount: Double = 1) {
        let recordIdMe: String?
        if #available(iOS 10.0, *) {
            recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName
        } else {
            recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName
        }
        
        if recordIdMe == nil {
            return
        }
        EVCloudData.publicDB.connect(Message(), predicate: NSPredicate(format: "To_ID = %@", recordIdMe!), filterId: "Message_ToMe", configureNotificationInfo: { notificationInfo in
                notificationInfo.alertLocalizationKey = "%1$@ %2$@ : %3$@"
                notificationInfo.alertLocalizationArgs = ["FromFirstName", "FromLastName", "Text"]
            }, completionHandler: { results, status in
                EVLog("Message to me results = \(results.count)")
                return status == CompletionStatus.partialResult && results.count < 200 // Continue reading if we have less than 200 records and if there are more.
            }, insertedHandler: { item in
                EVLog("Message to me inserted \(item)")
                self.startChat(item.From_ID, firstName: item.ToFirstName, lastName: item.ToLastName)
            }, updatedHandler: { item, dataIndex in
                EVLog("Message to me updated \(item)")
            }, deletedHandler: { recordId, dataIndex in
                EVLog("Message to me deleted : \(recordId)")
            }, errorHandler: { error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .retry(let timeToWait):
                    Helper.showError("Could not load messages: \(error.localizedDescription)")
                    Async.background(after: timeToWait) {
                        self.connectToMessagesToMe(retryCount + 1)
                    }
                case .fail:
                    Helper.showError("Could not load messages: \(error.localizedDescription)")
                default: // For here there is no need to handle the .Success and .RecoverableError
                    break
                }

        })
    }
}

func showNameFor(_ contact: AnyObject) -> String {
    if #available(iOS 10.0, *) {
        return showNameFor10(contact as! CKUserIdentity)
    } else {
        return showNameFor9(contact as! CKDiscoveredUserInfo)
    }
    
}

@available(iOS 10.0, *)
func showNameFor10(_ contact: CKUserIdentity) -> String {
    let nickname = contact.nameComponents?.nickname ?? ""
    let givenName = contact.nameComponents?.givenName ?? ""
    let familyName = contact.nameComponents?.familyName ?? ""
    let nameSuffix = contact.nameComponents?.nameSuffix ?? ""
    let middleName = contact.nameComponents?.middleName ?? ""
    let namePrefix = contact.nameComponents?.namePrefix ?? ""
    let emailAddress = contact.lookupInfo?.emailAddress ?? ""
    let phoneNumber = contact.lookupInfo?.phoneNumber ?? ""
    
    let name = "\(nickname) - \(givenName) \(middleName) \(namePrefix) \(familyName) \(nameSuffix) - \(emailAddress) \(phoneNumber))"  // contact.userRecordID?.recordName
    return name.replacingOccurrences(of: "   ", with: " ").replacingOccurrences(of: "  ", with: " ")
}

func showNameFor9(_ contact: CKDiscoveredUserInfo) -> String {
    var firstName: String = ""
    var lastName: String = ""
    if #available(iOS 9.0, *) {
        firstName = contact.displayContact?.givenName ?? ""
        lastName = contact.displayContact?.familyName ?? ""
    } else {
        firstName = contact.firstName ?? ""
        lastName = contact.lastName ?? ""
    }
    return "\(firstName) \(lastName)"
}

