//
//  ContactsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014. All rights reserved.
//

class ContactsViewController : UIViewController {
    
    var users: [AnyObject]!
    
    override func viewDidLoad() {
        getUsers()
        super.viewDidLoad()
    }
    
    func getUsers(){
        // Look who of our contact is also using this app.
        // the To for the test message will be the last contact in the list
        EVCloudKitDao.instance.allContactsUserInfo({ users in
            NSLog("AllContactUserInfo count = \(users.count)");
            self.users = users

            for user: AnyObject in users {
                NSLog("Firstname: \(user.firstName), Lastname: \(user.lastName), RecordId: \(user.userRecordID?.recordName)")
            }
            }, errorHandler: { error in
                NSLog("<-- ERROR in allContactsUserInfo : \(error.description)")
        })
        
    }
}
