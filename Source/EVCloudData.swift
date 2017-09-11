//
//  EVCloudData.swift
//
//  Created by Edwin Vermeer on 09-08-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation
import CloudKit
import EVReflection
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@available(*, deprecated, message: "Use CKDataObject instead")
open class EVCloudKitDataObject: CKDataObject {
}


/**
 Wrapper class for being able to use a class instance Dictionary.
 This is used for singleton access to named containers.
 */
private class DataContainerWrapper {
    var publicContainers : Dictionary<String,EVCloudData> = Dictionary<String,EVCloudData>()
    var privateContainers : Dictionary<String,EVCloudData> = Dictionary<String,EVCloudData>()
}

/**
 Class for access to  Apple's CloudKit data the easiest way possible
 */
open class EVCloudData: EVObject {
    
    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------
    
    /**
    Singleton access to EVCloudData that can be called from Swift
    
    :return: The EVCloudData object
    */
    open class var publicDB: EVCloudData {
        struct Static { static let instance: EVCloudData = EVCloudData() }
        return Static.instance
    }
    
    /**
     Singleton access to EVCloudData that can be called from Objective C
     
     :return: The EVCloudData object
     */
    open class func sharedPublicDB() -> EVCloudData {
        return publicDB;
    }
    
    /**
     Singleton access to EVCloudData that can be called from Swift
     
     :return: The EVCloudData object
     */
    open class var privateDB: EVCloudData {
        struct Static { static let instance: EVCloudData = EVCloudData() }
        Static.instance.dao = EVCloudKitDao.privateDB
        return Static.instance
    }
    
    /**
     Singleton access to EVCloudData that can be called from Objective C
     
     :return: The EVCloudData object
     */
    open class func sharedPrivateDB() -> EVCloudData {
        return privateDB;
    }
    
    /**
     Singleton acces to the wrapper class with the dictionaries with public and private containers.
     
     :return: The container wrapper class
     */
    fileprivate class var containerWrapperInstance: DataContainerWrapper {
        struct Static { static var instance: DataContainerWrapper = DataContainerWrapper()}
        return Static.instance
    }
    
    /**
     Singleton acces to a specific named public container
     - parameter containterIdentifier: The identifier of the public container that you want to use.
     
     :return: The public container for the identifier.
     */
    open class func publicDBForContainer(_ containerIdentifier: String) -> EVCloudData {
        if let containerInstance = containerWrapperInstance.publicContainers[containerIdentifier] {
            return containerInstance
        }
        let cloudData = EVCloudData()
        cloudData.dao = EVCloudKitDao.publicDBForContainer(containerIdentifier)
        containerWrapperInstance.publicContainers[containerIdentifier] =  cloudData
        return cloudData
    }
    
    /**
     Singleton acces to a specific named private container
     - parameter containterIdentifier: The identifier of the private container that you want to use.
     
     :return: The private container for the identifier.
     */
    open class func privateDBForContainer(_ containerIdentifier: String) -> EVCloudData {
        if let containerInstance = containerWrapperInstance.privateContainers[containerIdentifier] {
            return containerInstance
        }
        let cloudData = EVCloudData()
        cloudData.dao = EVCloudKitDao.privateDBForContainer(containerIdentifier)
        containerWrapperInstance.privateContainers[containerIdentifier] =  cloudData
        return cloudData
    }
    
    /**
     Overriding the default innit so that we can startup a timer when this is initialized. The timer is used for delayed cashing. For more info see the casching strategies.
     */
    required public init() {        
        super.init()
        Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(EVCloudData.backupAllData), userInfo: nil, repeats: true)
    }
    
    // ------------------------------------------------------------------------
    // MARK: - class variables
    // ------------------------------------------------------------------------
    
    /**
    The EVCloudKitDao instance that will be used. Defaults to the publicDB
    */
    open var dao = EVCloudKitDao.publicDB;
    /**
     Save the recordType of the connection.
     */
    open var recordType = Dictionary<String, String>()
    /**
     All the data in a dictionary. Each filterId is a dictionary entry that contains another dictionary with the objects in that filter
     */
    open var data = Dictionary<String, [CKDataObject]>()
    /**
     The caching strategy for each filter for when incomming data should be written to a file
     */
    open var cachingStrategies = Dictionary <String, CachingStrategy>()
    /**
     The timestamp of the last cach write for each filter
     */
    open var cachingLastWrite = Dictionary <String, Date>()
    /**
     The number of changes since the last cache write for each filter
     */
    open var cachingChangesCount = Dictionary <String, Int>()
    /**
     A dictionary of boolean flags that indicate if state change notifications should be broadcast via NSNotificationManager
     */
    open var postNotifications = Dictionary<String, Bool>()
    /**
     A dictionary of predicates. Each filterId is a dictionary entry containing a predicate
     */
    open var predicates = Dictionary<String, NSPredicate>()
    /**
     A dictionary of sort orders. Each filterId is a dictionary entry containging the sortOrder for that filter.
     */
    open var sortOrders = Dictionary<String, OrderBy>()
    /**
     A dictionary of insert event handlers. Each filterId is a dictionary entry containing a insert event handler
     */
    open var insertedHandlers = Dictionary<String, (_ item: CKDataObject) -> Void>()
    /**
     A dictionary of update event handlers. Each filterId is a dictionary entry containing a update event handler
     */
    open var updateHandlers = Dictionary<String, (_ item: CKDataObject, _ dataIndex: Int) -> Void>()
    /**
     A dictionary of dataChanged event handlers. Each filterId is a dictionary entry containing a dataChanged event handler
     */
    open var dataChangedHandlers = Dictionary<String, () -> Void>()
    /**
     A dictionary of delete event handlers. Each filterId is a dictionary entry containing a delete event handler
     */
    open var deletedHandlers = Dictionary<String, (_ recordId: String, _ dataIndex: Int) -> Void>()
    
    
    // ------------------------------------------------------------------------
    // MARK: - Store data to local file cache
    // ------------------------------------------------------------------------
        
    /**
     Write the data for a specific filter to a file if the corresponding backup strategy has been met.
     
     - parameter filterId: The filter id for the data that needs to be written to a file
     */
    fileprivate func backupDataWithStrategyTest(_ filterId: String) {
        switch cachingStrategies[filterId]! {
        case CachingStrategy.none:
            return
        case CachingStrategy.direct:
            if cachingChangesCount[filterId] > 0 {
                backupDataForFilter(filterId)
            }
        case CachingStrategy.every(let minute):
            if cachingChangesCount[filterId] > 0 {
                if dateDiffInMinutes(cachingLastWrite[filterId]!, toDate: Date()) >= minute {
                    backupDataForFilter(filterId)
                }
            }
        }
    }
    
    /**
     Handle data updates
     
     - parameter filterId: The filter id for the data that was received from CloudKit
     */
    fileprivate func dataIsUpdated(_ filterId: String) {
        cachingChangesCount[filterId] = (cachingChangesCount[filterId] ?? 0) + 1
        backupDataWithStrategyTest(filterId)
    }
    
    /**
     Return the difrence of 2 dates in minutes
     
     - parameter fromDate: The first date for the comparison
     - parameter toDate: The second date for the comparison
     */
    fileprivate func dateDiffInMinutes(_ fromDate: Date, toDate: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.minute, from: fromDate, to: toDate, options: NSCalendar.Options(rawValue: 0)).minute!
    }
    
    /**
     Make sure that all data is backed up while taking into account the selected CachingStrategy. You should call this method right before exiting your app.
     */
    open func backupAllData() {
        for (key, _) in cachingLastWrite {
            backupDataWithStrategyTest(key)
        }
    }
    
    /**
     Restore all previously backed up data for all initialized connections. Be aware that these already should have been restored.
     */
    open func restoreAllData() {
        for (key, _) in cachingLastWrite {
            restoreDataForFilter(key)
        }
    }
    
    /**
     Remove the backup files for all the initialized connections.
     */
    open func removeAllBackups() {
        for (key, _) in cachingLastWrite {
            removeBackupForFilter(key)
        }
    }
    
    /**
     Write the data for a specific filter to a file
     
     - parameter filterId: The filter id for the data that needs to be written to a file
     */
    open func backupDataForFilter(_ filterId: String) {
        if let theData = data[filterId] {
            dao.backupData(theData as AnyObject, toFile: "Filter_\(filterId).bak" )
            self.cachingLastWrite[filterId] = Date()
            self.cachingChangesCount[filterId] = 0
        }
    }
    
    /**
     Restore data for a specific filter from a file
     
     - parameter filterId: The filter id for the data that will be restored from file
     */
    @discardableResult
    open func restoreDataForFilter(_ filterId: String) -> Bool {
        if let theData = dao.restoreData("Filter_\(filterId).bak") as? [CKDataObject] {
            data[filterId] = theData
            return true
        }
        return false
    }
    
    /**
     Remove the backup for a specific filter
     
     - parameter filterId: The filter id for the backup file that will be removed
     */
    open func removeBackupForFilter(_ filterId: String) {
        dao.removeBackup("Filter_\(filterId).bak")
    }
        
    // ------------------------------------------------------------------------
    // MARK: - Internal app notifications via NSNotificationManager
    // ------------------------------------------------------------------------
    
    /**
    Get the NSNotificationCenter key for a given filterId and notification type
    
    - parameter filterId: ?
    - parameter changeType: ?
    
    - returns: ?
    */
    open class func getNotificationCenterId(_ filterId: String, changeType: DataChangeNotificationType? = nil) -> String {
        if changeType == nil {
            return "NL.EVICT.CloudKit.\(filterId).\(DataChangeNotificationType.dataChanged)"
        } else {
            return "NL.EVICT.CloudKit.\(filterId).\(changeType!)"
        }
        
    }
    
     /**
     Convert the raw ConnectStatus value stuffed in an NSNotification userInfo instance back into a ConnectStatus enum value
     
     - parameter notification: ?
     
     - returns: ?
     */
    open class func getCompletionStatusFromNotification(_ notification: Notification) -> CompletionStatus? {
        var result: CompletionStatus?
        
        if (notification as NSNotification).userInfo?["status"] != nil {
            result = CompletionStatus(rawValue: Int(((notification as NSNotification).userInfo?["status"])! as! NSNumber))
        }
        
        return result
    }
    
     /**
     Post a "completed" data notification plus the global "data changed" notification
     
     - parameter filterId: ?
     - parameter results:  ?
     - parameter status:   ?
     */
    fileprivate func postDataCompletedNotification<T:CKDataObject>(_ filterId: String, results: [T], status: CompletionStatus) {
        // Verify notifications are wanted
        if postNotifications[filterId] != nil {
            // Post requested notification
            let notificationId = EVCloudData.getNotificationCenterId(filterId, changeType: DataChangeNotificationType.completed)
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationId), object: self, userInfo: ["filterId": filterId, "results":results, "status": status.rawValue])
            // Post universal "data changed" notification
            postDataChangeNotification(filterId)
        }
    }
    
     /**
     Post an "inserted" data notification plus the global "data changed" notification
     
     - parameter filterId: ?
     - parameter item:     ?
     */
    fileprivate func postDataInsertedNotification<T:CKDataObject>(_ filterId: String, item: T) {
        // Verify notifications are wanted
        if postNotifications[filterId] != nil {
            // Post requested notification
            let notificationId = EVCloudData.getNotificationCenterId(filterId, changeType: DataChangeNotificationType.inserted)
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationId), object: self, userInfo: ["filterId": filterId, "item":item])
            // Post universal "data changed" notification
            postDataChangeNotification(filterId)
        }
    }
    
     /**
     Post an "updated" data notification plus the global "data changed" notification
     
     - parameter filterId:  ?
     - parameter item:      ?
     - parameter dataIndex: ?
     */
    fileprivate func postDataUpdatedNotification<T:CKDataObject>(_ filterId: String, item: T, dataIndex: Int) {
        // Verify notifications are wanted
        if postNotifications[filterId] != nil {
            // Post requested notification
            let notificationId = EVCloudData.getNotificationCenterId(filterId, changeType: DataChangeNotificationType.updated)
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationId), object: self, userInfo: ["filterId": filterId, "item":item, "dataIndex":dataIndex])
            // Post universal "data changed" notification
            postDataChangeNotification(filterId)
        }
    }
    
     /**
     Post a "data changed" data notification
     
     - parameter filterId: ?
     */
    fileprivate func postDataChangeNotification(_ filterId: String) {
        // Verify notifications are wanted
        if postNotifications[filterId] != nil {
            // Post requested notification
            let notificationId = EVCloudData.getNotificationCenterId(filterId, changeType: DataChangeNotificationType.dataChanged)
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationId), object: self, userInfo: ["filterId": filterId])
        }
    }
    
    /**
     Post a "data delete" data notification
     
     - parameter filterId:  ?
     - parameter recordId:  ?
     - parameter dataIndex: ?
     */
    fileprivate func postDataDeletedNotification(_ filterId: String, recordId: String, dataIndex: Int) {
        // Verify notifications are wanted
        if postNotifications[filterId] != nil {
            // Post requested notification
            let notificationId = EVCloudData.getNotificationCenterId(filterId, changeType: DataChangeNotificationType.deleted)
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationId), object: self, userInfo: ["filterId": filterId, "recordId":recordId, "dataIndex":dataIndex])
            // Post universal "data changed" notification
            postDataChangeNotification(filterId)
        }
    }
    
    /**
     Post a "data error" data notification
     
     - parameter filterId: ?
     - parameter error:    ?
     */
    fileprivate func postDataErrorNotification(_ filterId: String, error: Error) {
        // Verify notifications are wanted
        if postNotifications[filterId] != nil {
            // Post requested notification
            let notificationId = EVCloudData.getNotificationCenterId(filterId, changeType: DataChangeNotificationType.error)
            NotificationCenter.default.post(name: Notification.Name(rawValue: notificationId), object: self, userInfo: ["filterId": filterId, "error":error])
            // No universal "data changed" notification on errors
        }
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - Modify local data
    // ------------------------------------------------------------------------
    
    /**
    Add the inserted or updated object to every data collection where it confirms to it's predicate
    
    - parameter recordId: The recordId of the object that will be processed
    - parameter item: The object that will be processed
    :return: No return value
    */
    fileprivate func upsertObject(_ recordId: String, item: CKDataObject) {
        EVLog("upsert \(recordId) \(EVReflection.swiftStringFromClass(item))")
        for (filter, predicate) in self.predicates {
            if recordType[filter] == EVReflection.swiftStringFromClass(item) {
                let itemID: Int? = data[filter]!.EVindexOf {i in return i.recordID.recordName == recordId}
                if predicate.evaluate(with: item) {
                    var existingItem: CKDataObject?
                    if itemID != nil && itemID < data[filter]!.count {
                        existingItem = data[filter]![itemID!]
                    }
                    if existingItem != nil  {
                        EVLog("Update object for filter \(filter)")
                        EVReflection.setPropertiesfromDictionary(item.toDictionary(), anyObject: data[filter]![itemID!])                        
                        data[filter] = (data[filter]! as NSArray).sortedArray(using: sortOrders[filter]!.sortDescriptors()) as? [CKDataObject]
                        OperationQueue.main.addOperation {
                            (self.updateHandlers[filter]!)(item, itemID!)
                            (self.dataChangedHandlers[filter]!)()
                            self.postDataUpdatedNotification(filter, item: item, dataIndex: itemID!)
                        }
                        dataIsUpdated(filter)
                    } else {
                        EVLog("Insert object for filter \(filter)")
                        data[filter]!.insert(item, at: 0)
                        data[filter] = (data[filter]! as NSArray).sortedArray(using: sortOrders[filter]!.sortDescriptors()) as? [CKDataObject]
                        OperationQueue.main.addOperation {
                            (self.insertedHandlers[filter]!)(item)
                            (self.dataChangedHandlers[filter]!)()
                            self.postDataInsertedNotification(filter, item: item)
                        }
                        dataIsUpdated(filter)
                    }
                } else { // An update of a field that is used in the predicate could trigger a delete from that set.
                    EVLog("Object not for filter \(filter)")
                    if itemID != nil {
                        data[filter]!.remove(at: itemID!)
                        OperationQueue.main.addOperation {
                            (self.deletedHandlers[filter]!)(recordId, itemID!)
                            (self.dataChangedHandlers[filter]!)()
                            self.postDataDeletedNotification(filter, recordId: recordId, dataIndex: itemID!)
                        }
                        dataIsUpdated(filter)
                    }
                }
            }
        }
    }
    
    /**
     Delete an object from every data collection where it's part of
     
     - parameter recordId: The recordId of the object that will be deleted
     :return: No return value
     */
    fileprivate func deleteObject(_ recordId: String) {
        for (filter, _) in self.data {
            if let itemID: Int = data[filter]?.EVindexOf({item in return item.recordID.recordName == recordId}) {
                data[filter]!.remove(at: itemID)
                OperationQueue.main.addOperation {
                    (self.deletedHandlers[filter]!)(recordId, itemID)
                    (self.dataChangedHandlers[filter]!)()
                    self.postDataDeletedNotification(filter, recordId: recordId, dataIndex: itemID)
                }
                dataIsUpdated(filter)
            }
        }
    }

    
    // ------------------------------------------------------------------------
    // MARK: - Data methods - CRUD
    // ------------------------------------------------------------------------
    
    /**
    Get an Item for a recordId
    
    - parameter recordId: The CloudKit record id that we want to get.
    - parameter completionHandler: The function that will be called with the object that we aksed for
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func getItem(_ recordId: String, completionHandler: @escaping (_ result: CKDataObject) -> Void, errorHandler:@escaping (_ error: Error) -> Void) {
        dao.getItem(recordId, completionHandler: { result in
            OperationQueue.main.addOperation {
                self.upsertObject(result.recordID.recordName, item: result)
                completionHandler(result)
            }
            }, errorHandler: {error in
                OperationQueue.main.addOperation {
                    errorHandler(error)
                }
        })
    }
    
    /**
     Save an item and update the connected collections and call the insertedHandlers events for those
     
     - parameter item: object that we want to save
     - parameter completionHandler: The function that will be called with a CKRecord representation of the saved object
     - parameter errorHandler: The function that will be called when there was an error
     :return: No return value
     */
    open func saveItem<T:CKDataObject>(_ item: T, completionHandler: @escaping (_ item: T) -> Void, errorHandler:@escaping (_ error: Error) -> Void) {
        OperationQueue().addOperation() {
            self.upsertObject(item.recordID.recordName, item: item)
        }
        dao.saveItem(item, completionHandler: { record in
            if let savedItem = record.toDataObject() as? T {
                self.upsertObject(savedItem.recordID.recordName, item: savedItem)
                item.recordChangeTag = savedItem.recordChangeTag
                item.lastModifiedUserRecordID = savedItem.lastModifiedUserRecordID
                item.modificationDate = savedItem.modificationDate
                item.encodedSystemFields = savedItem.encodedSystemFields
                OperationQueue.main.addOperation {
                    completionHandler(savedItem)
                }
            }
            }, errorHandler: {error in
                OperationQueue.main.addOperation {
                    errorHandler(error)
                }
        })
    }
    
    /**
     Delete an Item for a recordId and update the connected collections and call the deletedHandlers events for those
     
     - parameter recordId: The CloudKit record id of the record that we want to delete
     - parameter completionHandler: The function that will be called with a record id of the deleted object
     - parameter errorHandler: The function that will be called when there was an error
     :return: No return value
     */
    open func deleteItem(_ recordId: String, completionHandler: @escaping (_ recordId: CKRecordID) -> Void, errorHandler:@escaping (_ error: Error) -> Void) {
        self.deleteObject(recordId)
        dao.deleteItem(recordId, completionHandler: { recordId in
            self.deleteObject(recordId.recordName)
            OperationQueue.main.addOperation {
                completionHandler(recordId)
            }
            }, errorHandler: {error in
                OperationQueue.main.addOperation {
                    errorHandler(error)
                }
        })
    }
    
    
    
    // ------------------------------------------------------------------------
    // MARK: - Query and subscribe
    // ------------------------------------------------------------------------
    
    /**
    Create a data connection between your app and CloudKit. Execute a query, create a subscription, process notifications, maintain an in memory dictionary of objects and execute apropriate events. The connection will be based on a predicate.
    
    - parameter type: The CloudKit record id of the record that we want to delete
    - parameter predicate: The filter that will be used. To see how to create a predicate, see: https://developer.apple.com/library/prerelease/ios/documentation/CloudKit/Reference/CKQuery_class/index.html
    - parameter filterId: The filterId under what this filter should be registered (must be unique per predicate
    - parameter cachingStrategy: Optional vale for setting the caching strategy for this connect. The default value is CachingStrategy.Direct
    - parameter configureNotificationInfo: The function that will be called with the CKNotificationInfo object so that we can configure it
    - parameter completionHandler: The function that will be called with a record id of the deleted object
    - parameter insertedHandler: Executed if the notification was for an inserted object
    - parameter updatedHandler: Executed if the notification was for an updated object pasing on the data object plus the index in the data array
    - parameter deletedHandler: Executed if the notification was for an deleted object passing on the recordId plus the index it had in the data array
    - parameter dataChangedHandler: Executed on all data modifications (completion, inserted, updated and deleted)
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    @discardableResult
    open func connect<T: CKDataObject>(
        _ type: T,
        predicate: NSPredicate,
        orderBy: OrderBy = Descending(field: "creationDate"),
        filterId: String,
        cachingStrategy: CachingStrategy = CachingStrategy.direct,
        postNotifications: Bool? = nil,
        configureNotificationInfo:((_ notificationInfo:CKNotificationInfo ) -> Void)? = nil,
        completionHandler: ((_ results: [T], _ status: CompletionStatus) -> Bool)? = nil,
        insertedHandler:((_ item: T) -> Void)? = nil,
        updatedHandler:((_ item: T, _ dataIndex: Int) -> Void)? = nil,
        deletedHandler:((_ recordId: String, _ dataIndex: Int) -> Void)? = nil,
        dataChangedHandler:(() -> Void)? = nil,
        errorHandler:((_ error: Error) -> Void)? = nil
        ) -> CKQueryOperation {
            // Set the post notifications flag for this filter ID before checking the cache
            if postNotifications != nil && postNotifications! {
                self.postNotifications[filterId] = postNotifications!
            }
            
            // If we have a cache for this filter, then first return that.
            if cachingStrategy != CachingStrategy.none  && restoreDataForFilter(filterId) {
                if let filterData = self.data[filterId] as? [T] {
                    postDataCompletedNotification(filterId, results: filterData, status: .fromCache)
                    if let handler = completionHandler {
                        let _ = handler(filterData, .fromCache)
                    }
                }
                if let handler = dataChangedHandler {
                    handler()
                }
            } else {
                if let handler = completionHandler {
                    let _ = handler([], .retrieving)
                }
                postDataCompletedNotification(filterId, results: [], status: .retrieving)
            }
            
            // setting the connection properties
            if data[filterId] == nil {
                self.data[filterId] = [T]()
            }
            self.recordType[filterId] = EVReflection.swiftStringFromClass(type)
            self.predicates[filterId] = predicate
            self.sortOrders[filterId] = orderBy
            self.cachingLastWrite[filterId] = Date()
            self.cachingChangesCount[filterId] = 0
            self.cachingStrategies[filterId] = cachingStrategy
            
            // Wrapping (Type and optional) the generic function so that we can add it to the collection and prevent nil reference exceptions
            if insertedHandler != nil {
                func insertedHandlerWrapper(_ item: CKDataObject) -> Void {
                    if let insertedItem = item as? T {
                        insertedHandler!(insertedItem)
                    }
                }
                self.insertedHandlers[filterId] = insertedHandlerWrapper
            } else {
                func insertedHandlerWrapper(_ item: CKDataObject) -> Void { }
                self.insertedHandlers[filterId] = insertedHandlerWrapper
            }
            
            if updatedHandler != nil {
                func updatedHandlerWrapper(_ item: CKDataObject, dataIndex: Int) -> Void {
                    if let updatedItem = item as? T {
                        updatedHandler!(updatedItem, dataIndex)
                    }
                }
                self.updateHandlers[filterId] = updatedHandlerWrapper
            } else {
                func updatedHandlerWrapper(_ item: CKDataObject, dataIndex: Int) -> Void { }
                self.updateHandlers[filterId] = updatedHandlerWrapper
            }
            
            if deletedHandler != nil {
                self.deletedHandlers[filterId] = deletedHandler!
            } else {
                func emptyDeletedHandler(_ recordId: String, dataIndex: Int) -> Void {}
                self.deletedHandlers[filterId] = emptyDeletedHandler
            }
            
            if dataChangedHandler != nil {
                self.dataChangedHandlers[filterId] = dataChangedHandler!
            } else {
                func emptyDataChangedHandler() -> Void {}
                self.dataChangedHandlers[filterId] = emptyDataChangedHandler
            }
            
            dao.subscribe(type, predicate:predicate, filterId: filterId, configureNotificationInfo:configureNotificationInfo ,errorHandler: errorHandler)
            
            return dao.query(type, predicate: predicate, orderBy: orderBy, completionHandler: { results, isFinished in
                if self.data[filterId] != nil && self.data[filterId]! == results && self.data[filterId]!.count > 0 {
                    return false // Result was already returned from cache
                }
                
                var continueReading: Bool = false
                self.data[filterId] = results
                let sema = DispatchSemaphore(value: 0)
                OperationQueue.main.addOperation {
                    let status = isFinished ? CompletionStatus.finalResult : CompletionStatus.partialResult
                    self.postDataCompletedNotification(filterId, results: results, status: status)
                    if completionHandler != nil {
                        continueReading = completionHandler!(results, status)
                    }
                    sema.signal();
                    if dataChangedHandler != nil {
                        dataChangedHandler!()
                    }
                }
                if self.cachingStrategies[filterId]! != CachingStrategy.none {
                    self.backupDataForFilter(filterId)
                }
                let _ = sema.wait(timeout: DispatchTime.distantFuture);
                return continueReading
                }, errorHandler: {error in
                    OperationQueue.main.addOperation {
                        if errorHandler != nil {
                            errorHandler!(error)
                        }
                    }
            })
    }
    
    /**
     Disconnect an existing connection. When a connect is made, then at least in the deinit you must do a disconnect for that same filterId.
     
     - parameter filterId: The filterId
     */
    open func disconnect(_ filterId: String) {
        let changed = dataChangedHandlers[filterId]
        insertedHandlers.removeValue(forKey: filterId)
        updateHandlers.removeValue(forKey: filterId)
        deletedHandlers.removeValue(forKey: filterId)
        dataChangedHandlers.removeValue(forKey: filterId)
        predicates.removeValue(forKey: filterId)
        data.removeValue(forKey: filterId)
        if changed != nil {
            changed!()
        }
    }
    
    /**
     Disconnect all connections
     */
    open func disconnectAll() {
        for (key, _) in data {
            disconnect(key)
        }
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - Handling remote notifications
    // ------------------------------------------------------------------------
    
    /**
    Call this from the AppDelegate didReceiveRemoteNotification for processing the notifications
    
    - parameter userInfo: CKNotification dictionary
    - parameter executeIfNonQuery: Will be called if the notification is not for a CloudKit subscription
    - parameter completed: Executed when all notifications are processed
    :return: No return value
    */
    open func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], executeIfNonQuery:() -> Void, completed:@escaping ()-> Void) {
        dao.didReceiveRemoteNotification(userInfo, executeIfNonQuery: executeIfNonQuery, inserted: {recordId, item in
            self.upsertObject(recordId, item: item)
            }, updated: {recordId, item in
                self.upsertObject(recordId, item: item)
            }, deleted: {recordId in
                self.deleteObject(recordId)
            }, completed: {
                completed()
        })
    }
    
    /**
     Call this in the AppDelegate didFinishLaunchingWithOptions to handle not yet handled notifications.
     
     - parameter completed: Executed when all notifications are processed
     :return: No return value
     */
    open func fetchChangeNotifications(_ completed:@escaping ()-> Void) {
        dao.fetchChangeNotifications(nil, inserted: {recordId, item in
            self.upsertObject(recordId, item: item)
            }, updated : {recordId, item in
                self.upsertObject(recordId, item: item)
            }, deleted : {recordId in
                self.deleteObject(recordId)
            }, completed: {
                completed()
        })
    }
}

/**
 These Array extensions are a copy from the ExSwift library. They ar copied here to limit dependencies.
 */
extension Array {
    /**
     Index of the first item that meets the condition.
     
     - parameter condition: A function which returns a boolean if an element satisfies a given condition or not.
     - returns: Index of the first matched item or nil
     */
    func EVindexOf (_ condition: (Element) -> Bool) -> Int? {
        for (index, element) in self.enumerated() {
            if condition(element) {
                return index
            }
        }
        
        return nil
    }
}
