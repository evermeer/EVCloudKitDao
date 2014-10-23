//
//  RootViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var loginLabel: UILabel!
    
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
            NSLog("The user’s iCloud login changed: should refresh all user data.")
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
        EVCloudKitDao.instance.getUserInfo({user in
                NSLog("discoverUserInfo : \(user.userRecordID.recordName) = \(user.firstName) \(user.lastName)");
                        
                NSOperationQueue.mainQueue().addOperationWithBlock(){
                    let storyboard = UIStoryboard(name: "Storyboard", bundle: nil);
                    let viewController = storyboard.instantiateViewControllerWithIdentifier("menuViewController") as UIViewController;
                    self.presentViewController(viewController, animated: false, completion: nil);
                }
            }, errorHandler: { error in
                NSLog("<--- ERROR in getUserInfo");
                NSLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account")
                self.loginLabel.hidden = false

        })
    }
}
