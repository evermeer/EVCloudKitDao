//
//  RootViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var contacting: UILabel!
    
    override func viewDidLoad() {
        reactToiCloudloginChanges()
        getUser()
        super.viewDidLoad()
    }
    
    /**
    Registering for iCloud availability change notifications (log in as different user, clear all user related data)
    */
    func reactToiCloudloginChanges() {
        var ubiquityIdentityDidChangeNotificationToken = NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquityIdentityDidChangeNotification, object: nil, queue: nil) { _ in
            EVLog("The user’s iCloud login changed: should refresh all user data.")
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.getUser()
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
                EVLog("discoverUserInfo : \(user.userRecordID.recordName) = \(user.firstName) \(user.lastName)");
                        
                NSOperationQueue.mainQueue().addOperationWithBlock(){
                    let storyboard = UIStoryboard(name: "Storyboard", bundle: nil);
                    let viewController = storyboard.instantiateViewControllerWithIdentifier("menuViewController") as! UIViewController;
                    self.presentViewController(viewController, animated: false, completion: nil);
                }
            }, errorHandler: { error in
                EVLog("ERROR in getUserInfo");
                EVLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account. (It could also be that your project iCloud entitlements are wrong)")
                self.loginLabel.hidden = false
                self.contacting.hidden = true

        })
    }
}
