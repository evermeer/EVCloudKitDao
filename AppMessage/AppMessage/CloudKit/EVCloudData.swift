//
//  EVCloudData.swift
//
//  Created by Edwin Vermeer on 09-08-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation
import CloudKit


/**
    Class for access to  Apple's CloudKit data the easiest way possible
*/
public class EVCloudData {
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    /**
    Singleton access to EVCloudData that can be called from Swift
    
    :return: The EVCloudData object
    */
    public class var publicDB : EVCloudData {
        struct Static { static let instance : EVCloudData = EVCloudData() }
        return Static.instance
    }
    
    /**
    Singleton access to EVCloudData that can be called from Objective C
    
    :return: The EVCloudData object
    */
    public class func sharedPublicDB() -> EVCloudData {
        return publicDB;
    }

    /**
    Singleton access to EVCloudData that can be called from Swift
    
    :return: The EVCloudData object
    */
    public class var privateDB : EVCloudData {
        struct Static { static let instance : EVCloudData = EVCloudData() }
        Static.instance.dao = EVCloudKitDao.privateDB
        return Static.instance
    }
    
    /**
    Singleton access to EVCloudData that can be called from Objective C
    
    :return: The EVCloudData object
    */
    public class func sharedPrivateDB() -> EVCloudData {
        return privateDB;
    }
    

    // ------------------------------------------------------------------------
    // MARK: - Store to local file cache
    // ------------------------------------------------------------------------

    var filePath =  (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString).stringByAppendingPathComponent("CloudKitDataBackup.bak")

    init() {
        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(filePath) {
            data = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as Dictionary<String, [EVCloudKitDataObject]>
            NSLog("data = \(data)")
        }
    }
    
    public func backupData() {
        NSKeyedArchiver.archiveRootObject(data, toFile: filePath)
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - class variables
    // ------------------------------------------------------------------------

    /**
    The EVCloudKitDao instance that will be used
    */
    public var dao = EVCloudKitDao.publicDB;
    /**
    Save the recordType of the connection.
    */
    public var recordType = Dictionary<String, String>()
    /**
    All the data in a dictionary. Each filterId is a dictionary entry that contains another dictionary with the objects in that filter
    */
    public var data = Dictionary<String, [EVCloudKitDataObject]>()

    /**
    A dictionary of predicates. Each filterId is a dictionary entry containing a predicate
    */
    public var predicates = Dictionary<String, NSPredicate>()
    /**
    A dictionary of insert event handlers. Each filterId is a dictionary entry containing a insert event handler
    */
    public var insertedHandlers = Dictionary<String, (item: EVCloudKitDataObject) -> Void>()
    /**
    A dictionary of update event handlers. Each filterId is a dictionary entry containing a update event handler
    */
    public var updateHandlers = Dictionary<String, (item: EVCloudKitDataObject, dataIndex:Int) -> Void>()
    /**
    A dictionary of delete event handlers. Each filterId is a dictionary entry containing a delete event handler
    */
    public var deletedHandlers = Dictionary<String, (recordId: String, dataIndex:Int) -> Void>()

    // ------------------------------------------------------------------------
    // MARK: - Modify local data
    // ------------------------------------------------------------------------
    
    /**
    Add the inserted or updated object to every data collection where it confirms to it's predicate
    
    :param: recordId The recordId of the object that will be processed
    :param: item The object that will be processed
    :return: No return value
    */
    private func upsertObject(recordId:String, item :EVCloudKitDataObject) {
        NSLog("upsert \(recordId) \(EVReflection.swiftStringFromClass(item))")
        for (filter, predicate) in self.predicates {
            if recordType[filter] == EVReflection.swiftStringFromClass(item) {
                var itemID:Int? = data[filter]!.EVindexOf {item in return item.recordID!.recordName == recordId}
                if predicate.evaluateWithObject(item) {
                    var d:[EVCloudKitDataObject] = data[filter]!
                    var s:EVCloudKitDataObject?
                    if itemID != nil && itemID < d.count {
                        s = d[itemID!]
                    }
                    if s != nil  {
                        data[filter]!.removeAtIndex(itemID!)
                        data[filter]!.insert(item, atIndex: itemID!)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            (self.updateHandlers[filter]!)(item: item, dataIndex:itemID!)
                        }
                    } else {
                        data[filter]!.insert(item, atIndex: 0)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            (self.insertedHandlers[filter]!)(item: item)
                        }
                    }
                } else { // An update of a field that is used int the predicate could trigger a delete from that set.
                    NSLog("Object not for filter \(filter)")
                    if (itemID != nil) {
                        data[filter]!.removeAtIndex(itemID!)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            (self.deletedHandlers[filter]!)(recordId: recordId, dataIndex:itemID!)
                        }
                    }
                }
            }
        }
    }
    
    /**
    Delete an object from every data collection where it's part of
    
    :param: recordId The recordId of the object that will be deleted
    :return: No return value
    */
    private func deleteObject(recordId :String) {
        for (filter, table) in self.data {
            var itemID:Int? = data[filter]!.EVindexOf {item in return item.recordID == recordId}
            if (itemID != nil) {
                data[filter]!.removeAtIndex(itemID!)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    (self.deletedHandlers[filter]!)(recordId: recordId, dataIndex:itemID!)
                }
            }
        }
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
    public func getItem(recordId: String, completionHandler: (result: EVCloudKitDataObject) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.getItem(recordId, completionHandler: { result in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completionHandler(result: result)
            }
        }, errorHandler: {error in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                errorHandler(error: error)
            }
        })
    }
    
    /**
    Save an item and update the connected collections and call the insertedHandlers events for those
    
    :param: item object that we want to save
    :param: completionHandler The function that will be called with a CKRecord representation of the saved object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func saveItem(item: EVCloudKitDataObject, completionHandler: (item: EVCloudKitDataObject) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.saveItem(item, completionHandler: { record in
            var item : EVCloudKitDataObject = self.dao.fromCKRecord(record)
            self.upsertObject(record.recordID.recordName, item: item)
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completionHandler(item: self.dao.fromCKRecord(record))
            }
        }, errorHandler: {error in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                errorHandler(error: error)
            }
        })
    }
    
    /**
    Delete an Item for a recordId and update the connected collections and call the deletedHandlers events for those
    
    :param: recordId The CloudKit record id of the record that we want to delete
    :param: completionHandler The function that will be called with a record id of the deleted object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    public func deleteItem(recordId: String, completionHandler: (recordId: CKRecordID) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.deleteItem(recordId, completionHandler: { recordId in
            self.deleteObject(recordId.recordName)
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completionHandler(recordId: recordId)
            }
        }, errorHandler: {error in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                errorHandler(error: error)
            }
        })
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Query and subscribe
    // ------------------------------------------------------------------------

    /**
    Create a data connection between your app and CloudKit. Execute a query, create a subscription, process notifications, maintain an in memory dictionary of objects and execute apropriate events. The connection will be based on a predicate.
    
    :param: type The CloudKit record id of the record that we want to delete
    :param: predicate The filter that will be used. To see how to create a predicate, see: https://developer.apple.com/library/prerelease/ios/documentation/CloudKit/Reference/CKQuery_class/index.html
    :param: filterId The filterId under what this filter should be registered (must be unique per predicate
    :param: configureNotificationInfo The function that will be called with the CKNotificationInfo object so that we can configure it
    :param: completionHandler The function that will be called with a record id of the deleted object
    :param: insertedHandler Executed if the notification was for an inserted object
    :param: updatedHandler Executed if the notification was for an updated object pasing on the data object plus the index in the data array
    :param: deletedHandler Executed if the notification was for an deleted object passing on the recordId plus the index it had in the data array
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */

    public func connect<T:EVCloudKitDataObject>(type:T,
        predicate: NSPredicate,
        filterId: String,
        configureNotificationInfo:(notificationInfo:CKNotificationInfo ) -> Void,
        completionHandler: (results: [T]) -> Void,
        insertedHandler:(item: EVCloudKitDataObject) -> Void,
        updatedHandler:(item: EVCloudKitDataObject, dataIndex:Int) -> Void,
        deletedHandler:(recordId: String, dataIndex:Int) -> Void,
        errorHandler:(error: NSError) -> Void
        ) -> Void {
            if !data.has(filterId) {
                self.data[filterId] = [T]()
            }
            self.recordType[filterId] = EVReflection.swiftStringFromClass(type)
            self.insertedHandlers[filterId] = insertedHandler
            self.updateHandlers[filterId] = updatedHandler
            self.deletedHandlers[filterId] = deletedHandler
            self.predicates[filterId] = predicate
            dao.subscribe(type, predicate:predicate, filterId: filterId, configureNotificationInfo:configureNotificationInfo ,errorHandler: errorHandler)
            var recordType = EVReflection.swiftStringFromClass(type)
            var query = CKQuery(recordType: recordType, predicate: predicate)
            dao.queryRecords(type, query: query, completionHandler: { results in
                self.data[filterId] = results
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completionHandler(results: results)
                }
            }, errorHandler: {error in
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    errorHandler(error: error)
                }
            })
    }

    /**
    Disconnect an existing connection. When a connect is made, then at least in the deinit you must do a disconnect for that same filterId.
    
    :param: filterId The filterId
    */
    public func disconnect(filterId: String) {
        insertedHandlers.removeValueForKey(filterId)
        updateHandlers.removeValueForKey(filterId)
        deletedHandlers.removeValueForKey(filterId)
        predicates.removeValueForKey(filterId)
        data.removeValueForKey(filterId)
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Handling remote notifications
    // ------------------------------------------------------------------------
    
    /**
    Call this from the AppDelegate didReceiveRemoteNotification for processing the notifications
    
    :param: userInfo CKNotification dictionary
    :param: executeIfNonQuery Will be called if the notification is not for a CloudKit subscription
    :return: No return value
    */
    public func didReceiveRemoteNotification(userInfo: [NSObject : NSObject]!, executeIfNonQuery:() -> Void) {
        dao.didReceiveRemoteNotification(userInfo, executeIfNonQuery: executeIfNonQuery, inserted: {recordId, item in
                self.upsertObject(recordId, item: item)
            }, updated: {recordId, item in
                self.upsertObject(recordId, item: item)
            }, deleted: {recordId in
                self.deleteObject(recordId)
            })
    }
    
    /**
    Call this in the AppDelegate didFinishLaunchingWithOptions to handle not yet handled notifications.
    
    :return: No return value
    */
    public func fetchChangeNotifications() {
        dao.fetchChangeNotifications(nil, {recordId, item in
                self.upsertObject(recordId, item: item)
            }, updated : {recordId, item in
                self.upsertObject(recordId, item: item)
            }, deleted : {recordId in
                self.deleteObject(recordId)
            })
    }
}

/**
These Array extensions are a copy from the ExSwift library. They ar copied here to limit dependencies.
*/
extension Array {
    /**
    Index of the first item that meets the condition.
    
    :param: condition A function which returns a boolean if an element satisfies a given condition or not.
    :returns: Index of the first matched item or nil
    */
    func EVindexOf (condition: Element -> Bool) -> Int? {
        for (index, element) in enumerate(self) {
            if condition(element) {
                return index
            }
        }
        
        return nil
    }
    
    
    /**
    Gets the object at the specified index, if it exists.
    
    :param: index
    :returns: Object at index in self
    */
    func EVget (index: Int) -> Element? {
        
        //  If the index is out of bounds it's assumed relative
        func relativeIndex (index: Int) -> Int {
            var _index = (index % count)
            
            if _index < 0 {
                _index = count + _index
            }
            
            return _index
        }
        
        let _index = relativeIndex(index)
        return _index < count ? self[_index] : nil
    }
}