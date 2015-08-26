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
        
        pscope.addPermission(PermissionConfig(type: .Notifications, demands: .Required, message: "For if you want to receive notifications that people send directly to you"))
        pscope.addPermission(PermissionConfig(type: .CloudKit, demands: .Required, message: "So that other users can find you"))
        
        showPermissionScope()
        reactToiCloudloginChanges()
        super.viewDidLoad()
    }

    func showPermissionScope() {
        pscope.show({ (finished, results) -> Void in
            print("TODO: results is a PermissionsResult for each config")
            if finished {
                Async.main {
                    self.pscope.hide()
                }
                self.getUser()
            }
        }, cancelled: { (results) -> Void in
            print("WARNING: PermissionScope was cancelled")
        })
    }
    
    /**
    Registering for iCloud availability change notifications (log in as different user, clear all user related data)
    */
    func reactToiCloudloginChanges() {
        _ = NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquityIdentityDidChangeNotification, object: nil, queue: nil) { _ in
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
    func getUser() {
        self.loginLabel.hidden = true
        EVCloudKitDao.publicDB.getUserInfo({user in
                EVLog("discoverUserInfo : \(user.userRecordID?.recordName) = \(user.firstName) \(user.lastName)")

                Async.main {
                    let storyboard = UIStoryboard(name: "Storyboard", bundle: nil);
                     self.viewController = storyboard.instantiateViewControllerWithIdentifier("menuViewController")
                        self.presentViewController(self.viewController!, animated: false, completion: nil)
                    
                }
            }, errorHandler: { error in
                EVLog("ERROR in getUserInfo: \(error.description)");
                EVLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account. (It could also be that your project iCloud entitlements are wrong)")
                self.loginLabel.hidden = false

        })
    }
}
