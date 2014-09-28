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
class EVCloudData {
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    /**
    Singleton access to EVCloudData that can be called from Swift
    
    :return: The EVCloudData object
    */
    class var instance : EVCloudData {
        struct Static { static let instance : EVCloudData = EVCloudData() }
        return Static.instance
    }
    
    /**
    Singleton access to EVCloudData that can be called from Objective C
    
    :return: The EVCloudData object
    */
    class func sharedInstance() -> EVCloudData {
        return instance;
    }

    // ------------------------------------------------------------------------
    // MARK: - class variables
    // ------------------------------------------------------------------------

    /**
    The EVCloudKitDao instance that will be used
    */
    var dao = EVCloudKitDao.instance;
    /**
    All the data in a dictionary. Each filterId is a dictionary entry that contains another dictionary with the objects in that filter
    */
    var data = Dictionary<String, Dictionary<String, NSObject>>()
    /**
    A dictionary of predicates. Each filterId is a dictionary entry containing a predicate
    */
    var predicates = Dictionary<String, NSPredicate>()
    /**
    A dictionary of insert event handlers. Each filterId is a dictionary entry containing a insert event handler
    */
    var insertedHandlers = Dictionary<String, (item: NSObject) -> Void>()
    /**
    A dictionary of update event handlers. Each filterId is a dictionary entry containing a update event handler
    */
    var updateHandlers = Dictionary<String, (item: NSObject) -> Void>()
    /**
    A dictionary of delete event handlers. Each filterId is a dictionary entry containing a delete event handler
    */
    var deletedHandlers = Dictionary<String, (recordId: String) -> Void>()

    // ------------------------------------------------------------------------
    // MARK: - Modify local data
    // ------------------------------------------------------------------------
    
    /**
    Add the inserted or updated object to every data collection where it confirms to it's predicate
    
    :param: recordId The recordId of the object that will be processed
    :param: item The object that will be processed
    :return: No return value
    */
    private func upsertObject(recordId:String, item :NSObject) {
        var test = [item]
        for (filter, predicate) in predicates {
            if predicate.evaluateWithObject(item) {
                var table : Dictionary<String, NSObject> = data[filter]!
                if table[recordId] != nil  {
                    table[recordId] = item
                    (updateHandlers[filter]!)(item: item)
                } else {
                    table[recordId] = item
                    (insertedHandlers[filter]!)(item: item)
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
        for (filter, table) in data {
            if (table[recordId] != nil) {
                var table2 = table // hack to make it mutable?
                table2.removeValueForKey(recordId)
                (deletedHandlers[filter]!)(recordId: recordId)
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
    func getItem(recordId: String, completionHandler: (result: NSObject) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.getItem(recordId, completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    /**
    Save an item and update the connected collections and call the insertedHandlers events for those
    
    :param: item object that we want to save
    :param: completionHandler The function that will be called with a CKRecord representation of the saved object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func saveItem(item: NSObject, completionHandler: (record: CKRecord) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.saveItem(item, completionHandler: { record in
            var item : NSObject = self.dao.fromCKRecord(record)
            self.upsertObject(record.recordID.recordName, item: item)
            completionHandler(record: record)
            }, errorHandler: errorHandler)
    }
    
    /**
    Delete an Item for a recordId and update the connected collections and call the deletedHandlers events for those
    
    :param: recordId The CloudKit record id of the record that we want to delete
    :param: completionHandler The function that will be called with a record id of the deleted object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */
    func deleteItem(recordId: String, completionHandler: (recordId: CKRecordID) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.deleteItem(recordId, completionHandler: { recordId in
            self.deleteObject(recordId.recordName)
            completionHandler(recordId: recordId)
            }, errorHandler: errorHandler)
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
    :param: updatedHandler Executed if the notification was for an updated object
    :param: deletedHandler Executed if the notification was for an deleted object
    :param: errorHandler The function that will be called when there was an error
    :return: No return value
    */

    func connect<T:NSObject>(type:T,
        predicate: NSPredicate,
        filterId: String,
        configureNotificationInfo:(notificationInfo:CKNotificationInfo ) -> Void,
        completionHandler: (results: Dictionary<String, T>) -> Void,
        insertedHandler:(item: NSObject) -> Void,
        updatedHandler:(item: NSObject) -> Void,
        deletedHandler:(recordId: String) -> Void,
        errorHandler:(error: NSError) -> Void
        ) -> Void {
            self.data[filterId] = nil
            self.insertedHandlers[filterId] = insertedHandler
            self.updateHandlers[filterId] = updatedHandler
            self.deletedHandlers[filterId] = deletedHandler
            self.predicates[filterId] = predicate
            dao.subscribe(type, predicate:predicate, filterId: filterId, configureNotificationInfo:configureNotificationInfo ,errorHandler: errorHandler)
            var recordType = EVReflection.swiftStringFromClass(type)
            var query = CKQuery(recordType: recordType, predicate: predicate)
            dao.queryRecords(type, query: query, completionHandler: { results in
                self.data[filterId] = results
                completionHandler(results: results)
                }, errorHandler: errorHandler)
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
    func didReceiveRemoteNotification(userInfo: [NSObject : NSObject]!, executeIfNonQuery:() -> Void) {
        var dao: EVCloudKitDao = EVCloudKitDao.instance
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
    func fetchChangeNotifications() {
        var dao: EVCloudKitDao = EVCloudKitDao.instance
        dao.fetchChangeNotifications({recordId, item in
                self.upsertObject(recordId, item: item)
            }, updated : {recordId, item in
                self.upsertObject(recordId, item: item)
            }, deleted : {recordId in
                self.deleteObject(recordId)
            })
    }
    
}