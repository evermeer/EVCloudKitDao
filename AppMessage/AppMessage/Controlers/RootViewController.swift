//
//  RootViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import EVCloudKitDao

class RootViewController: UIViewController {

    @IBOutlet weak var loginLabel: UILabel!

    var viewController: UIViewController?

    override func viewDidLoad() {
        reactToiCloudloginChanges()
        self.getUser()
        super.viewDidLoad()
    }

    
    /**
    Registering for iCloud availability change notifications (log in as different user, clear all user related data)
    */
    func reactToiCloudloginChanges() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil, queue: nil) { _ in
            EVLog("The user’s iCloud login changed: should refresh all user data.")
            Async.main {
                self.viewController?.removeFromParentViewController()
            }
            return
        }
    }

    /**
     
    As what ugetUserser are we loged in to iCloud. Then open the main app.
    */
    func getUser(_ retryCount:Double = 1) {
        Async.main {
            self.loginLabel.isHidden = true
        }
        
        EVCloudKitDao.publicDB.requestDiscoverabilityPermission({ (granted) -> Void in
            if !granted {
                Helper.showError("Discoverability has been denied. You will not be able to be found by other user. You can change this in the settings app, iCloud, iCloud drive, discover by email")
            }
            }) { (error) -> Void in
                Helper.showError("Unable to request discoverability.") //TODO: auto open app settings?
        }
        
        EVCloudKitDao.publicDB.discoverUserInfo({ (user) -> Void in
                EVLog("discoverUserInfo : \(showNameFor(user))")
                Async.main {
                    let storyboard = UIStoryboard(name: "Storyboard", bundle: nil);
                     self.viewController = storyboard.instantiateViewController(withIdentifier: "menuViewController")
                        self.present(self.viewController!, animated: false, completion: nil)
                    
                }
            }, errorHandler: { error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .retry(let timeToWait):
                    EVLog("ERROR in getUserInfo: Can retry after \(timeToWait)")
                    Async.background(after: timeToWait) {
                        self.getUser(retryCount + 1)
                    }
                case .fail:
                    EVLog("ERROR in getUserInfo: \(error.localizedDescription)");
                    EVLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account. (It could also be that your project iCloud entitlements are wrong)")
                    Helper.showError("Could not get user: \(error.localizedDescription)")
                default: // For here there is no need to handle the .Success, and .RecoverableError
                    break
                }
                
        })
    }
}
