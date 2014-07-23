//
//  EVCloudKitDao.swift
//
//  Created by Edwin Vermeer on 04-06-14.
//  Copyright (c) 2014 Evict. All rights reserved.
//

import CloudKit

class EVCloudKitDao {
    
    // ------------------------------------------------------------------------
    // - Initialisation
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
            if error { NSLog("Error = \(error.description)")}
            NSLog("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
        })
        NSLog("Container identifier = \(container.containerIdentifier)")
        database = container.publicCloudDatabase
    }

    // ------------------------------------------------------------------------
    // - Helper methods
    // ------------------------------------------------------------------------

    // Generic CloudKit callback handling
    func handleCallback(error: NSError?, errorHandler: () -> Void, completionHandler: () -> Void) {
        //NSOperationQueue.mainQueue().addOperationWithBlock {
            if error {
                NSLog("CloudKit Error : \(error?.code) = \(error?.description) \n\(error?.userInfo)")
                errorHandler()
            } else {
                completionHandler()
            }
        //}
    }
    
    // Generic query handling
    func queryRecords(query: CKQuery, completionHandler: (results: NSArray) -> Void, errorHandler:(error: NSError) -> Void) {
        // Not sortable anymore!?
//        if !query.sortDescriptors {
//            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//        }
        var operation = CKQueryOperation(query: query)
        var results = NSMutableArray()
        operation.recordFetchedBlock = { record in
            results.addObject(self.fromCKRecord(record))
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
    // - Data methods - rights and contacts
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
    // - Data methods - CRUD
    // ------------------------------------------------------------------------
    
    // Get an Item for a recordId
    func getItem(recordId: String, completionHandler: (result: AnyObject) -> Void, errorHandler:(error: NSError) -> Void) {
        database.fetchRecordWithID(CKRecordID(recordName: recordId), completionHandler: {record, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(result: self.fromCKRecord(record));
            })
        })
    }
    
    // Save an item. Relate to other objects with property CKReference or save an asset using CKAsset
    func saveItem(item: AnyObject, completionHandler: (record: CKRecord) -> Void, errorHandler:(error: NSError) -> Void) {
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
    // - Data methods - Query
    // ------------------------------------------------------------------------
    
    // Query a recordType
    func query(recordType:String, completionHandler: (results: NSArray) -> Void, errorHandler:(error: NSError) -> Void) {
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        queryRecords(query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // Query child object of a recordType
    func query(recordType:String, referenceRecordName:String, referenceField:String ,completionHandler: (results: NSArray) -> Void, errorHandler:(error: NSError) -> Void) {
        var parentId = CKRecordID(recordName: referenceRecordName)
        var parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "%K == %@", referenceField ,parent))
        queryRecords(query, completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    // Query a recordType with a predicate
    func query(recordType:String, predicate: NSPredicate, completionHandler: (results: NSArray) -> Void, errorHandler:(error: NSError) -> Void){
        var query = CKQuery(recordType: recordType, predicate: predicate)
        queryRecords(query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // TODO: Was in the 208 lab, since beta 3 it does not work anymore.
    // Query child a recordType for some tokens
    func query(recordType:String, tokens:String ,completionHandler: (results: NSArray) -> Void, errorHandler:(error: NSError) -> Void) {
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "ALL tokenize(&@, 'Cdl') IN allTokens", tokens))
        queryRecords(query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // ------------------------------------------------------------------------
    // - Data methods - Subscriptions
    // ------------------------------------------------------------------------

    // subscribe for modifications to a recordType and predicate (and register it under filterId)
    func subscribe(recordType : String, predicate:NSPredicate, filterId:String ,errorHandler:(error: NSError) -> Void) {
        var defaults = NSUserDefaults.standardUserDefaults()
        if defaults.boolForKey("subscriptionFor_\(recordType)_\(filterId)") { return }
        
        var subscription = CKSubscription(recordType: recordType, predicate: predicate, options: .FiresOnRecordCreation | .FiresOnRecordUpdate | .FiresOnRecordDeletion)
        subscription.notificationInfo = CKNotificationInfo()
        subscription.notificationInfo.alertBody = "New item added to \(recordType), \(filterId)"
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
    func unsubscribe(recordType : String, filterId:String, errorHandler:(error: NSError) -> Void) {
        var defaults = NSUserDefaults.standardUserDefaults()
        if !defaults.boolForKey("subscriptionFor_\(recordType)_\(filterId)") { return }
        
        var modifyOperation = CKModifySubscriptionsOperation()
        var subscriptionID : String? = defaults.objectForKey("subscriptionIDFor\(recordType)") as? String
        if subscriptionID {
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
    func subscribe(recordType:String, referenceRecordName:String, referenceField:String, errorHandler:(error: NSError) -> Void) {
        var parentId = CKRecordID(recordName: referenceRecordName)
        var parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        var predicate = NSPredicate(format: "%K == %@", referenceField ,parent)
        subscribe(recordType, predicate: predicate, filterId: "reference_\(referenceField)", errorHandler: errorHandler)
    }
    
    // unsubscribe for modifications to a recordType with a reference to the user
    func unsubscribe(recordType : String, referenceRecordName:String, referenceField:String, errorHandler:(error: NSError) -> Void) {
        unsubscribe(recordType, filterId: "reference_\(referenceField)", errorHandler: errorHandler)
    }

    // subscribe for modifications to a recordType
    func subscribe(recordType : String, errorHandler:(error: NSError) -> Void) {
        subscribe(recordType, predicate: NSPredicate(value: true), filterId: "all", errorHandler: errorHandler)
    }

    // unsubscribe for modifications to a recordType
    func unsubscribe(recordType : String, errorHandler:(error: NSError) -> Void) {
        unsubscribe(recordType, filterId: "all", errorHandler: errorHandler)
    }

    
    // ------------------------------------------------------------------------
    // - Reflection methods
    // ------------------------------------------------------------------------
    
    // Convert a CloudKit record to an object
    func fromCKRecord(record: CKRecord) -> AnyObject {
        var anyobjectype : AnyObject.Type = NSClassFromString("_" + record.recordType)
        var nsobjectype : NSObject.Type = anyobjectype as NSObject.Type
        var nsobject: NSObject = nsobjectype()
        var myobject: AnyObject = nsobject as AnyObject
        var fromDict = toDictionary(myobject)
        for (key: String, value: AnyObject?) in fromDict {
            nsobject.setValue(record.valueForKey(key), forKey: key)
        }
        return myobject
    }
    
    // The CloudKit recordtype for an object
    func recordType(theObject: AnyObject) -> String {
        return NSStringFromClass(theObject.dynamicType).stringByReplacingOccurrencesOfString("_", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
    }
    
    // Helper method for getting a reference (with delete action)
    func referenceForId(recordId:String) -> CKReference {
        return CKReference(recordID: CKRecordID(recordName: recordId), action: CKReferenceAction.DeleteSelf)
    }
    
    // Convert an object to a CKRecord
    func toCKRecord(theObject: AnyObject) -> CKRecord {
        var record = CKRecord(recordType: recordType(theObject))
        var fromDict = toDictionary(theObject)
        for (key: String, value: AnyObject?) in fromDict {
            record.setValue(value, forKey: key)
        }
        return record
    }
    
    // Convert an object to a dictionary
    func toDictionary(theObject: AnyObject) -> Dictionary<String, AnyObject?> {
        var propertiesDictionary : Dictionary<String, AnyObject?> = Dictionary<String, AnyObject?>()
        for i in 0..<reflect(theObject).count {
            let key : String = reflect(theObject)[i].0
            let value = reflect(theObject)[i].1.value
            if key != "super" {
                var v : NSObject? = valueForAny(value)
                propertiesDictionary.updateValue(v, forKey: key)
            }
        }
        return propertiesDictionary
    }
    
    // Dump the content of this object
    func logObject(theObject: AnyObject) {
        for (key: String, value: AnyObject?) in toDictionary(theObject) {
            NSLog("key = \(key), value = \(value)")
        }
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