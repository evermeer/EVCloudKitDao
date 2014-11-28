//
//  AppDelegate.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        
        // Make sure we receive subscription notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
        application.registerForRemoteNotifications()
                
        // Only call this line once, ever. It will make sure the recordType are there in iCloud.
        // This call is here to help you play around with this code.
        // After this, go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!
        EVCloudKitDao.instance.createRecordTypes([Message(), Asset(), News()])
        
        return true
    }
    
    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : NSObject]!) {
        NSLog("Push received")
        EVCloudData.instance.didReceiveRemoteNotification(userInfo, {
            NSLog("Not a CloudKit Query notification.")            
        })
    }
    
}

