//
//  EVCloudKitDao.swift
//
//  Created by Edwin Vermeer on 04-06-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

public func EVLog<T>(object: T, filename: String = __FILE__, line: Int = __LINE__, funcname: String = __FUNCTION__) {
    var dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
    var process = NSProcessInfo.processInfo()
    var threadId = "." //NSThread.currentThread().threadDictionary
    println("\(dateFormatter.stringFromDate(NSDate())) \(process.processName))[\(process.processIdentifier):\(threadId)] \(filename.lastPathComponent)(\(line)) \(funcname):\r\t\(object)\n")
}

/**
Wrapper class for being able to use a class instance Dictionary
*/
private class DaoContainerWrapper {
    var publicContainers : Dictionary<String,EVCloudKitDao> = Dictionary<String,EVCloudKitDao>()
    var privateContainers : Dictionary<String,EVCloudKitDao> = Dictionary<String,EVCloudKitDao>()
}

/**
Class for simplified access to  Apple's CloudKit data where you still have full control
*/
public class EVCloudKitDao {
    
    // ------------------------------------------------------------------------
    // MARK: - For getting the various instances
    // ------------------------------------------------------------------------
    
    /** 
    Singleton access to EVCloudKitDao public database that can be called from Swift
    
    :return: The EVCLoudKitDao object
    */
    public class var publicDB : EVCloudKitDao {
        struct Static { static let instance : EVCloudKitDao = EVCloudKitDao() }
        return Static.instance
    }
    
    /**
    Singleton access to EVCloudKitDao public database that can be called from Objective C
    
    :return: The EVCLoudKitDao object
    */
    public class func sharedPublicDB() -> EVCloudKitDao {
        return publicDB;
    }

    
    /**
    Singleton access to EVCloudKitDao private database that can be called from Swift
    
    :return: The EVCLoudKitDao object
    */
    public class var privateDB : EVCloudKitDao {
        struct Static { static let instance : EVCloudKitDao = EVCloudKitDao() }
        Static.instance.database = Static.instance.container.privateCloudDatabase
        return Static.instance
    }
    
    
    /**
    Singleton access to EVCloudKitDao private database that can be called from Objective C
    
    :return: The EVCLoudKitDao object
    */
    public class func sharedPrivateDB() -> EVCloudKitDao {
        return privateDB;
    }
    
    
    /**
    Singleton acces to the wrapper class with the dictionaries with public and private containers.
    
    :return: The container wrapper class
    */
    private class var containerWrapperInstance : DaoContainerWrapper {
        struct Static { static var instance : DaoContainerWrapper = DaoContainerWrapper()}
        return Static.instance
    }
    
    
    /**
    Singleton acces to a specific named public container
    :param: containterIdentifier The identifier of the public container that you want to use.
    
    :return: The public container for the identifier.
    */
    public class func publicDBForContainer(containterIdentifier:String) -> EVCloudKitDao {
        if let containerInstance = containerWrapperInstance.publicContainers[containterIdentifier] {
            return containerInstance
        }
        containerWrapperInstance.publicContainers[containterIdentifier] =  EVCloudKitDao(containerIdentifier: containterIdentifier)
        return containerWrapperInstance.publicContainers[containterIdentifier]!
    }

    
    /**
    Singleton acces to a specific named private container
    :param: containterIdentifier The identifier of the private container that you want to use.
    
    :return: The private container for the identifier.
    */
    public class func privateDBForContainer(containterIdentifier:String) -> EVCloudKitDao {
        if let containerInstance = containerWrapperInstance.privateContainers[containterIdentifier] {
            return containerInstance
        }
        containerWrapperInstance.privateContainers[containterIdentifier] =  EVCloudKitDao(containerIdentifier: containterIdentifier)
        return containerWrapperInstance.privateContainers[containterIdentifier]!
    }


    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
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
    

    /**
    The iClout account status of the current user
    
    :return: The account status of the current user
    */
    public var accountStatus : CKAccountStatus?
    
    /**
    The iClout account information of the current user
    
    :return: The account information of the current user
    */
    public var activeUser : CKDiscoveredUserInfo!
    
    /**
    On init set a quick refrence to the container and database
    */
    init() {
        container = CKContainer.defaultContainer()
        database = container.publicCloudDatabase
        container.accountStatusWithCompletionHandler({status, error in
            if (error != nil) {
                EVLog("Error: Initialising EVCloudKitDao - accountStatusWithCompletionHandler.\n\(error.description)")
            } else {
                self.accountStatus = status
            }
            EVLog("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
        })
        EVLog("Container identifier = \(container.containerIdentifier)")
    }

    
    /**
    On init set a quick refrence to the container and database for a specific container.
    */
    init(containerIdentifier: String) {
        container = CKContainer(identifier: containerIdentifier)
        database = container.publicCloudDatabase
        container.accountStatusWithCompletionHandler({status, error in
            if (error != nil) {
                EVLog("Error: Initialising EVCloudKitDao - accountStatusWithCompletionHandler.\n\(error.description)")
            } else {
                self.accountStatus = status
            }
            EVLog("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
        })
        EVLog("Container identifier = \(container.containerIdentifier)")
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
    internal func handleCallback(error: NSError?, errorHandler: ((error: NSError) -> Void)? = nil, completionHandler: () -> Void) {
        if (error != nil) {
            EVLog("Error: \(error?.code) = \(error?.description) \n\(error?.userInfo)")
            if let handler = errorHandler {
                handler(error: error!)
            }
        } else {
            completionHandler()
        }
    }
    
    
    /**
    Generic query handling
    
    :param: type An object instance that will be used as the type of the records that will be returned
    :param: query The CloudKit query that will be executed
    :param: completionHandler The function that will be called with the result of the query
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    internal func queryRecords<T:EVCloudKitDataObject>(type:T, query: CKQuery, completionHandler: (results: [T]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        // Not sortable anymore!?
        if !(query.sortDescriptors != nil) {
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        var operation = CKQueryOperation(query: query)
        var results = [T]()
        operation.recordFetchedBlock = { record in
            results.append(self.fromCKRecord(record) as T)
        }
        operation.queryCompletionBlock = { cursor, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: { completionHandler(results: results) })
        }
        operation.resultsLimit = CKQueryOperationMaximumResults;
        database.addOperation(operation)
    }
    
    /**
    Helper method for getting a reference (with delete action)
    
    :param: recordId The record id that will be converted to a CKReference
    :return: The CKReference that is created from the recordId
    */
    public func referenceForId(recordId:String) -> CKReference {
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
    public func createRecordTypes(types: [EVCloudKitDataObject]) {
        for item in types {
            var sema = dispatch_semaphore_create(0);
            saveItem(item, completionHandler: {record in
                    EVLog("saveItem \(item): \(record.recordID.recordName)");
                    dispatch_semaphore_signal(sema);
                }, errorHandler: {error in
                    EVLog("ERROR: saveItem\n\(error.description)");
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
    public func requestDiscoverabilityPermission(completionHandler: (granted: Bool) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
    container.requestApplicationPermission(CKApplicationPermissions.PermissionUserDiscoverability, completionHandler: { applicationPermissionStatus, error in
        self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
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
    public func discoverUserInfo(completionHandler: (user: CKDiscoveredUserInfo) -> Void, errorHandler:((error:NSError) -> Void)? = nil) {
        container.fetchUserRecordIDWithCompletionHandler({recordID, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                self.container.discoverUserInfoWithUserRecordID(recordID, { user, error in
                    self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
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
    public func getUserInfo(completionHandler: (user: CKDiscoveredUserInfo) -> Void, errorHandler:((error:NSError) -> Void)? = nil) {
        self.requestDiscoverabilityPermission({ discoverable in
            if discoverable {
                self.discoverUserInfo({user in
                        self.activeUser = user
                        completionHandler(user: user)
                    }, errorHandler: { error in
                        if let handler = errorHandler {
                            handler(error: error)
                        }
                    })
            } else
            {
                EVLog("requestDiscoverabilityPermission : No permissions")
                var error = NSError(domain: "EVCloudKitDao", code: 1, userInfo:nil)
                if let handler = errorHandler {
                    handler(error: error)
                }
            }
        }, errorHandler: errorHandler)
    }
    
    /**
    Who or our contacts is using the same app (will get a system popup requesting permitions)
    
    :param: completionHandler The function that will be called with an array of CKDiscoveredUserInfo objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func allContactsUserInfo(completionHandler: (users: [CKDiscoveredUserInfo]!) -> Void, errorHandler:((error:NSError) -> Void)? = nil) {
        container.discoverAllContactUserInfosWithCompletionHandler({users, error in
            self.handleCallback(error, errorHandler:errorHandler, completionHandler: {
                var returnData = users as [CKDiscoveredUserInfo]
                if returnData.count == 0 {
                    if let restoreData = EVCloudData.publicDB.restoreData("allContactsUserInfo.bak") as? [CKDiscoveredUserInfo] {
                        returnData = restoreData
                    }
                } else {
                    EVCloudData.publicDB.backupData(returnData, toFile: "allContactsUserInfo.bak")
                }
                completionHandler(users:returnData)
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
    public func getItem(recordId: String, completionHandler: (result: EVCloudKitDataObject) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        database.fetchRecordWithID(CKRecordID(recordName: recordId), completionHandler: {record, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
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
    public func saveItem(item: EVCloudKitDataObject, completionHandler: (record: CKRecord) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        var theRecord = self.toCKRecord(item)
        database.saveRecord(theRecord, completionHandler: { record, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
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
    public func deleteItem(recordId: String, completionHandler: (recordID: CKRecordID) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        database.deleteRecordWithID(CKRecordID(recordName: recordId), completionHandler: {recordID, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
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
    :param: completionHandler The function that will be called with an array of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, completionHandler: (results: [T]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /**
    Query child object of a recordType
    
    :param: type An instance of the Object for what we want to query the record type
    :param: referenceRecordName The CloudKit record id that we are looking for
    :param: referenceField The name of the field that we will query for the referenceRecordName
    :param: completionHandler The function that will be called with an array of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, referenceRecordName:String, referenceField:String ,completionHandler: (results: [T]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
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
    :param: completionHandler The function that will be called with an array of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, predicate: NSPredicate, completionHandler: (results: [T]) -> Void, errorHandler:((error: NSError) -> Void)? = nil){
        var recordType = EVReflection.swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: predicate)
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /**
    Query a recordType for some tokens
    
    :param: type An instance of the Object for what we want to query the record type
    :param: tokens The tokens that we will query for (words seperated by a space)
    :param: completionHandler The function that will be called with an array of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, tokens:String ,completionHandler: (results: [T]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "allTokens TOKENMATCHES[cdl] %@", tokens))
        queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    
    /**
    Query a recordType for a location and sort on distance
    
    :param: type An instance of the Object for what we want to query the record type
    :param: fieldname The field that contains the location data
    :param: latitude The latitude that will be used to query
    :param: longitude The longitude that will be used to query
    :param: distance The maximum distance to the location that will be returned
    :param: completionHandler The function that will be called with an array of the requested objects
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, fieldname:String, latitude:Double, longitude:Double, distance:Int ,completionHandler: (results: [T]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        var recordType:String = EVReflection.swiftStringFromClass(type)
        var location:CLLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        var predecate: NSPredicate =  NSPredicate(format: "distanceToLocation:fromLocation:(%K, %@) < %@", fieldname, location, distance)!
        var query = CKQuery(recordType:recordType, predicate:predecate)
        query.sortDescriptors = [CKLocationSortDescriptor(key: fieldname, relativeLocation: location)]
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
    public func subscribe(type:EVCloudKitDataObject, predicate:NSPredicate, filterId:String, configureNotificationInfo:((notificationInfo:CKNotificationInfo ) -> Void)? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var defaults = NSUserDefaults.standardUserDefaults()
        var key = "subscriptionFor_\(recordType)_\(filterId)"
        if defaults.boolForKey(key) {
            unsubscribe(type, filterId: filterId, errorHandler: errorHandler)
        }
        
        var subscription = CKSubscription(recordType: recordType, predicate: predicate, options: .FiresOnRecordCreation | .FiresOnRecordUpdate | .FiresOnRecordDeletion)
        subscription.notificationInfo = CKNotificationInfo()
        subscription.notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo.soundName = UILocalNotificationDefaultSoundName
        if let configure = configureNotificationInfo {
            configure(notificationInfo: subscription.notificationInfo)
        }
        database.saveSubscription(subscription, completionHandler: { savedSubscription, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                EVLog("Subscription created for key \(key)")
                defaults.setBool(true, forKey: key)
                defaults.setObject(subscription.subscriptionID, forKey: key)
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
    public func unsubscribe(type:EVCloudKitDataObject, filterId:String, errorHandler:((error: NSError) -> Void)? = nil) {
        var recordType = EVReflection.swiftStringFromClass(type)
        var defaults = NSUserDefaults.standardUserDefaults()
        var key = "subscriptionFor_\(recordType)_\(filterId)"
        if !defaults.boolForKey(key) { return }
        
        var modifyOperation = CKModifySubscriptionsOperation()
        var subscriptionID : String? = defaults.objectForKey(key) as? String
        if (subscriptionID != nil) {
            modifyOperation.subscriptionIDsToDelete = [subscriptionID!]
            modifyOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptions, error in
                self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                    defaults.removeObjectForKey(key)
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
    public func subscribe(type:EVCloudKitDataObject, referenceRecordName:String, referenceField:String, configureNotificationInfo:((notificationInfo:CKNotificationInfo) -> Void)? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
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
    public func unsubscribe(type:EVCloudKitDataObject, referenceRecordName:String, referenceField:String, errorHandler:((error: NSError) -> Void)? = nil) {
        unsubscribe(type, filterId:"reference_\(referenceField)_\(referenceRecordName)", errorHandler: errorHandler)
    }

    /**
    Subscribe for modifications to a recordType
    
    :param: type An instance of the Object for what we want to subscribe for
    :param: configureNotificationInfo The function that will be called with the CKNotificationInfo object so that we can configure it
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func subscribe(type:EVCloudKitDataObject, configureNotificationInfo:((notificationInfo:CKNotificationInfo) -> Void)? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        subscribe(type, predicate:NSPredicate(value: true), filterId: "all", configureNotificationInfo: configureNotificationInfo ,errorHandler: errorHandler)
    }

    /**
    Unsubscribe for modifications to a recordType
    
    :param: type An instance of the Object for what we want to query the record type
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func unsubscribe(type:EVCloudKitDataObject, errorHandler:((error: NSError) -> Void)? = nil) {
        unsubscribe(type, filterId:"all", errorHandler:errorHandler)
    }

    /**
    Unsubscribe for all modifications
    
    :param: errorHandler The function that will be called when there was an error
    :param: completionHandler The function that will be called with a number which is the count of messages removed.
    :return: No return value
    */
    public func unsubscribeAll(completionHandler:(subscriptionCount: Int) -> Void , errorHandler:((error: NSError) -> Void)? = nil) {
        
        for (key, value) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
            if key.description.hasPrefix("subscriptionFor_") {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(key as String)
            }
        }
        
        database.fetchAllSubscriptionsWithCompletionHandler({subscriptions, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                for subscriptionObject in subscriptions {
                    var subscription: CKSubscription = subscriptionObject as CKSubscription
                    self.database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {subscriptionId, error in
                        self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                            EVLog("Subscription with id \(subscriptionId) was removed : \(subscription.description)")
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
    public func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject]!, executeIfNonQuery:() -> Void, inserted:(recordID:String, item: EVCloudKitDataObject) -> Void, updated:(recordID:String, item: EVCloudKitDataObject) -> Void, deleted:(recordId: String) -> Void) {
        var cloudNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        //EVLog("Notification alert body : \(cloudNotification.alertBody)")
        
        // Handle CloudKit subscription notifications
        var recordID:CKRecordID?
        if cloudNotification.notificationType == CKNotificationType.Query {
            var queryNotification: CKQueryNotification = cloudNotification as CKQueryNotification
            recordID = queryNotification.recordID
            EVLog("recordID of notified record = \(recordID)")
            if(queryNotification.queryNotificationReason == .RecordDeleted) {
                deleted(recordId: recordID!.recordName)
            } else {
                EVCloudKitDao.publicDB.getItem(recordID!.recordName, completionHandler: { item in
                    EVLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                    EVReflection.logObject(item)
                    if (queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordCreated ) {
                        inserted(recordID: recordID!.recordName, item: item)
                    } else if(queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordUpdated){
                        updated(recordID: recordID!.recordName, item: item)
                    }
                    }, errorHandler: { error in
                        EVLog("ERROR: getItem for notification.\n\(error.description)")
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
    public func fetchChangeNotifications(skipRecordID:CKRecordID?, inserted:(recordID:String, item: EVCloudKitDataObject) -> Void, updated:(recordID:String, item: EVCloudKitDataObject) -> Void, deleted:(recordId: String) -> Void) {
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
                        EVCloudKitDao.publicDB.getItem(queryNotification.recordID.recordName, completionHandler: { item in
                            EVLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                            EVReflection.logObject(item)
                            if (queryNotification.queryNotificationReason == .RecordCreated) {
                                inserted(recordID: queryNotification.recordID.recordName, item: item)
                            } else if (queryNotification.queryNotificationReason == .RecordUpdated) {
                                updated(recordID: queryNotification.recordID.recordName, item: item)
                            }
                            }, errorHandler: { error in
                                EVLog("ERROR: getItem for change notification.\n\(error.description)")
                            })
                    }
                }
            }
        }
        operation.fetchNotificationChangesCompletionBlock = { changetoken, error in
            var op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: array)
            op.start()
            EVLog("changetoken = \(changetoken)")
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
    
    
    public func setBadgeCounter(count:Int) {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: count)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in            
            func handleError(error: NSError) -> Void {
                EVLog("Error: could not reset badge: \n\(error)")
            }
            self.handleCallback(error, errorHandler: handleError, completionHandler: {
                    UIApplication.sharedApplication().applicationIconBadgeNumber = count
                })
        }
        CKContainer.defaultContainer().addOperation(badgeResetOperation)
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Converting a CKRecord from and to an object
    // ------------------------------------------------------------------------
    
    /**
    Convert a CKrecord to an object
    
    :param: record The CKRecord that will be converted to an object
    :return: The object that is created from the record
    */
    public func fromCKRecord(record: CKRecord) -> EVCloudKitDataObject {
        var theObject = EVReflection.fromDictionary(CKRecordToDictionary(record), anyobjectTypeString: record.recordType) as EVCloudKitDataObject
        theObject.recordID = record.recordID
        theObject.recordType = record.recordType
        theObject.creationDate = record.creationDate
        theObject.creatorUserRecordID = record.creatorUserRecordID
        theObject.modificationDate = record.modificationDate
        theObject.lastModifiedUserRecordID = record.lastModifiedUserRecordID
        theObject.recordChangeTag = record.recordChangeTag
        return theObject
    }
    
    /**
    Convert an object to a CKRecord
    
    :param: theObject The object that will be converted to a CKRecord
    :return: The CKRecord that is created from theObject
    */
    public func toCKRecord(theObject: EVCloudKitDataObject) -> CKRecord {
        var record = CKRecord(recordType: EVReflection.swiftStringFromClass(theObject), recordID: theObject.recordID)
        var fromDict = EVReflection.toDictionary(theObject)
        for (key: String, value: AnyObject) in fromDict {
            if !contains(["recordType", "creationDate", "creatorUserRecordID", "modificationDate", "lastModifiedUserRecordID", "recordChangeTag"] ,key) {
                if let t = value as? NSNull {
//                    record.setValue(nil, forKey: key) // Swift can not set a value on a nulable type.
                } else if key != "recordID" {
                    record.setValue(value, forKey: key)
                }
            }
        }
        return record
    }
    
    /**
    Convert CKRecord to dictionary
    
    :param: record The CKRecord that will be converted to a dictionary
    :return: The dictionary that is created from the record
    */
    public func CKRecordToDictionary(record:CKRecord) -> Dictionary<String, AnyObject?> {
        var dictionary = Dictionary<String, AnyObject>()
        for field in record.allKeys() {
            dictionary[field as NSString] = record.objectForKey(field as NSString)
        }
        return dictionary
    }
}



