//
//  TestsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit
import EVCloudKitDao
import EVReflection

class TestObject: NSObject {
    var objectValue: String = ""
}

class TestsViewController: UIViewController {

    var dao: EVCloudKitDao = EVCloudKitDao.publicDB
    var userId: String = ""
    var createdId = "";

    @IBAction func runTest(_ sender: AnyObject) {
        
        conflictTest()

        getUserInfoTest() // will set the self.userId

        ingnoreFieldTest()
        
        subObjectTest()
        
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
    
    func conflictTest() {
        let message = Message()
        message.recordID = CKRecordID(recordName: "We use this twice")
        message.Text = "This is the message text"

        let message2 = Message()
        message2.recordID = CKRecordID(recordName: "We use this twice")
        message2.Text = "This is an other message text"

        self.dao.saveItem(message, completionHandler: {record in
            EVLog("saveItem Message: \(record.recordID.recordName)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem message \(error)");
        })

        self.dao.saveItem(message, completionHandler: {record in
            EVLog("saveItem Message: \(record.recordID.recordName)");
        }, errorHandler: {error in
            EVLog("<--- ERROR saveItem message \(error)");
        })
    }

    func getUserInfoTest() {
        // retrieve our CloudKit user id. (made syncronous for this demo)
        let sema = DispatchSemaphore(value: 0)
        dao.discoverUserInfo({ (user) -> Void in
            if #available(iOS 10.0, *) {
                self.userId = (user as! CKUserIdentity).userRecordID?.recordName ?? ""
            } else {
                self.userId = (user as! CKDiscoveredUserInfo).userRecordID?.recordName ?? ""
            }
            EVLog("discoverUserInfo : \(showNameFor(user))");
            sema.signal();
        }) { (error) -> Void in
            EVLog("<--- ERROR in getUserInfo");
            sema.signal();
        }
        let _ = sema.wait(timeout: DispatchTime.distantFuture);

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
        let sema = DispatchSemaphore(value: 0)
        dao.allContactsUserInfo({ users in
            EVLog("AllContactUserInfo count = \(users?.count ?? 0)");
            for user in users! {
                EVLog("\(showNameFor(user))")
            }
            sema.signal();
            }, errorHandler: { error in
                EVLog("<-- ERROR in allContactsUserInfo : \(error.localizedDescription)")
                sema.signal();
        })
        let _ = sema.wait(timeout: DispatchTime.distantFuture);
    }
    
    func saveObjectsTest() {
        let userIdTo: String = userId
        // New message
        let message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userIdTo)
        message.Text = "This is the message text"
        message.MessageType = MessageTypeEnum.Picture.rawValue

        // The attachment
        let asset = Asset()
        asset.File = CKAsset(fileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "test", ofType: "png")!))
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
        let userIdTo: String = userId
        let message = Message()
        message.From = dao.referenceForId(userId)
        message.To = dao.referenceForId(userIdTo)
        message.Text = "This is the message text"
        message.MessageType = MessageTypeEnum.Text.rawValue

        let sema = DispatchSemaphore(value: 0);
        message.MessageType = MessageTypeEnum.Text.rawValue
        dao.saveItem(message, completionHandler: {record in
            self.createdId = record.recordID.recordName
            EVLog("saveItem Message: \(self.createdId)")
            sema.signal()
            }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message")
                sema.signal()
        })
        let _ = sema.wait(timeout: DispatchTime.distantFuture);

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
        dao.query(Message(), completionHandler: { results, isFinished in
            EVLog("query recordType : result count = \(results.count)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message")
        })

        // Get all user related record of a recordType
        dao.query(Message(), referenceRecordName: userId, referenceField:"To"
            , completionHandler: { results, isFinished in
                EVLog("query recordType reference : result count = \(results.count)")
                return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message for user in To")
        })

        // Get all records of a recordType that are created by me using a predicate
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: userId))
        dao.query(Message(), predicate:predicate, completionHandler: { results, isFinished in
            EVLog("query recordType created by: result count = \(results.count)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message created by user")
        })

        // Get all users containing some words
        dao.query(Message(), tokens: "test the", completionHandler: { results, isFinished in
            EVLog("query tokens: result count = \(results.count)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Message for words")
        })
    }

    func subscriptionsTest() {
        // Subscribe for update notifications
        dao.subscribe(Message(), configureNotificationInfo:{ notificationInfo in
            notificationInfo.alertBody = "New Message record"
            notificationInfo.shouldSendContentAvailable = true
            }, errorHandler:{ error in
                EVLog("<--- ERROR subscribeForRecordType")
        })

        // Unsubscribe for update notifications
        dao.unsubscribe(Message(), errorHandler:{ error in
            EVLog("<--- ERROR unsubscribeForRecordType")
        })

        // Subscribe for update notifications where you are in the To field
        dao.subscribe(Message(), referenceRecordName: userId, referenceField:"To", configureNotificationInfo:{ notificationInfo in
            notificationInfo.alertBody = "New Message record where To = \(self.userId)"
            notificationInfo.shouldSendContentAvailable = true
            }, errorHandler: { error in
                EVLog("<--- ERROR subscribeForRecordType reference")
        })

        // Unsubscribe for update notifications where you are in the To field
        dao.unsubscribe(Message(), referenceRecordName: userId, referenceField: "To", errorHandler: { error in
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
            }, completionHandler: { results, isFinished in
                EVLog("results = \(results.count)")
                return results.count < 200 // Continue reading if we have less than 200 records and if there are more.
            }, insertedHandler: { item in
                EVLog("inserted \(item)")
            }, updatedHandler: { item, index in
                EVLog("updated \(item)")
            }, deletedHandler: { recordId, index in
                EVLog("deleted : \(recordId)")
            }, errorHandler: { error in
                EVLog("<--- ERROR connect")
        })
    }

    func alternateContainerTest() {
        EVLog("===== WARNING : This will fail because you will probably not have this specific container! =====")

        let userIdTo: String = userId
        let message = Message()
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

    func subObjectTest() {
        let invoice = Invoice()
        invoice.InvoiceNumber = "A123"
        invoice.DeliveryAddress = Address()
        invoice.DeliveryAddress?.Street = "The street"
        invoice.DeliveryAddress?.City = "The city"
        invoice.InvoiceAddress = Address()
        invoice.InvoiceAddress?.Street = "The invoice street"
        invoice.InvoiceAddress?.City = "The invoice city"
        invoice.PostalAddress = Address()
        invoice.PostalAddress?.Street = "The postal street"
        invoice.PostalAddress?.City = "The postal city"
        
        // Save the invoice and wait for it to complete
        let sema = DispatchSemaphore(value: 0);
        self.dao.saveItem(invoice, completionHandler: {record in
            EVLog("saveItem Invoice: \(record.recordID.recordName)");
            sema.signal();
        }, errorHandler: {error in
                EVLog("<--- ERROR saveItem message");
            sema.signal();
        })
        let _ = sema.wait(timeout: DispatchTime.distantFuture);
        
        
        // Now see if we can query the invoice
        // Get all records of a recordType
        dao.query(Invoice(), completionHandler: { results, isFinished in
            EVLog("query Invoice : result count = \(results.count), results = \(results)")
            return false
            }, errorHandler: { error in
                EVLog("<--- ERROR query Invoice")
        })
    }
    
    func ingnoreFieldTest() {
        let myObj = testObject()
        myObj.saveString = "save this"
        myObj.ignoreString = "Forget about this"
        
        let record = myObj.toCKRecord()
        EVLog("record from object: \(record)")
    }
}

open class testObject: CKDataObject {
    fileprivate var ignoreString: String = ""
    var saveString: String = ""

    override open func propertyMapping() -> [(keyInObject: String?, keyInResource: String?)] {
        return [("ignoreString", nil)]
    }
}

