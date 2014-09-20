//
//  EVCloudKitDao.swift
//
//  Created by Edwin Vermeer on 04-06-14.
//  Copyright (c) 2014 Evict. All rights reserved.
//

import CloudKit

@objc protocol SetCell {
    func setcell()
}

class BaseUITableViewCell : UITableViewCell, SetCell {
    func setcell() {}
}

class MyCell : BaseUITableViewCell {
    override func setcell() {}
}


let cellClass: AnyClass! = NSClassFromString("MyCell")
var objectType : NSObject.Type! = cellClass as NSObject.Type!
var theObject: NSObject! = objectType() as NSObject
var myCell:BaseUITableViewCell = theObject as BaseUITableViewCell

var myCell2:protocol<SetCell> = objectType() as protocol<SetCell>


class EVCloudKitDao {
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    // Singleton
    class var instance : EVCloudKitDao {
        struct Static { static let instance : EVCloudKitDao = EVCloudKitDao() }
        return Static.instance
    }
    
    class func sharedInstance() -> EVCloudKitDao {
        return instance;
    }
    
    var container : CKContainer
    var database : CKDatabase
    
    // On init set a quick refrence to the container and database
    init() {
        container = CKContainer.defaultContainer()
        container.accountStatusWithCompletionHandler({status, error in
            if (error != nil) { NSLog("Error = \(error.description)")}
            NSLog("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
        })
        NSLog("Container identifier = \(container.containerIdentifier)")
        database = container.publicCloudDatabase
    }

    // ------------------------------------------------------------------------
    // MARK: - Helper methods
    // ------------------------------------------------------------------------

    // Generic CloudKit callback handling
    func handleCallback(error: NSError?, errorHandler: () -> Void, completionHandler: () -> Void) {
        //NSOperationQueue.mainQueue().addOperationWithBlock {
            if (error != nil) {
                NSLog("CloudKit Error : \(error?.code) = \(error?.description) \n\(error?.userInfo)")
                errorHandler()
            } else {
                completionHandler()
            }
        //}
    }
    
    // Generic query handling
    func queryRecords<T:NSObject>(type:T, query: CKQuery, completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        // Not sortable anymore!?
        if !(query.sortDescriptors != nil) {
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        var operation = CKQueryOperation(query: query)
        var results = Dictionary<String, T>()
        operation.recordFetchedBlock = { record in
            results[record.recordID.recordName] = self.fromCKRecord(record) as? T
        }
        operation.queryCompletionBlock = { cursor, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(results: results);
                })
        }
        operation.resultsLimit = CKQueryOperationMaximumResults;
        database.addOperation(operation)
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - initialize record types
    // ------------------------------------------------------------------------

    // This is a helper method that inserts and removes records in order to create the recordtypes in the iCloud
    // You only need to call this method once, ever.
    func createRecordTypes(types: [NSObject]) {
        for item in types {
            var sema = dispatch_semaphore_create(0);
            saveItem(item, completionHandler: {record in
                    NSLog("saveItem Message: \(record.recordID.recordName)");
                    self.deleteItem(record.recordID.recordName, completionHandler: { recordId in
                        NSLog("deleteItem : \(recordId)")
                        dispatch_semaphore_signal(sema);
                    }, errorHandler: {error in
                        NSLog("<--- ERROR deleteItem")
                        dispatch_semaphore_signal(sema);
                    })
                
                }, errorHandler: {error in
                    NSLog("<--- ERROR saveItem");
                    dispatch_semaphore_signal(sema);
                })
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        NSException(name: "RunOnlyOnce", reason: "Call this method only once. Only here for easy debugging reasons for fast generation of the iCloud recordTypes. Sorry for the hard crash. Now disable the call to this method in the AppDelegat!  Then go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!", userInfo: nil).raise()
    }

    
    // ------------------------------------------------------------------------
    // MARK: - Data methods - rights and contacts
    // ------------------------------------------------------------------------
    
    // Are we allowed to call the discoverUserInfo function?
    func requestDiscoverabilityPermission(completionHandler: (granted: Bool) -> Void, errorHandler:(error: NSError) -> Void) {
    container.requestApplicationPermission(CKApplicationPermissions.PermissionUserDiscoverability, completionHandler: { applicationPermissionStatus, error in
        self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(granted: applicationPermissionStatus == CKApplicationPermissionStatus.Granted)
            })
        })
    }

    // Get the info of the current user
    func discoverUserInfo(completionHandler: (user: CKDiscoveredUserInfo) -> Void, errorHandler:(error:NSError) -> Void) {
        container.fetchUserRecordIDWithCompletionHandler({recordID, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                self.container.discoverUserInfoWithUserRecordID(recordID, { user, error in
                    self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                        completionHandler(user: user)
                    })
                })
            })
        })
    }

    // Combined ask for rights and get user
    func getUserInfo(completionHandler: (user: CKDiscoveredUserInfo) -> Void, errorHandler:(error:NSError) -> Void) {
        self.requestDiscoverabilityPermission({ discoverable in
            if discoverable {
                self.discoverUserInfo({user in
                        completionHandler(user: user)
                    }, errorHandler: { error in
                        errorHandler(error: error)
                    })
            } else
            {
                NSLog("requestDiscoverabilityPermission : No permissions")
                var error = NSError(domain: "EVCloudKitDao", code: 1, userInfo:nil)
                errorHandler(error: error)
            }
        }, errorHandler: { error in
            errorHandler(error: error)
        })
    }
    
    // Who is using our app
    func allContactsUserInfo(completionHandler: (users: [AnyObject]!) -> Void, errorHandler:(error:NSError) -> Void) {
        container.discoverAllContactUserInfosWithCompletionHandler({users, error in
            self.handleCallback(error, errorHandler:{errorHandler(error: error)}, completionHandler: {
                completionHandler(users:users)
            })
        })
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - CRUD
    // ------------------------------------------------------------------------
    
    // Get an Item for a recordId
    func getItem(recordId: String, completionHandler: (result: NSObject) -> Void, errorHandler:(error: NSError) -> Void) {
        database.fetchRecordWithID(CKRecordID(recordName: recordId), completionHandler: {record, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(result: self.fromCKRecord(record));
            })
        })
    }
    
    // Save an item. Relate to other objects with property CKReference or save an asset using CKAsset
    func saveItem(item: NSObject, completionHandler: (record: CKRecord) -> Void, errorHandler:(error: NSError) -> Void) {
        var theRecord = self.toCKRecord(item)
        database.saveRecord(theRecord, completionHandler: { record, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(record: record);
            })
        })
    }
    
    // Delete an Item for a recordId
    func deleteItem(recordId: String, completionHandler: (recordID: CKRecordID) -> Void, errorHandler:(error: NSError) -> Void) {
        database.deleteRecordWithID(CKRecordID(recordName: recordId), completionHandler: {recordID, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(recordID: recordID);
            })
        })
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - Query
    // ------------------------------------------------------------------------
    
    // Query a recordType
    func query<T:NSObject>(type:T, completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // Query child object of a recordType
    func query<T:NSObject>(type:T, referenceRecordName:String, referenceField:String ,completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = swiftStringFromClass(type)
        var parentId = CKRecordID(recordName: referenceRecordName)
        var parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "%K == %@", referenceField ,parent))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    // Query a recordType with a predicate
    func query<T:NSObject>(type:T, predicate: NSPredicate, completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void){
        var recordType = swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: predicate)
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // TODO: Was in the 208 lab, since beta 3 it does not work anymore. also tried the "self contains '\(tokens)'"
    // Query a recordType for some tokens
    func query<T:NSObject>(type:T, tokens:String ,completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = swiftStringFromClass(T())
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "ALL tokenize('\(tokens)', ‘Cdl') IN allTokens"))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - Subscriptions
    // ------------------------------------------------------------------------

    // subscribe for modifications to a recordType and predicate (and register it under filterId)
    func subscribe(type:NSObject, predicate:NSPredicate, filterId:String ,errorHandler:(error: NSError) -> Void) {
        var recordType = swiftStringFromClass(type)
        var defaults = NSUserDefaults.standardUserDefaults()
        if defaults.boolForKey("subscriptionFor_\(recordType)_\(filterId)") { return }
        
        var subscription = CKSubscription(recordType: recordType, predicate: predicate, options: .FiresOnRecordCreation | .FiresOnRecordUpdate | .FiresOnRecordDeletion)
        subscription.notificationInfo = CKNotificationInfo()
        subscription.notificationInfo.alertBody = "New item added to \(recordType), \(filterId)"
        //TODO: extra code block so you can set these from code?
        // subscription.notificationInfo.alertLocalizationKey = "subscriptionMessage"
        // subscription.notificationInfo.alertLocalizationArgs = [recordType, filterId]
        // subscription.notificationInfo.alertActionLocalizationKey = "subscrioptionActionMessage"
        // subscription.notificationInfo.alertLaunchImage = "alertImage"
        // subscription.notificationInfo.soundName = "alertSound"
        // subscription.notificationInfo.shouldBadge = true
        // subscription.notificationInfo.desiredKeys = [""]
        subscription.notificationInfo.shouldSendContentAvailable = true
        database.saveSubscription(subscription, completionHandler: { savedSubscription, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                defaults.setBool(true, forKey: "subscriptionFor_\(recordType)_\(filterId)")
                defaults.setObject(subscription.subscriptionID, forKey: "subscriptionIDFor_\(recordType)_\(filterId)")
                })
            })
    }
    
    // unsubscribe for modifications to a recordType and predicate (and unregister is under filterId)
    func unsubscribe(type:NSObject, filterId:String, errorHandler:(error: NSError) -> Void) {
        var recordType = swiftStringFromClass(type)
        var defaults = NSUserDefaults.standardUserDefaults()
        if !defaults.boolForKey("subscriptionFor_\(recordType)_\(filterId)") { return }
        
        var modifyOperation = CKModifySubscriptionsOperation()
        var subscriptionID : String? = defaults.objectForKey("subscriptionIDFor\(recordType)") as? String
        if (subscriptionID != nil) {
            modifyOperation.subscriptionIDsToDelete = [subscriptionID!]
            modifyOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptions, error in
                self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                    defaults.removeObjectForKey("subscriptionFor_\(recordType)_\(filterId)")
                    })
            }
            database.addOperation(modifyOperation)
        }
    }
    
    // subscribe for modifications to a recordType with a reference to the user
    func subscribe(type:NSObject, referenceRecordName:String, referenceField:String, errorHandler:(error: NSError) -> Void) {
        var recordType = swiftStringFromClass(type)
        var parentId = CKRecordID(recordName: referenceRecordName)
        var parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        var predicate = NSPredicate(format: "%K == %@", referenceField ,parent)
        subscribe(type, predicate:predicate, filterId: "reference_\(referenceField)", errorHandler: errorHandler)
    }
    
    // unsubscribe for modifications to a recordType with a reference to the user
    func unsubscribe(type:NSObject, referenceRecordName:String, referenceField:String, errorHandler:(error: NSError) -> Void) {
        unsubscribe(type, filterId:"reference_\(referenceField)", errorHandler: errorHandler)
    }

    // subscribe for modifications to a recordType
    func subscribe(type:NSObject, errorHandler:(error: NSError) -> Void) {
        subscribe(type, predicate:NSPredicate(value: true), filterId: "all", errorHandler: errorHandler)
    }

    // unsubscribe for modifications to a recordType
    func unsubscribe(type:NSObject, errorHandler:(error: NSError) -> Void) {
        unsubscribe(type, filterId:"all", errorHandler:errorHandler)
    }


    // ------------------------------------------------------------------------
    // MARK: - Handling remote notifications
    // ------------------------------------------------------------------------
    
    // call this from the AppDelegate didReceiveRemoteNotification
    func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject]!, executeIfNonQuery:() -> Void, inserted:(recordID:String, item: NSObject) -> Void, updated:(recordID:String, item: NSObject) -> Void, deleted:(recordId: String) -> Void) {
        var cloudNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        var alertBody = cloudNotification.alertBody
        NSLog("Notification alert body : \(alertBody)")
        
        // Handle CloudKit subscription notifications
        if cloudNotification.notificationType == CKNotificationType.Query {
            var queryNotification: CKQueryNotification = cloudNotification as CKQueryNotification
            var recordID = queryNotification.recordID
            NSLog("recordID = \(recordID)")
            if(queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordCreated) {
                deleted(recordId: recordID.recordName)
            } else {
                var dao: EVCloudKitDao = EVCloudKitDao.instance
                dao.getItem(recordID.recordName, completionHandler: { item in
                    NSLog("getItem: recordType = \(dao.swiftStringFromClass(item)), with the keys and values:")
                    dao.logObject(item)
                    if (queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordCreated ) {
                        inserted(recordID: recordID.recordName, item: item)
                    } else if(queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordUpdated){
                        updated(recordID: recordID.recordName, item: item)
                    }
                    }, errorHandler: { error in
                        NSLog("<--- ERROR getItem")
                    })
            }
            
        } else {
            executeIfNonQuery()
        }
        fetchChangeNotifications(inserted , updated: updated, deleted: deleted)
    }

    // Call this in the AppDelegate didFinishLaunchingWithOptions to handle not yet handled notifications.
    // Also call this in the AppDelegate didReceiveRemoteNotification because not all notifications will be pushed if there are multiple.
    func fetchChangeNotifications(inserted:(recordID:String, item: NSObject) -> Void, updated:(recordID:String, item: NSObject) -> Void, deleted:(recordId: String) -> Void) {
        var defaults = NSUserDefaults.standardUserDefaults()
        var array: [NSObject] = [NSObject]()
        var operation = CKFetchNotificationChangesOperation(previousServerChangeToken: self.previousChangeToken)
        operation.notificationChangedBlock = { notification in
            if(notification.notificationType == .Query) {
                var queryNotification:CKQueryNotification = notification as CKQueryNotification
                array.append(notification.notificationID)
                
                if (queryNotification.queryNotificationReason == .RecordDeleted) {
                    deleted(recordId: queryNotification.recordID.recordName)
                } else {
                    var dao: EVCloudKitDao = EVCloudKitDao.instance
                    dao.getItem(queryNotification.recordID.recordName, completionHandler: { item in
                        NSLog("getItem: recordType = \(dao.swiftStringFromClass(item)), with the keys and values:")
                        dao.logObject(item)
                        if (queryNotification.queryNotificationReason == .RecordCreated) {
                            inserted(recordID: queryNotification.recordID.recordName, item: item)
                        } else if (queryNotification.queryNotificationReason == .RecordUpdated) {
                            updated(recordID: queryNotification.recordID.recordName, item: item)
                        }
                        }, errorHandler: { error in
                            NSLog("<--- ERROR getItem")
                        })
                }
            }
        }
        operation.fetchNotificationChangesCompletionBlock = { changetoken, error in
            var op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: array)
            op.start()
            NSLog("changetoken = \(changetoken)")
            self.previousChangeToken = changetoken
            
            if(operation.moreComing) {
                self.fetchChangeNotifications(inserted, updated, deleted)
            }
        }
        operation.start()
    }
    
    // Saving the changetoken in the userdefaults
    var previousChangeToken:CKServerChangeToken? {
        get {
            let encodedObjectData = NSUserDefaults.standardUserDefaults().objectForKey("lastFetchNotificationId") as? NSData
            if ((encodedObjectData) != nil) {
                return NSKeyedUnarchiver.unarchiveObjectWithData(encodedObjectData!) as? CKServerChangeToken
            }
            return nil
        }
        set(newToken) {
            if ((newToken) != nil) {
                NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(newToken!), forKey:"lastFetchNotificationId")
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Reflection methods
    // ------------------------------------------------------------------------
    
    // Convert a CloudKit record to an object
    func fromCKRecord(record: CKRecord) -> NSObject {
        return fromDictionary(CKRecordToDictionary(record), anyobjectTypeString: record.recordType)
    }
    
    // Create an object from a dictionary
    func fromDictionary(dictionary:Dictionary<String, AnyObject?>, anyobjectTypeString: String) -> NSObject {
        var anyobjectype : AnyObject.Type = swiftClassFromString(anyobjectTypeString)
        var nsobjectype : NSObject.Type = anyobjectype as NSObject.Type
        var nsobject: NSObject = nsobjectype()
        for (key: String, value: AnyObject?) in dictionary {
            if (dictionary[key] != nil) {
                nsobject.setValue(dictionary[key]!, forKey: key)
            }
        }
        return nsobject
    }
    
    // Convert an object to a CKRecord
    func toCKRecord(theObject: NSObject) -> CKRecord {
        var record = CKRecord(recordType: swiftStringFromClass(theObject))
        var fromDict = toDictionary(theObject)
        for (key: String, value: AnyObject?) in fromDict {
            record.setValue(value, forKey: key)
        }
        return record
    }
    
    // Convert CKRecord to dictionary
    func CKRecordToDictionary(ckRecord:CKRecord) -> Dictionary<String, AnyObject?> {
        var dictionary = Dictionary<String, AnyObject>()
        for field in ckRecord.allKeys() {
            dictionary[field as NSString] = ckRecord.objectForKey(field as NSString)
        }
        return dictionary
    }
    
    // Convert an object to a dictionary
    func toDictionary(theObject: NSObject) -> Dictionary<String, AnyObject?> {
        var propertiesDictionary : Dictionary<String, AnyObject?> = Dictionary<String, AnyObject?>()
        for i in 0..<reflect(theObject).count {
            let key : String = reflect(theObject)[i].0
            let value = reflect(theObject)[i].1.value
            if key != "super" {
                var v : AnyObject? = valueForAny(value)
                propertiesDictionary.updateValue(v, forKey: key)
            }
        }
        return propertiesDictionary
    }
    
    // Helper method for getting a reference (with delete action)
    func referenceForId(recordId:String) -> CKReference {
        return CKReference(recordID: CKRecordID(recordName: recordId), action: CKReferenceAction.DeleteSelf)
    }
    
    // Dump the content of this object
    func logObject(theObject: NSObject) {
        for (key: String, value: AnyObject?) in toDictionary(theObject) {
            NSLog("key = \(key), value = \(value)")
        }
    }
    
    // Get the swift Class from a string
    func swiftClassFromString(className: String) -> AnyClass! {
        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String? {
            let classStringName = "\(appName).\(className)"
            return NSClassFromString(classStringName)
        }
        return nil;
    }

    // Get the class name as a string from a swift class
    func swiftStringFromClass(theObject: NSObject) -> String! {
        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String? {
            let classStringName: String = NSStringFromClass(theObject.dynamicType)
            return classStringName.stringByReplacingOccurrencesOfString(appName + ".", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        return nil;
    }
    
    // Helper function to convert an Any to AnyObject
    //TODO: Make this work with nulable types
    func valueForAny(anyValue:Any) -> NSObject? {
        switch(anyValue) {
        case let intValue as Int:
            return NSNumber(int: CInt(intValue))
        case let doubleValue as Double:
            return NSNumber(double: CDouble(doubleValue))
        case let stringValue as String:
            return stringValue as NSString
        case let boolValue as Bool:
            return NSNumber(bool: boolValue)
        case let anyvalue as CKReference:
            return anyvalue as CKReference
        case let anyvalue as CKAsset:
            return anyvalue as CKAsset
        case let anyvalue as NSObject:
            return anyvalue as NSObject
        default:
            return nil
        }
    }
}