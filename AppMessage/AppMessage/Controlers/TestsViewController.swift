//
//  TestsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit
import EVReflection

class TestObject:NSObject {
    var objectValue:String = ""
}

class TestsViewController : UIViewController {
    @IBAction func runTest(sender: AnyObject) {
        
        // Test the EVReflection class - to and from string
        var theObject = TestObject()
        var theObjectString:String = EVReflection.swiftStringFromClass(theObject)
        NSLog("swiftStringFromClass = \(theObjectString)")
        
        if var nsobject = EVReflection.swiftClassFromString(theObjectString) {
            NSLog("object = \(nsobject)")
        }
        
        // Test the EVReflection class - to and from dictionary
        theObject.objectValue = "testing"
        var toDict = EVReflection.toDictionary(theObject)
        NSLog("toDictionary = \(toDict)")
        if var nsobject = EVReflection.fromDictionary(toDict, anyobjectTypeString: theObjectString) as? TestObject {
            NSLog("object = \(nsobject), objectValue = \(nsobject.objectValue)")
        }
        
        //var nsobject: AnyObject! = objc_getClass("AppMessage.\(theObjectString)") as! TestObject
        //NSLog("object \(theObjectString) = \(nsobject)")
        
        // See AppDelegate.swift to see how to handle subscriptions
        var dao: EVCloudKitDao = EVCloudKitDao.publicDB
        
        // retrieve our CloudKit user id. (made syncronous for this demo)
        var sema = dispatch_semaphore_create(0)
        var userId: String = ""
        dao.getUserInfo({user in
            userId = user.userRecordID.recordName
            EVLog("discoverUserInfo : \(userId) = \(user.firstName) \(user.lastName)");
            dispatch_semaphore_signal(sema);
            }, errorHandler: { error in
                EVLog("<--- ERROR in getUserInfo");
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // Must be loged in to iCloud
        if userId.isEmpty {
            EVLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account")
            return
        }
        
        // Remove all subscriptions
        dao.unsubscribeAll({ subscriptionCount in
                EVLog("unsubscribeAll removed \(subscriptionCount) subscriptions");
            }, errorHandler: { error in
                EVLog("<--- ERROR in unsubscribeAll");
        })
        
        // Look who of our contact is also using this app.
        // the To for the test message will be the last contact in the list
        sema = dispatch_semaphore_create(0)
        var userIdTo: String = userId
        dao.allContactsUserInfo({ users in
            EVLog("AllContactUserInfo count = \(users.count)");
            for user in users {
                userIdTo = user.userRecordID!.recordName
                EVLog("Firstname: \(user.firstName), Lastname: \(user.lastName), RecordId: \(user.userRecordID)")
            }
            dispatch_semaphore_signal(sema);
            }, errorHandler: { error in
                EVLog("<-- ERROR in allContactsUserInfo : \(error.description)")
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // New message
        var message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userIdTo)
        message.Text = "This is the message text"
        message.MessageType = MessageTypeEnum.Picture.rawValue
        
        // The attachment
        var asset = Asset()
        asset.File = CKAsset(fileURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("test", ofType: "png")!))
        asset.FileName = "test"
        asset.FileType = "png"
        
        // Save the message
        dao.saveItem(asset, completionHandler: {record in
            EVLog("saveItem Asset: \(record.recordID.recordName)");
            // Save the attached image
            message.setAssetFields(record.recordID.recordName)
            dao.saveItem(message, completionHandler: {record in
                EVLog("saveItem Message: \(record.recordID.recordName)");
                }, errorHandler: {error in
                    EVLog("<--- ERROR saveItem asset");
                })
            
            }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message");
            })
        
        // Save an other instance without the file, make the action synchronous so we can use the id for query and deletion
        sema = dispatch_semaphore_create(0);
        var createdId = "";
        message.MessageType = MessageTypeEnum.Text.rawValue
        dao.saveItem(message, completionHandler: {record in
            createdId = record.recordID.recordName;
            EVLog("saveItem Message: \(createdId)");
            dispatch_semaphore_signal(sema);
            }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message");
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // Get the just created data item
        dao.getItem(createdId
            , completionHandler: { item in
                EVLog("getItem: with the keys and values:")
                EVReflection.logObject(item)
            }, errorHandler: { error in
                EVLog("<--- ERROR getItem")
            })
                
        // Get all records of a recordType
        dao.query(Message(), completionHandler: { results in
                EVLog("query recordType : result count = \(results.count)")
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message")
            })
        
        // Get all user related record of a recordType
        dao.query(Message(), referenceRecordName: userId, referenceField:"To", completionHandler: { results in
            EVLog("query recordType reference : result count = \(results.count)")
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message for user in To")
            })
        
        // Get all records of a recordType that are created by me using a predicate
        var predicate = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: userId))
        dao.query(Message(), predicate:predicate, completionHandler: { results in
            EVLog("query recordType created by: result count = \(results.count)")
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message created by user")
            })
        
        // Get all users containing some words
        dao.query(Message(), tokens: "test the", completionHandler: { results in
                EVLog("query tokens: result count = \(results.count)")
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message for words")
            })
        
        // Unsubscribe for update notifications
        dao.unsubscribe(Message(), errorHandler:{ error in
            EVLog("<--- ERROR unsubscribeForRecordType")
            })
        
        // Subscribe for update notifications
        dao.subscribe(Message(), configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record"
                notificationInfo.shouldSendContentAvailable = true
            }, errorHandler:{ error in
                EVLog("<--- ERROR subscribeForRecordType")
            })
        
        // Unsubscribe for update notifications where you are in the To field
        dao.unsubscribe(Message(), referenceRecordName: userId, referenceField: "To", errorHandler: { error in
            EVLog("<--- ERROR subscribeForRecordType reference")
            })
        
        // Subscribe for update notifications where you are in the To field
        dao.subscribe(Message(), referenceRecordName: userId, referenceField:"To", configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record where To = \(userId)"
                notificationInfo.shouldSendContentAvailable = true
            }, errorHandler: { error in
            EVLog("<--- ERROR subscribeForRecordType reference")
            })
        
        // Delete the just created data item
        dao.deleteItem(createdId, completionHandler: { recordId in
            EVLog("deleteItem : \(recordId)")
            }, errorHandler: {error in
                EVLog("<--- ERROR deleteItem")
            })
        
        // Creating a connection to the Message recordType in the public database
        EVCloudData.publicDB.connect(Message()
            , predicate: NSPredicate(value: true)
            , filterId: "Message_all"
            , configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record"
                notificationInfo.shouldSendContentAvailable = true
            }, completionHandler: { results in
                EVLog("results = \(results.count)")
            }, insertedHandler: { item in
                EVLog("inserted \(item)")
            }, updatedHandler: { item in
                EVLog("updated \(item)")
            }, deletedHandler: { recordId in
                EVLog("deleted : \(recordId)")
            }, errorHandler: { error in
                EVLog("<--- ERROR connect")
            })
        
        EVLog("===== WARNING : This will fail because you will probably not have this specific container! =====")
        let dao2 = EVCloudKitDao.publicDBForContainer("iCloud.nl.evict.myapp")
        dao2.saveItem(message, completionHandler: {record in
            createdId = record.recordID.recordName;
            EVLog("saveItem Message: \(createdId)");
            }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message, you probably need to fix the container id iCloud.nl.evict.myapp");
        })
        
    }
    
}