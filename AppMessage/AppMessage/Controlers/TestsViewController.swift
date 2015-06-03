//
//  TestsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit
import EVReflection

class TestObject: NSObject {
    var objectValue: String = ""
}

class TestsViewController: UIViewController {

    var dao: EVCloudKitDao = EVCloudKitDao.publicDB
    var userId: String = ""
    var createdId = "";

    @IBAction func runTest(sender: AnyObject) {
        getUserInfoTest() // will set the self.userId

        removeAllSubscriptionsTest()

        getAllContactsTest()

        saveObjectsTest() // will set the self.createdId

        saveAndDeleteTest()

        queryRecordsTest()

        subscriptionsTest()

        deleteTest()

        connectTest()

        alternateContainerTest()
    }

    func getUserInfoTest() {
        // retrieve our CloudKit user id. (made syncronous for this demo)
        var sema = dispatch_semaphore_create(0)
        dao.getUserInfo({user in
            self.userId = user.userRecordID.recordName
            EVLog("discoverUserInfo : \(self.userId) = \(user.firstName) \(user.lastName)");
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
    }

    func removeAllSubscriptionsTest() {
        dao.unsubscribeAll({ subscriptionCount in
            EVLog("unsubscribeAll removed \(subscriptionCount) subscriptions");
            }, errorHandler: { error in
                EVLog("<--- ERROR in unsubscribeAll");
        })
    }

    func getAllContactsTest() {
        // Look who of our contact is also using this app.
        // the To for the test message will be the last contact in the list
        var sema = dispatch_semaphore_create(0)
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
    }

    func saveObjectsTest() {
        var userIdTo: String = userId
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
        self.dao.saveItem(asset, completionHandler: {record in
            EVLog("saveItem Asset: \(record.recordID.recordName)");
            // Save the attached image
            message.setAssetFields(record.recordID.recordName)
            self.dao.saveItem(message, completionHandler: {record in
                EVLog("saveItem Message: \(record.recordID.recordName)");
                }, errorHandler: {error in
                    EVLog("<--- ERROR saveItem asset");
            })

            }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message");
        })
    }

    func saveAndDeleteTest() {
        var userIdTo: String = userId
        var message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userIdTo)
        message.Text = "This is the message text"
        message.MessageType = MessageTypeEnum.Text.rawValue

        var sema = dispatch_semaphore_create(0);
        message.MessageType = MessageTypeEnum.Text.rawValue
        dao.saveItem(message, completionHandler: {record in
            self.createdId = record.recordID.recordName
            EVLog("saveItem Message: \(self.createdId)")
            dispatch_semaphore_signal(sema)
            }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message")
                dispatch_semaphore_signal(sema)
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
    }

    func queryRecordsTest() {
        // Get all records of a recordType
        dao.query(Message(), completionHandler: { results in
            EVLog("query recordType : result count = \(results.count)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message")
        })

        // Get all user related record of a recordType
        dao.query(Message(), referenceRecordName: userId, referenceField:"To"
            , completionHandler: { results in
                EVLog("query recordType reference : result count = \(results.count)")
                return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message for user in To")
        })

        // Get all records of a recordType that are created by me using a predicate
        var predicate = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: userId))
        dao.query(Message(), predicate:predicate, completionHandler: { results in
            EVLog("query recordType created by: result count = \(results.count)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message created by user")
        })

        // Get all users containing some words
        dao.query(Message(), tokens: "test the", completionHandler: { results in
            EVLog("query tokens: result count = \(results.count)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message for words")
        })
    }

    func subscriptionsTest() {
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
            notificationInfo.alertBody = "New Message record where To = \(self.userId)"
            notificationInfo.shouldSendContentAvailable = true
            }, errorHandler: { error in
                EVLog("<--- ERROR subscribeForRecordType reference")
        })
    }

    func deleteTest() {
        // Delete the just created data item
        dao.deleteItem(self.createdId, completionHandler: { recordId in
            EVLog("deleteItem : \(recordId)")
        }, errorHandler: {error in
            EVLog("<--- ERROR deleteItem")
        })
    }

    func connectTest() {
        // Creating a connection to the Message recordType in the public database
        EVCloudData.publicDB.connect(Message()
            , predicate: NSPredicate(value: true)
            , filterId: "Message_all"
            , configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record"
                notificationInfo.shouldSendContentAvailable = true
            }, completionHandler: { results in
                EVLog("results = \(results.count)")
                return results.count < 200 // Continue reading if we have less than 200 records and if there are more.
            }, insertedHandler: { item in
                EVLog("inserted \(item)")
            }, updatedHandler: { item in
                EVLog("updated \(item)")
            }, deletedHandler: { recordId in
                EVLog("deleted : \(recordId)")
            }, errorHandler: { error in
                EVLog("<--- ERROR connect")
        })
    }

    func alternateContainerTest() {
        EVLog("===== WARNING : This will fail because you will probably not have this specific container! =====")

        var userIdTo: String = userId
        var message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userIdTo)
        message.Text = "This is the message text"
        message.MessageType = MessageTypeEnum.Text.rawValue

        let dao2 = EVCloudKitDao.publicDBForContainer("iCloud.nl.evict.myapp")
        dao2.saveItem(message, completionHandler: {record in
            self.createdId = record.recordID.recordName;
            EVLog("saveItem Message: \(self.createdId)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem message, you probably need to fix the container id iCloud.nl.evict.myapp");
        })
    }

}
