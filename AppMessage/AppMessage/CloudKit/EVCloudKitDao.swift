//
//  EVCloudKitDao.swift
//
//  Created by Edwin Vermeer on 04-06-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

/**
Class for simplified access to  Apple's CloudKit data where you still have full control
*/
class EVCloudKitDao {
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    /** 
    Singleton access to EVCloudKitDao that can be called from Swift
    
    :return: The EVCLoudKitDao object
    */
    class var instance : EVCloudKitDao {
        struct Static { static let instance : EVCloudKitDao = EVCloudKitDao() }
        return Static.instance
    }
    
    /**
    Singleton access to EVCloudKitDao that can be called from Objective C
    
    :return: The EVCLoudKitDao object
    */
    class func sharedInstance() -> EVCloudKitDao {
        return instance;
    }
    
    /**
    Access to the default CloudKit container
    
    :return: The default CloudKit container
    */
    private var container : CKContainer

    
    /**
    Access to the public database
    
    :return: The public database
    */
    private var database : CKDatabase
    
    internal var activeUser : CKDiscoveredUserInfo!
    
    /**
    On init set a quick refrence to the container and database
    */
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

    //
    /**
    Generic CloudKit callback handling
    
    :param: error Passing on the error
    :param: errorHandler The error handler function that will be called if there is an error
    :param: completionHandler The function that will be called if ther is no error
    :return: No return value
    */
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
    
    
    /**
    Generic query handling
    
    :param: type An object instance that will be used as the type of the records that will be returned
    :param: query The CloudKit query that will be executed
    :param: completionHandler The function that will be called with the result of the query
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
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
    
    /**
    Helper method for getting a reference (with delete action)
    
    :param: recordId The record id that will be converted to a CKReference
    :return: The CKReference that is created from the recordId
    */
    func referenceForId(recordId:String) -> CKReference {
        return CKReference(recordID: CKRecordID(recordName: recordId), action: CKReferenceAction.DeleteSelf)
    }
    

    // ------------------------------------------------------------------------
    // MARK: - Data methods - initialize record types
    // ------------------------------------------------------------------------

    /**
    This is a helper method that inserts and removes records in order to create the recordtypes in the iCloud
    You only need to call this method once, ever.
    
    :param: types An array of objects for which CloudKit record types should be generated
    :return: No return value
    */
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
        NSException(name: "RunOnlyOnce", reason: "Call this method only once. Only here for easy debugging reasons for fast generation of the iCloud recordTypes. Sorry for the hard crash. Now disable the call to this method in the AppDelegate!  Then go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!", userInfo: nil).raise()
    }

    
    // ------------------------------------------------------------------------
    // MARK: - Data methods - rights and contacts
    // ------------------------------------------------------------------------
    
    /**
    Are we allowed to call the discoverUserInfo function?
    
    :param: completionHandler The function that will be called with the result of the query (true or false)
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func requestDiscoverabilityPermission(completionHandler: (granted: Bool) -> Void, errorHandler:(error: NSError) -> Void) {
    container.requestApplicationPermission(CKApplicationPermissions.PermissionUserDiscoverability, completionHandler: { applicationPermissionStatus, error in
        self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(granted: applicationPermissionStatus == CKApplicationPermissionStatus.Granted)
            })
        })
    }

    /**
    Get the info of the current user
    
    :param: completionHandler The function that will be called with the CKDiscoveredUserInfo object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
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

    /**
    Combined ask for rights and get the current user
    
    :param: completionHandler The function that will be called with the CKDiscoveredUserInfo object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func getUserInfo(completionHandler: (user: CKDiscoveredUserInfo) -> Void, errorHandler:(error:NSError) -> Void) {
        self.requestDiscoverabilityPermission({ discoverable in
            if discoverable {
                self.discoverUserInfo({user in
                        self.activeUser = user
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
    
    /**
    Who or our contacts is using the same app (will get a system popup requesting permitions)
    
    :param: completionHandler The function that will be called with an array of CKDiscoveredUserInfo objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func allContactsUserInfo(completionHandler: (users: [CKDiscoveredUserInfo]!) -> Void, errorHandler:(error:NSError) -> Void) {
        container.discoverAllContactUserInfosWithCompletionHandler({users, error in
            self.handleCallback(error, errorHandler:{errorHandler(error: error)}, completionHandler: {
                completionHandler(users:users as [CKDiscoveredUserInfo])
            })
        })
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - CRUD
    // ------------------------------------------------------------------------
    
    /**
    Get an Item for a recordId

    :param: recordId The CloudKit record id that we want to get.
    :param: completionHandler The function that will be called with the object that we aksed for
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func getItem(recordId: String, completionHandler: (result: NSObject) -> Void, errorHandler:(error: NSError) -> Void) {
        database.fetchRecordWithID(CKRecordID(recordName: recordId), completionHandler: {record, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(result: self.fromCKRecord(record));
            })
        })
    }
    
    /**
    Save an item. Relate to other objects with property CKReference or save an asset using CKAsset
    
    :param: item object that we want to save
    :param: completionHandler The function that will be called with a CKRecord representation of the saved object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func saveItem(item: NSObject, completionHandler: (record: CKRecord) -> Void, errorHandler:(error: NSError) -> Void) {
        var theRecord = self.toCKRecord(item)
        database.saveRecord(theRecord, completionHandler: { record, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                completionHandler(record: record);
            })
        })
    }
    
    /**
    Delete an Item for a recordId
    
    :param: recordId The CloudKit record id of the record that we want to delete
    :param: completionHandler The function that will be called with a record id of the deleted object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
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
    
    /**
    Query a record type
    
    :param: type An instance of the Object for what we want to query the record type
    :param: completionHandler The function that will be called with a dictionary of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func query<T:NSObject>(type:T, completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /**
    Query child object of a recordType
    
    :param: type An instance of the Object for what we want to query the record type
    :param: referenceRecordName The CloudKit record id that we are looking for
    :param: referenceField The name of the field that we will query for the referenceRecordName
    :param: completionHandler The function that will be called with a dictionary of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func query<T:NSObject>(type:T, referenceRecordName:String, referenceField:String ,completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var parentId = CKRecordID(recordName: referenceRecordName)
        var parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "%K == %@", referenceField ,parent))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    
    /**
    Query a recordType with a predicate
    
    :param: type An instance of the Object for what we want to query the record type
    :param: predicate The predicate with the filter for our query
    :param: completionHandler The function that will be called with a dictionary of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func query<T:NSObject>(type:T, predicate: NSPredicate, completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void){
        var recordType = EVReflection.swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: predicate)
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // TODO: Was in the 208 lab, since beta 3 it does not work anymore. also tried the "self contains '\(tokens)'"
    /**
    Query a recordType for some tokens
    
    :param: type An instance of the Object for what we want to query the record type
    :param: tokens The tokens that we will query for (words seperated by a space)
    :param: completionHandler The function that will be called with a dictionary of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func query<T:NSObject>(type:T, tokens:String ,completionHandler: (results: Dictionary<String, T>) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = EVReflection.swiftStringFromClass(T())
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "ALL tokenize('\(tokens)', ‘Cdl') IN allTokens"))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - Subscriptions
    // ------------------------------------------------------------------------

    /**
    Subscribe for modifications to a recordType and predicate (and register it under filterId)
    
    :param: type An instance of the Object for what we want to query the record type
    :param: predicate The predicate with the filter for our subscription
    :param: configureNotificationInfo The function that will be called with the CKNotificationInfo object so that we can configure it
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func subscribe(type:NSObject, predicate:NSPredicate, filterId:String, configureNotificationInfo:(notificationInfo:CKNotificationInfo ) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var defaults = NSUserDefaults.standardUserDefaults()
        if defaults.boolForKey("subscriptionFor_\(recordType)_\(filterId)") { return }
        
        var subscription = CKSubscription(recordType: recordType, predicate: predicate, options: .FiresOnRecordCreation | .FiresOnRecordUpdate | .FiresOnRecordDeletion)
        subscription.notificationInfo = CKNotificationInfo()
        subscription.notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo.soundName = UILocalNotificationDefaultSoundName
        configureNotificationInfo(notificationInfo: subscription.notificationInfo)
        database.saveSubscription(subscription, completionHandler: { savedSubscription, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                defaults.setBool(true, forKey: "subscriptionFor_\(recordType)_\(filterId)")
                defaults.setObject(subscription.subscriptionID, forKey: "subscriptionIDFor_\(recordType)_\(filterId)")
                })
            })
    }
    
    /**
    Unsubscribe for modifications to a recordType and predicate (and unregister is under filterId)
    
    :param: type An instance of the Object for what we want to query the record type
    :param: filterId The id of the filter that you want to unsubscibe
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func unsubscribe(type:NSObject, filterId:String, errorHandler:(error: NSError) -> Void) {
        var recordType = EVReflection.swiftStringFromClass(type)
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
    
    /**
    Subscribe for modifications to child object of a record
    
    :param: type An instance of the Object for what we want to subscribe for
    :param: referenceRecordName The CloudKit record id that we are looking for
    :param: referenceField The name of the field that we will query for the referenceRecordName
    :param: configureNotificationInfo The function that will be called with the CKNotificationInfo object so that we can configure it
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func subscribe(type:NSObject, referenceRecordName:String, referenceField:String, configureNotificationInfo:(notificationInfo:CKNotificationInfo) -> Void, errorHandler:(error: NSError) -> Void) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var parentId = CKRecordID(recordName: referenceRecordName)
        var parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        var predicate = NSPredicate(format: "%K == %@", referenceField ,parent)
        subscribe(type, predicate:predicate!, filterId: "reference_\(referenceField)_\(referenceRecordName)",configureNotificationInfo: configureNotificationInfo ,errorHandler: errorHandler)
    }
    
    /**
    Unsubscribe for modifications to a recordType with a reference to the user
    
    :param: type An instance of the Object for what we want to query the record type
    :param: referenceRecordName The CloudKit record id that we are looking for
    :param: referenceField The name of the field that we will query for the referenceRecordName
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func unsubscribe(type:NSObject, referenceRecordName:String, referenceField:String, errorHandler:(error: NSError) -> Void) {
        unsubscribe(type, filterId:"reference_\(referenceField)_\(referenceRecordName)", errorHandler: errorHandler)
    }

    /**
    Subscribe for modifications to a recordType
    
    :param: type An instance of the Object for what we want to subscribe for
    :param: configureNotificationInfo The function that will be called with the CKNotificationInfo object so that we can configure it
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func subscribe(type:NSObject, configureNotificationInfo:(notificationInfo:CKNotificationInfo) -> Void, errorHandler:(error: NSError) -> Void) {
        subscribe(type, predicate:NSPredicate(value: true), filterId: "all", configureNotificationInfo: configureNotificationInfo ,errorHandler: errorHandler)
    }

    /**
    Unsubscribe for modifications to a recordType
    
    :param: type An instance of the Object for what we want to query the record type
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func unsubscribe(type:NSObject, errorHandler:(error: NSError) -> Void) {
        unsubscribe(type, filterId:"all", errorHandler:errorHandler)
    }

    /**
    Unsubscribe for all modifications
    
    :param: errorHandler The function that will be called when there was an error
    :param: completionHandler The function that will be called with a number which is the count of messages removed.
    :return: No return value
    */
    func unsubscribeAll(completionHandler:(subscriptionCount: Int) -> Void , errorHandler:(error: NSError) -> Void) {
        database.fetchAllSubscriptionsWithCompletionHandler({subscriptions, error in
            self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                for subscriptionObject in subscriptions {
                    var subscription: CKSubscription = subscriptionObject as CKSubscription
                    self.database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {subscriptionId, error in
                        self.handleCallback(error, errorHandler: {errorHandler(error: error)}, completionHandler: {
                            NSLog("Subscription with id \(subscriptionId) was removed : \(subscription.description)")
                        })
                    })
                }
                completionHandler(subscriptionCount: subscriptions.count)
            })
        })
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - Handling remote notifications
    // ------------------------------------------------------------------------
    
    /**
    Method for processing remote notifications. Call this from the AppDelegate didReceiveRemoteNotification
    
    :param: userInfo CKNotification dictionary
    :param: executeIfNonQuery Function that will be executed if the notification was not for a subscription
    :param: inserted Executed if the notification was for an inserted object
    :param: updated Executed if the notification was for an updated object
    :param: deleted Executed if the notification was for an deleted object
    :return: No return value
    */
    func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject]!, executeIfNonQuery:() -> Void, inserted:(recordID:String, item: NSObject) -> Void, updated:(recordID:String, item: NSObject) -> Void, deleted:(recordId: String) -> Void) {
        var cloudNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        var alertBody = cloudNotification.alertBody
        NSLog("Notification alert body : \(alertBody)")
        
        // Handle CloudKit subscription notifications
        var recordID:CKRecordID?
        if cloudNotification.notificationType == CKNotificationType.Query {
            var queryNotification: CKQueryNotification = cloudNotification as CKQueryNotification
            recordID = queryNotification.recordID
            NSLog("recordID = \(recordID)")
            if(queryNotification.queryNotificationReason == .RecordDeleted) {
                deleted(recordId: recordID!.recordName)
            } else {
                EVCloudKitDao.instance.getItem(recordID!.recordName, completionHandler: { item in
                    NSLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                    EVReflection.logObject(item)
                    if (queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordCreated ) {
                        inserted(recordID: recordID!.recordName, item: item)
                    } else if(queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordUpdated){
                        updated(recordID: recordID!.recordName, item: item)
                    }
                    }, errorHandler: { error in
                        NSLog("<--- ERROR getItem")
                    })
            }
        } else {
            executeIfNonQuery()
        }
        fetchChangeNotifications(recordID, inserted , updated: updated, deleted: deleted)
    }
    
    /**
    Method for pulling all subscription notifications.
    Call this in the AppDelegate didFinishLaunchingWithOptions to handle not yet handled notifications.
    Also call this in the AppDelegate didReceiveRemoteNotification because not all notifications will be pushed if there are multiple.
    
    :param: inserted Executed if the notification was for an inserted object
    :param: updated Executed if the notification was for an updated object
    :param: deleted Executed if the notification was for an deleted object
    :return: No return value
    */
    func fetchChangeNotifications(skipRecordID:CKRecordID?, inserted:(recordID:String, item: NSObject) -> Void, updated:(recordID:String, item: NSObject) -> Void, deleted:(recordId: String) -> Void) {
        var defaults = NSUserDefaults.standardUserDefaults()
        var array: [NSObject] = [NSObject]()
        var operation = CKFetchNotificationChangesOperation(previousServerChangeToken: self.previousChangeToken)
        operation.notificationChangedBlock = { notification in
            if(notification.notificationType == .Query) {
                var queryNotification:CKQueryNotification = notification as CKQueryNotification
                array.append(notification.notificationID)
                if(skipRecordID != nil && skipRecordID?.recordName != queryNotification.recordID.recordName) {
                    if (queryNotification.queryNotificationReason == .RecordDeleted) {
                        deleted(recordId: queryNotification.recordID.recordName)
                    } else {
                        EVCloudKitDao.instance.getItem(queryNotification.recordID.recordName, completionHandler: { item in
                            NSLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                            EVReflection.logObject(item)
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
        }
        operation.fetchNotificationChangesCompletionBlock = { changetoken, error in
            var op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: array)
            op.start()
            NSLog("changetoken = \(changetoken)")
            self.previousChangeToken = changetoken
            
            if(operation.moreComing) {
                self.fetchChangeNotifications(skipRecordID, inserted, updated, deleted)
            }
        }
        operation.start()
    }
    
    /**
    Property for saving the changetoken in the userdefaults
    */
    private var previousChangeToken:CKServerChangeToken? {
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
    // MARK: - Converting a CKRecord from and to an object
    // ------------------------------------------------------------------------
    
    /**
    Convert a CKrecord to an object
    
    :param: record The CKRecord that will be converted to an object
    :return: The object that is created from the record
    */
    func fromCKRecord(record: CKRecord) -> NSObject {
        return EVReflection.fromDictionary(CKRecordToDictionary(record), anyobjectTypeString: record.recordType)
    }
    
    /**
    Convert an object to a CKRecord
    
    :param: theObject The object that will be converted to a CKRecord
    :return: The CKRecord that is created from theObject
    */
    func toCKRecord(theObject: NSObject) -> CKRecord {
        var record = CKRecord(recordType: EVReflection.swiftStringFromClass(theObject))
        var fromDict = EVReflection.toDictionary(theObject)
        for (key: String, value: AnyObject?) in fromDict {
            record.setValue(value, forKey: key)
        }
        return record
    }
    
    /**
    Convert CKRecord to dictionary
    
    :param: record The CKRecord that will be converted to a dictionary
    :return: The dictionary that is created from the record
    */
    func CKRecordToDictionary(record:CKRecord) -> Dictionary<String, AnyObject?> {
        var dictionary = Dictionary<String, AnyObject>()
        for field in record.allKeys() {
            dictionary[field as NSString] = record.objectForKey(field as NSString)
        }
        return dictionary
    }
}


/**
Extending the Dictionary
*/
extension Dictionary {
    /**
    Make a Dictionary subscriptable by an index so that you can return the value for an index instead of its key
    
    :param: index The index of the object to return
    */
    subscript(index: Int) -> Value? {
        get {
            var i:Int = 0
            for (key, item) in self {
                if i == index {
                    return item
                }
                i++
            }
            return nil
        }
    }
}
