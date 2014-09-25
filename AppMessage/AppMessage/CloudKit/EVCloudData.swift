//
//  EVCloudData.swift
//
//  Created by Edwin Vermeer on 09-08-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation
import CloudKit


class EVCloudData {
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    // Singleton
    class var instance : EVCloudData {
    struct Static { static let instance : EVCloudData = EVCloudData() }
        return Static.instance
    }
    
    class func sharedInstance() -> EVCloudData {
        return instance;
    }
    
    var dao = EVCloudKitDao.instance;
    var data = Dictionary<String, Dictionary<String, NSObject>>()
    var predicates = Dictionary<String, NSPredicate>()
    var insertedHandlers = Dictionary<String, (item: NSObject) -> Void>()
    var updateHandlers = Dictionary<String, (item: NSObject) -> Void>()
    var deletedHandlers = Dictionary<String, (recordId: String) -> Void>()

    // ------------------------------------------------------------------------
    // MARK: - Modify local data
    // ------------------------------------------------------------------------
    
    // Add the inserted object to every data collection where it confirms to it's predicate
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
    
    // Delete an object from every data collection where it's part of
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
    
    // Get an Item for a recordId
    func getItem(recordId: String, completionHandler: (result: NSObject) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.getItem(recordId, completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    // Save an item and update the connected collections and call the insertedHandlers events for those
    func saveItem(item: NSObject, completionHandler: (record: CKRecord) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.saveItem(item, completionHandler: { record in
            var item : NSObject = self.dao.fromCKRecord(record)
            self.upsertObject(record.recordID.recordName, item: item)
            completionHandler(record: record)
            }, errorHandler: errorHandler)
    }
    
    // Delete an Item for a recordId and update the connected collections and call the deletedHandlers events for those
    func deleteItem(recordId: String, completionHandler: (recordId: CKRecordID) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.deleteItem(recordId, completionHandler: { recordId in
            self.deleteObject(recordId.recordName)
            completionHandler(recordId: recordId)
            }, errorHandler: errorHandler)
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Query and subscribe
    // To see how to create a predicate, see: https://developer.apple.com/library/prerelease/ios/documentation/CloudKit/Reference/CKQuery_class/index.html
    // ------------------------------------------------------------------------

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
            var recordType = dao.swiftStringFromClass(type)
            var query = CKQuery(recordType: recordType, predicate: predicate)
            dao.queryRecords(type, query: query, completionHandler: { results in
                self.data[filterId] = results
                completionHandler(results: results)
                }, errorHandler: errorHandler)
    }

    
    // ------------------------------------------------------------------------
    // MARK: - Handling remote notifications
    // ------------------------------------------------------------------------
    
    // call this from the AppDelegate didReceiveRemoteNotification
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
    
    // Call this in the AppDelegate didFinishLaunchingWithOptions to handle not yet handled notifications.
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