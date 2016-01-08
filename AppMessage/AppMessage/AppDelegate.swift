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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        // Only call this line once. It will make sure the recordType are there in iCloud.
        // After this, go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!
        // If you use this in your own project, then make sure that the fields are not nil otherwise the field will not be created.
        EVCloudKitDao.publicDB.createRecordTypes([Message(), Asset(), News(), Invoice()])

        
        // During development you will probably play around with subscriptins.
        // To be sure you do not have any old subscriptions left over,  just clear them all on startup.
        if EVCloudKitDao.publicDB.accountStatus == .Available {
            EVCloudKitDao.publicDB.unsubscribeAll( { count in
                EVLog("\(count) subscriptions removed")
            })            
        }
        
        // Here we do not call the EVCloudData.publicDB.fetchChangeNotifications. Instead we do that in the LeftMenuViewController after we are sure that all general .connect are setup
        
        return true
    }

    // The app is alredy loaded and the .connect calls are setup. So we can process any notifications that have arived and not processed. 
    func applicationDidBecomeActive(application: UIApplication) {
        EVCloudData.publicDB.fetchChangeNotifications({
            EVLog("All change notifications are processed")
            EVCloudKitDao.publicDB.setBadgeCounter(0)
        })
    }
    

// This will only be called when your app is active. Instead we should use the function below
//    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
//        EVLog("Push received")
//        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, executeIfNonQuery: {
//            EVLog("Not a CloudKit Query notification.")
//        }, completed: {
//            EVLog("All notifications are processed")
//        })
//    }
    

    // Process al notifications
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        EVLog("Push received")
        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, executeIfNonQuery: {
            EVLog("Not a CloudKit Query notification.")
            }, completed: {
                EVLog("All notifications are processed")
                completionHandler(.NewData)
        })
    }
    
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Just to make sure that all updates are written do the cache.
        EVCloudData.publicDB.backupAllData()
    }

}
