//
//  AppDelegate.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
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
            self.runTests() //TODO: why are we still loged out? Do we need a delay?
        }
        
        runTests()
        
        return true
    }
    
    func runTests() {
        var dao: EVCloudKitDao = EVCloudKitDao.instance
        
        // retrieve our CloudKit user id. (made syncronous for this demo)
        var sema = dispatch_semaphore_create(0)
        var userId: String = ""
        dao.getUserInfo({user in
                userId = user.userRecordID.recordName
                NSLog("discoverUserInfo : \(userId) = \(user.firstName) \(user.lastName)");
                dispatch_semaphore_signal(sema);
            }, errorHandler: { error in
                NSLog("<--- ERROR in getUserInfo");
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        if userId.isEmpty {
            NSLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account")
            return
        }
        
        dao.allContactsUserInfo({ users in
                NSLog("AllContactUserInfo count = \(users.count)");
                for user: AnyObject in users {
                    NSLog("Firstname: \(user.firstName), Lastname: \(user.lastName), RecordId: \(user.userRecordID)")
                }
            }, errorHandler: { error in
                NSLog("<-- ERROR in allContactsUserInfo : \(error.description)")
            })
        
        // New message (to self)
        var message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userId)
        message.Subject = "Hier gaat het over"
        message.Body = "Dit wil je vertellen"
        //message.File =
        message.FileType = "Image"
        
        // Save a data item
        sema = dispatch_semaphore_create(0);
        var createdId = "";
        dao.saveItem(message, completionHandler: {record in
                createdId = record.recordID.recordName;
                NSLog("saveItem : \(createdId)");
                dispatch_semaphore_signal(sema);
            }, errorHandler: {error in
                NSLog("<--- ERROR saveItem");
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        
        // Delete a data item
        dao.deleteItem(createdId, completionHandler: { recordId in
                NSLog("deleteItem : \(recordId)")
            }, errorHandler: {error in
                NSLog("<--- ERROR deleteItem");
            })
        
        // D84F85B2-2286-48B8-B20B-B87F22C26041
        dao.getItem("36ECE3F5-5190-4B58-BD12-131B9FC7480F", completionHandler: { item in
                NSLog("getItem: with the keys and values:")
                dao.logObject(item)
            }, errorHandler: { error in
                NSLog("<--- ERROR getItem")
            })
        
        // Get all records of a recordType
        dao.query(dao.recordType(Message()), completionHandler: { results in
                NSLog("query recordType : result count = \(results.count)")
            }, errorHandler: { error in
                NSLog("<--- ERROR query Message")
            })
        
        // Get all user related record of a recordType
        dao.query(dao.recordType(Message()) ,referenceRecordName:userId, referenceField:"To", completionHandler: { results in
                NSLog("query recordType reference : result count = \(results.count)")
            }, errorHandler: { error in
                NSLog("<--- ERROR query Message for user in To")
            })

        // Get all records of a recordType that are created by me using a predicate
        var predicate = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: userId))
        dao.query(dao.recordType(Message()), predicate: predicate, completionHandler: { results in
                NSLog("query recordType created by: result count = \(results.count)")
            }, errorHandler: { error in
                NSLog("<--- ERROR query Message created by user")
            })
        
        // Get all users containing some words
        //        dao.query(dao.recordType(Message()), tokens:"ik je", completionHandler: { results in
        //                NSLog("query : result count = \(results.count)")
        //            }, errorHandler: { error in
        //                NSLog("<--- ERROR query Message for words")
        //            })
        
        // Unsubscribe for update notifications
        dao.unsubscribe(dao.recordType(Message()), errorHandler: { error in
                NSLog("<--- ERROR unsubscribeForRecordType")
            })
        
        // Subscribe for update notifications
        dao.subscribe(dao.recordType(Message()), errorHandler: { error in
                NSLog("<--- ERROR subscribeForRecordType")
            })
        
        // Unsubscribe for update notifications where you are in the To field
        dao.unsubscribe(dao.recordType(Message()), referenceRecordName: userId, referenceField: "To", errorHandler: { error in
                NSLog("<--- ERROR subscribeForRecordType reference")
            })
        
        // Subscribe for update notifications where you are in the To field
        dao.subscribe(dao.recordType(Message()), referenceRecordName:userId, referenceField:"To", errorHandler: { error in
                NSLog("<--- ERROR subscribeForRecordType reference")
            })
        
        // Save an other item
        dao.saveItem(message, completionHandler: {record in
                createdId = record.recordID.recordName;
                NSLog("saveItem : \(createdId)");
            }, errorHandler: {error in
                NSLog("<--- ERROR saveItem");
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

    
    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]!) {
        NSLog("Push received")
        var cloudNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        var alertBody = cloudNotification.alertBody
        NSLog("alert body : \(alertBody)")
        if cloudNotification.notificationType == CKNotificationType.Query {
            var queryNotification = cloudNotification as CKQueryNotification
            var recordID = queryNotification.recordID
            NSLog("recordID = \(recordID)")

            var dao: EVCloudKitDao = EVCloudKitDao.instance
            dao.getItem(recordID.recordName, completionHandler: { item in
                    NSLog("getItem: recordType = \(dao.recordType(item)), with the keys and values:")
                    dao.logObject(item)
                }, errorHandler: { error in
                    NSLog("<--- ERROR getItem")
                })
        }
    }
    
}

