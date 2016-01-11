//
//  RootViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import Async
import PermissionScope

class RootViewController: UIViewController {

    @IBOutlet weak var loginLabel: UILabel!

    var viewController: UIViewController?
    var pscope:PermissionScope = PermissionScope()

    override func viewDidLoad() {
        pscope.headerLabel.text = "Setting permissions"
        pscope.bodyLabel.text = "For optimal usage we need some permissions."
        pscope.addPermission(NotificationsPermission(notificationCategories: nil),
            message: "For if you want to receive notifications that people send directly to you")
        pscope.addPermission(CloudKitPermission(),
            message: "So that other users can find you")
        showPermissionScope()
        reactToiCloudloginChanges()
        super.viewDidLoad()
    }

    func showPermissionScope() {
        pscope.show({ (finished, results) -> Void in
            if finished {
                Async.main {
                    self.pscope.hide()
                }
                self.getUser()
            }
            }, cancelled: { (results: [PermissionResult]) -> Void in
                if (results.filter {$0.type == .CloudKit && $0.status == .Authorized}).count > 0  {
                    self.getUser()
                }
            print("WARNING: PermissionScope was cancelled")
        })
    }
    
    /**
    Registering for iCloud availability change notifications (log in as different user, clear all user related data)
    */
    func reactToiCloudloginChanges() {
        NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquityIdentityDidChangeNotification, object: nil, queue: nil) { _ in
            EVLog("The user’s iCloud login changed: should refresh all user data.")
            Async.main {
                self.viewController?.removeFromParentViewController()
                self.pscope.hide()
                Async.main(after: 1, block: { () -> Void in
                    self.showPermissionScope()
                })
            }
            return
        }
    }

    /**
    As what user are we loged in to iCloud. Then open the main app.
    */
    func getUser(retryCount:Double = 1) {
        self.loginLabel.hidden = true
        
        EVCloudKitDao.publicDB.requestDiscoverabilityPermission({ (granted) -> Void in
            if !granted {
                Helper.showError("Discoverability has been denied. You will not be able to be found by other user. You can change this in the settings app, iCloud, iCloud drive, discover by email")
            }
            }) { (error) -> Void in
                Helper.showError("Unable to request discoverability.")
        }
        
        EVCloudKitDao.publicDB.discoverUserInfo({ (user) -> Void in
                if #available(iOS 9.0, *) {
                    EVLog("discoverUserInfo : \(user.userRecordID?.recordName) = \(user.displayContact?.givenName ?? "") \(user.displayContact?.familyName ?? "")")
                } else {
                    EVLog("discoverUserInfo : \(user.userRecordID?.recordName) = \(user.firstName) \(user.lastName)")
                }

                Async.main {
                    let storyboard = UIStoryboard(name: "Storyboard", bundle: nil);
                     self.viewController = storyboard.instantiateViewControllerWithIdentifier("menuViewController")
                        self.presentViewController(self.viewController!, animated: false, completion: nil)
                    
                }
            }, errorHandler: { error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .Retry(let timeToWait):
                    EVLog("ERROR in getUserInfo: Can retry after \(timeToWait)")
                    Async.background(after: timeToWait) {
                        self.getUser(retryCount + 1)
                    }
                case .Fail:
                    EVLog("ERROR in getUserInfo: \(error.description)");
                    EVLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account. (It could also be that your project iCloud entitlements are wrong)")
                    Helper.showError("Could not get user: \(error.localizedDescription)")
                default: // For here there is no need to handle the .Success, and .RecoverableError
                    break
                }
                
        })
    }
}
