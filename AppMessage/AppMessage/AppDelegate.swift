//
//  AppDelegate.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit
import CloudKit
import EVCloudKitDao

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Only call this line once. It will make sure the recordType are there in iCloud.
        // After this, go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!
        // If you use this in your own project, then make sure that the fields are not nil otherwise the field will not be created.
        //EVCloudKitDao.publicDB.createRecordTypes([Message(), Asset(), News(), Invoice()])

        
        // During development you will probably play around with subscriptins.
        // To be sure you do not have any old subscriptions left over,  just clear them all on startup.
        if EVCloudKitDao.publicDB.accountStatus == .available {
            EVCloudKitDao.publicDB.unsubscribeAll( { count in
                EVLog("\(count) subscriptions removed")
            })            
        }
        
        // Register for notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil))
        application.registerForRemoteNotifications()
        
        // Here we do not call the EVCloudData.publicDB.fetchChangeNotifications. Instead we do that in the LeftMenuViewController after we are sure that all general .connect are setup
        
        return true
    }

    // The app is alredy loaded and the .connect calls are setup. So we can process any notifications that have arived and not processed. 
    func applicationDidBecomeActive(_ application: UIApplication) {
        EVCloudData.publicDB.fetchChangeNotifications({
            EVLog("All change notifications are processed")
            EVCloudKitDao.publicDB.setBadgeCounter(0)
        })
    }
    
    #if os(tvOS)
    //This will only be called when your app is active. So this is what you should use on tvOS
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        EVLog("Push received")
        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, executeIfNonQuery: {
            EVLog("Not a CloudKit Query notification.")
        }, completed: {
            EVLog("All notifications are processed")
        })
    }
    #else
    // Process al notifications even if we are in the background. tvOS will not have this event
    // Make sure you enable background notifications in the app settings. (entitlements: pushnotifications and  backgrounds modes - notifications plus background fetch)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        EVLog("Push received")
        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, executeIfNonQuery: {
            EVLog("Not a CloudKit Query notification.")
            }, completed: {
                EVLog("All notifications are processed")
                completionHandler(.newData)
        })
    }
    #endif
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Just to make sure that all updates are written do the cache.
        EVCloudData.publicDB.backupAllData()
    }

}
