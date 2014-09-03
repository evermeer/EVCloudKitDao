//
//  TestsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import CloudKit

class TestsViewController : UIViewController {
    
    @IBAction func runTest(sender: AnyObject) {
        // See AppDelegate.swift to see how to handle subscriptions
        
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
        
        // Must be loged in to iCloud
        if userId.isEmpty {
            NSLog("You have to log in to your iCloud account. Open the Settings app, Go to iCloud and sign in with your account")
            return
        }
        
        // Look who of our contact is also using this app.
        // the To for the test message will be the last contact in the list
        sema = dispatch_semaphore_create(0)
        var userIdTo: String = userId
        dao.allContactsUserInfo({ users in
            NSLog("AllContactUserInfo count = \(users.count)");
            for user: AnyObject in users {
                userIdTo = user.userRecordID!.recordName
                NSLog("Firstname: \(user.firstName), Lastname: \(user.lastName), RecordId: \(user.userRecordID)")
            }
            dispatch_semaphore_signal(sema);
            }, errorHandler: { error in
                NSLog("<-- ERROR in allContactsUserInfo : \(error.description)")
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // New message
        var message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userIdTo)
        message.Text = "This is the message text"
        message.HasAttachments = true
        
        // The attachment
        var asset = Asset()
        asset.File = CKAsset(fileURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("test", ofType: "png")!))
        asset.FileName = "test"
        asset.FileType = "png"
        
        // Save the message
        dao.saveItem(message, completionHandler: {record in
            NSLog("saveItem Message: \(record.recordID.recordName)");
            // Save the attached image
            asset.Message = CKReference(recordID: record.recordID, action: .DeleteSelf)
            dao.saveItem(asset, completionHandler: {record in
                NSLog("saveItem Asset: \(record.recordID.recordName)");
                }, errorHandler: {error in
                    NSLog("<--- ERROR saveItem asset");
                })
            
            }, errorHandler: {error in
                NSLog("<--- ERROR saveItem message");
            })
        
        // Save an other instance without the file, make the action synchronous so we can use the id for query and deletion
        sema = dispatch_semaphore_create(0);
        var createdId = "";
        message.HasAttachments = false
        dao.saveItem(message, completionHandler: {record in
            createdId = record.recordID.recordName;
            NSLog("saveItem Message: \(createdId)");
            dispatch_semaphore_signal(sema);
            }, errorHandler: {error in
                NSLog("<--- ERROR saveItem message");
                dispatch_semaphore_signal(sema);
            })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // Get the just created data item
        dao.getItem(createdId, completionHandler: { item in
            NSLog("getItem: with the keys and values:")
            dao.logObject(item)
            }, errorHandler: { error in
                NSLog("<--- ERROR getItem")
            })
        
        // Get all records of a recordType
        dao.query(dao.swiftStringFromClass(Message()), completionHandler: { results in
            NSLog("query recordType : result count = \(results.count)")
            }, errorHandler: { error in
                NSLog("<--- ERROR query Message")
            })
        
        // Get all user related record of a recordType
        dao.query(dao.swiftStringFromClass(Message()) ,referenceRecordName:userId, referenceField:"To", completionHandler: { results in
            NSLog("query recordType reference : result count = \(results.count)")
            }, errorHandler: { error in
                NSLog("<--- ERROR query Message for user in To")
            })
        
        // Get all records of a recordType that are created by me using a predicate
        var predicate = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: userId))
        dao.query(dao.swiftStringFromClass(Message()), predicate: predicate, completionHandler: { results in
            NSLog("query recordType created by: result count = \(results.count)")
            }, errorHandler: { error in
                NSLog("<--- ERROR query Message created by user")
            })
        
        // Get all users containing some words
        //TODO: Since beta 3 this does not work anymore.
        //        dao.query(dao.recordType(Message()), tokens:"this the", completionHandler: { results in
        //                NSLog("query : result count = \(results.count)")
        //            }, errorHandler: { error in
        //                NSLog("<--- ERROR query Message for words")
        //            })
        
        // Unsubscribe for update notifications
        dao.unsubscribe(dao.swiftStringFromClass(Message()), errorHandler: { error in
            NSLog("<--- ERROR unsubscribeForRecordType")
            })
        
        // Subscribe for update notifications
        dao.subscribe(dao.swiftStringFromClass(Message()), errorHandler: { error in
            NSLog("<--- ERROR subscribeForRecordType")
            })
        
        // Unsubscribe for update notifications where you are in the To field
        dao.unsubscribe(dao.swiftStringFromClass(Message()), referenceRecordName: userId, referenceField: "To", errorHandler: { error in
            NSLog("<--- ERROR subscribeForRecordType reference")
            })
        
        // Subscribe for update notifications where you are in the To field
        dao.subscribe(dao.swiftStringFromClass(Message()), referenceRecordName:userId, referenceField:"To", errorHandler: { error in
            NSLog("<--- ERROR subscribeForRecordType reference")
            })
        
        // Delete the just created data item
        dao.deleteItem(createdId, completionHandler: { recordId in
            NSLog("deleteItem : \(recordId)")
            }, errorHandler: {error in
                NSLog("<--- ERROR deleteItem")
            })
        
        EVCloudData.instance.connect(dao.swiftStringFromClass(Message()), predicate: NSPredicate(value: true), filterId: "Message_all"
        , onCompletion: { results in
            NSLog("results = \(results.count)")
        }, onError: { error in
            NSLog("<--- ERROR connect")
        }, onInserted: { item in
            NSLog("inserted \(item)")
        }, onDeleted: { recordId in
            NSLog("deleted : \(recordId)")
        })
    }
    
}