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

        // Registering for iCloud availability change notifications (log in as different user, clear all user related data)
        var localeChangeObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquityIdentityDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
            println("The user’s iCloud login changed: should refresh all user data.")
        }
        
        var dao = EVCloudKitDao.instance
        var data = EVCloudData.instance
        
        // Only call this line once, ever. It will make sure the recordType are there in iCloud.
        // This call is here to help you play around with this code.
//        dao.createRecordTypes([Message(), Asset(), Group(), GroupParticipant(), News()])
        // Then go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!
        
        
        data.connect(News()
            , predicate: NSPredicate(value: true)
            , filterId: "News_All"
            , onCompletion: { results in
                NSLog("There are \(results.count) existing news items")
                self.refreshNewsVieuw()
            }, onError: {error in
                NSLog("<-- ERROR connect")
            }, onInserted: {item in
                NSLog("New News item received with subject '\((item as News).Subject)'")
                self.refreshNewsVieuw()
            }, onUpdated: {item in
                NSLog("Updated News item received with subject '\((item as News).Subject)'")
                self.refreshNewsVieuw()
            }, onDeleted: {recordId in
                NSLog("News item removed")
                self.refreshNewsVieuw()
            })
        
        // Call this to handle notifications that were not handled yet.
        // Only already setup CloudKit connect's will receive these notifications (like the News above)
        EVCloudData.instance.fetchChangeNotifications()
        
        return true
    }
    
    func refreshNewsVieuw() {
        NSOperationQueue.mainQueue().addOperationWithBlock({
            // If news view is loaded, then refresh the data (on the main queue)
            var news:Dictionary<String, NSObject> = EVCloudData.instance.data["News_All"]!
            for (key, value) in news {
                NSLog("key = \(key), Subject = \((value as News).Subject), Body = \((value as News).Body), ActionUrl = \((value as News).ActionUrl)")
            }
            
        })
    }
    
    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : NSObject]!) {
        NSLog("Push received")
        EVCloudData.instance.didReceiveRemoteNotification(userInfo, {
            NSLog("Not a CloudKit Query notification.")            
            })
        
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    
}

