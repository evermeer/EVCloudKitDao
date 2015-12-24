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

        // The 2 commands below are only here to assist during development.
        
        // Only call this line once. It will make sure the recordType are there in iCloud.
        // After this, go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!
//        EVCloudKitDao.publicDB.createRecordTypes([Message(), Asset(), News()])

        // During development you will probably play around with subscriptins. 
        // To be sure you do not have any old subscriptions left over,  just clear them all on startup.
//        EVCloudKitDao.publicDB.unsubscribeAll({subscriptioncount in EVLog("subscriptions removed = \(subscriptioncount)")}, errorHandler: {error in })

        EVCloudKitDao.publicDB.unsubscribeAll( { count in
            EVLog("\(count) subscriptions removed")
        })
        
        return true
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        EVLog("Push received")
        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, executeIfNonQuery: {
            EVLog("Not a CloudKit Query notification.")
        }, completed: {
            EVLog("All notifications are processed")
        })
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Just to make sure that all updates are written do the cache.
        EVCloudData.publicDB.backupAllData()
    }

}
