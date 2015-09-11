//
//  EVCloudData.swift
//
//  Created by Edwin Vermeer on 09-08-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation
import CloudKit
import EVReflection

/**
The enum for specifying the caching strategy for the data
*/
public enum CachingStrategy {
    /**
    Do not cache this
    */
    case None,
    /**
    Always write changes to the cache immediately
    */
    Direct,
    /**
    Only write to the cache once every .. minutes when there are changes (initial query result will always be written directly)
    */
    Every(minute:Int)
}


/**
Strange enough by default Swift does not implement the Equality operator for enums. So we just made one ourselves.

- parameter leftPart: The CachingStrategy value at the left of the equality operator.
- parameter rightPart: The CachingStrategy value at the right of the equality operator.
*/
func ==(leftPart: CachingStrategy, rightPart: CachingStrategy) -> Bool {
    switch(leftPart) {
    case .None:
        switch(rightPart) {
        case .None: return true
        default: return false
        }
    case .Direct:
        switch(rightPart) {
        case .Direct: return true
        default: return false
        }
    case .Every(let minutea):
        switch(rightPart) {
        case .Every(let minuteb): return minutea == minuteb
        default: return false
        }
    }
}


/**
Strange enough by default Swift does not implement the not Equality operator for enums. So we just made one ourselves.

- parameter leftPart: The CachingStrategy value at the left of the equality operator.
- parameter rightPart: The CachingStrategy value at the right of the equality operator.
*/
func !=(leftPart: CachingStrategy, rightPart: CachingStrategy) -> Bool {
    return !(leftPart == rightPart)
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
public class EVCloudData: NSObject {

    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------

    /**
    Singleton access to EVCloudData that can be called from Swift

    :return: The EVCloudData object
    */
    public class var publicDB: EVCloudData {
        struct Static { static let instance: EVCloudData = EVCloudData() }
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
    public class var privateDB: EVCloudData {
        struct Static { static let instance: EVCloudData = EVCloudData() }
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

    /**
    Singleton acces to the wrapper class with the dictionaries with public and private containers.

    :return: The container wrapper class
    */
    private class var containerWrapperInstance: DataContainerWrapper {
        struct Static { static var instance: DataContainerWrapper = DataContainerWrapper()}
        return Static.instance
    }

    /**
    Singleton acces to a specific named public container
    - parameter containterIdentifier: The identifier of the public container that you want to use.

    :return: The public container for the identifier.
    */
    public class func publicDBForContainer(containerIdentifier: String) -> EVCloudData {
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
    public class func privateDBForContainer(containerIdentifier: String) -> EVCloudData {
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
    override init() {
        let pathDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if pathDir.count > 0 {
            fileDirectory = pathDir[0]
        } else
        {
            fileDirectory = ""
        }
        filemanager = NSFileManager.defaultManager()
        ioQueue = dispatch_queue_create("NL.EVICT.CloudKit.ioQueue", DISPATCH_QUEUE_SERIAL) as dispatch_queue_t

        super.init()
        NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("backupAllData"), userInfo: nil, repeats: true)
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
    The caching strategy for each filter for when incomming data should be written to a file
    */
    public var cachingStrategies = Dictionary <String, CachingStrategy>()
    /**
    The timestamp of the last cach write for each filter
    */
    public var cachingLastWrite = Dictionary <String, NSDate>()
    /**
    The number of changes since the last cache write for each filter
    */
    public var cachingChangesCount = Dictionary <String, Int>()
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
    public var updateHandlers = Dictionary<String, (item: EVCloudKitDataObject, dataIndex: Int) -> Void>()
    /**
    A dictionary of dataChanged event handlers. Each filterId is a dictionary entry containing a dataChanged event handler
    */
    public var dataChangedHandlers = Dictionary<String, () -> Void>()
    /**
    A dictionary of delete event handlers. Each filterId is a dictionary entry containing a delete event handler
    */
    public var deletedHandlers = Dictionary<String, (recordId: String, dataIndex: Int) -> Void>()


    // ------------------------------------------------------------------------
    // MARK: - Store data to local file cache
    // ------------------------------------------------------------------------

    private let fileDirectory: NSString
    private let filemanager: NSFileManager
    private let ioQueue: dispatch_queue_t

    /**
    Write the data for a specific filter to a file if the corresponding backup strategy has been met.

    - parameter filterId: The filter id for the data that needs to be written to a file
    */
    private func backupDataWithStrategyTest(filterId: String) {
        switch cachingStrategies[filterId]! {
        case CachingStrategy.None:
            return
        case CachingStrategy.Direct:
            if cachingChangesCount[filterId] > 0 {
                backupDataForFilter(filterId)
            }
        case CachingStrategy.Every(let minute):
            if cachingChangesCount[filterId] > 0 {
                if dateDiffInMinutes(cachingLastWrite[filterId]!, toDate: NSDate()) >= minute {
                    backupDataForFilter(filterId)
                }
            }
        }
    }

    /**
    Handle data updates

    - parameter filterId: The filter id for the data that was received from CloudKit
    */
    private func dataIsUpdated(filterId: String) {
        cachingChangesCount[filterId] = cachingChangesCount[filterId]! + 1
        backupDataWithStrategyTest(filterId)
    }

    /**
    Return the difrence of 2 dates in minutes

    - parameter fromDate: The first date for the comparison
    - parameter toDate: The second date for the comparison
    */
    private func dateDiffInMinutes(fromDate: NSDate, toDate: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(.Minute, fromDate: fromDate, toDate: toDate, options: NSCalendarOptions(rawValue: 0)).minute
    }

    /**
    Make sure that all data is backed up while taking into account the selected CachingStrategy. You should call this method right before exiting your app.
    */
    public func backupAllData() {
        for (key, _) in cachingLastWrite {
            backupDataWithStrategyTest(key)
        }
    }

    /**
    Restore all previously backed up data for all initialized connections. Be aware that these already should have been restored.
    */
    public func restoreAllData() {
        for (key, _) in cachingLastWrite {
            restoreDataForFilter(key)
        }
    }

    /**
    Remove the backup files for all the initialized connections.
    */
    public func removeAllBackups() {
        for (key, _) in cachingLastWrite {
            removeBackupForFilter(key)
        }
    }

    /**
    Write the data for a specific filter to a file

    - parameter filterId: The filter id for the data that needs to be written to a file
    */
    public func backupDataForFilter(filterId: String) {
        if let theData = data[filterId] {
            backupData(theData, toFile: "Filter_\(filterId).bak" )
            self.cachingLastWrite[filterId] = NSDate()
            self.cachingChangesCount[filterId] = 0
        }
    }

    /**
    Restore data for a specific filter from a file

    - parameter filterId: The filter id for the data that will be restored from file
    */
    public func restoreDataForFilter(filterId: String) -> Bool {
        if let theData = restoreData("Filter_\(filterId).bak") as? [EVCloudKitDataObject] {
            data[filterId] = theData
            return true
        }
        return false
    }

    /**
    Remove the backup for a specific filter

    - parameter filterId: The filter id for the backup file that will be removed
    */
    public func removeBackupForFilter(filterId: String) {
        removeBackup("Filter_\(filterId).bak")
    }

    /**
    Write data to a file

    - parameter data: The data that will be written to the file (Needs to implement NSCoding like the EVCloudKitDataObject)
    - parameter toFile: The file that will be written to
    */
    public func backupData(data: AnyObject, toFile: String){
        let filePath = fileDirectory.stringByAppendingPathComponent(toFile)
        dispatch_sync(ioQueue) {
            NSKeyedArchiver.archiveRootObject(data, toFile: filePath)
            addSkipBackupAttributeToItemAtPath(filePath)
            EVLog("Data is written to \(filePath))")
        }
    }
    
    /**
    Read a backup file and return it as an unarchived object

    - parameter fromFile: The file that will be read and parsed to objects
    */
    public func restoreData(fromFile: String) -> AnyObject? {
        let filePath = fileDirectory.stringByAppendingPathComponent(fromFile)
        var result: AnyObject? = nil
        dispatch_sync(ioQueue) {
            if self.filemanager.fileExistsAtPath(filePath) {
                result = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath)
                EVLog("Data is restored from \(filePath))")
            }
        }
        return result
    }

    /**
    Remove a backup file

    - parameter file: The file that will be removed from the backup folder (EVCloudDataBackup)
    */
    public func removeBackup(file: String) {
        let filePath = fileDirectory.stringByAppendingPathComponent(file)
        dispatch_sync(ioQueue) {
            if self.filemanager.fileExistsAtPath(filePath) {
                do {
                    try self.filemanager.removeItemAtPath(filePath)
                } catch  _ as NSError {
                } catch {
                    fatalError()
                }
            }
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
    private func upsertObject(recordId: String, item: EVCloudKitDataObject) {
        EVLog("upsert \(recordId) \(EVReflection.swiftStringFromClass(item))")
        for (filter, predicate) in self.predicates {
            if recordType[filter] == EVReflection.swiftStringFromClass(item) {
                let itemID: Int? = data[filter]!.EVindexOf {i in return i.recordID.recordName == recordId}
                if predicate.evaluateWithObject(item) {
                    var existingItem: EVCloudKitDataObject?
                    if itemID != nil && itemID < data[filter]!.count {
                        existingItem = data[filter]![itemID!]
                    }
                    if existingItem != nil  {
                        EVLog("Update object for filter \(filter)")
                        data[filter]!.removeAtIndex(itemID!)
                        data[filter]!.insert(item, atIndex: itemID!)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            (self.updateHandlers[filter]!)(item: item, dataIndex:itemID!)
                            (self.dataChangedHandlers[filter]!)()
                        }
                        dataIsUpdated(filter)
                    } else {
                        EVLog("Insert object for filter \(filter)")
                        data[filter]!.insert(item, atIndex: 0)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            (self.insertedHandlers[filter]!)(item: item)
                            (self.dataChangedHandlers[filter]!)()
                        }
                        dataIsUpdated(filter)
                    }
                } else { // An update of a field that is used in the predicate could trigger a delete from that set.
                    EVLog("Object not for filter \(filter)")
                    if itemID != nil {
                        data[filter]!.removeAtIndex(itemID!)
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            (self.deletedHandlers[filter]!)(recordId: recordId, dataIndex:itemID!)
                            (self.dataChangedHandlers[filter]!)()
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
    private func deleteObject(recordId: String) {
        for (filter, _) in self.data {
            let itemID: Int? = data[filter]!.EVindexOf {item in return item.recordID.recordName == recordId}
            if itemID != nil {
                data[filter]!.removeAtIndex(itemID!)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    (self.deletedHandlers[filter]!)(recordId: recordId, dataIndex:itemID!)
                    (self.dataChangedHandlers[filter]!)()
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
    public func getItem(recordId: String, completionHandler: (result: EVCloudKitDataObject) -> Void, errorHandler:(error: NSError) -> Void) {
        dao.getItem(recordId, completionHandler: { result in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.upsertObject(result.recordID.recordName, item: result)
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

    - parameter item: object that we want to save
    - parameter completionHandler: The function that will be called with a CKRecord representation of the saved object
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func saveItem<T:EVCloudKitDataObject>(item: T, completionHandler: (item: T) -> Void, errorHandler:(error: NSError) -> Void) {
        NSOperationQueue().addOperationWithBlock() {
            self.upsertObject(item.recordID.recordName, item: item)
        }
        dao.saveItem(item, completionHandler: { record in
            if let savedItem = self.dao.fromCKRecord(record)! as? T {
                self.upsertObject(savedItem.recordID.recordName, item: savedItem)
                item.recordChangeTag = savedItem.recordChangeTag
                item.lastModifiedUserRecordID = savedItem.lastModifiedUserRecordID
                item.modificationDate = savedItem.modificationDate
                item.encodedSystemFields = savedItem.encodedSystemFields
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completionHandler(item: savedItem)
                }
            }
        }, errorHandler: {error in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                errorHandler(error: error)
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
    public func deleteItem(recordId: String, completionHandler: (recordId: CKRecordID) -> Void, errorHandler:(error: NSError) -> Void) {
        self.deleteObject(recordId)
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
    public func connect<T:EVCloudKitDataObject>(
        type: T,
        predicate: NSPredicate,
        filterId: String,
        cachingStrategy: CachingStrategy = CachingStrategy.Direct,
        configureNotificationInfo:((notificationInfo:CKNotificationInfo ) -> Void)? = nil,
        completionHandler: ((results: [T]) -> Bool)? = nil,
        insertedHandler:((item: T) -> Void)? = nil,
        updatedHandler:((item: T, dataIndex: Int) -> Void)? = nil,
        deletedHandler:((recordId: String, dataIndex: Int) -> Void)? = nil,
        dataChangedHandler:(() -> Void)? = nil,
        errorHandler:((error: NSError) -> Void)? = nil
        ) -> Void {
            // If we have a cache for this filter, then first return that.
            if restoreDataForFilter(filterId) {
                if let handler = completionHandler {
                    if let filterData = self.data[filterId] as? [T] {
                        handler(results: filterData)
                    }
                }
                if let handler = dataChangedHandler {
                    handler()
                }
            }

            // setting the connection properties
            if data[filterId] == nil {
                self.data[filterId] = [T]()
            }
            self.recordType[filterId] = EVReflection.swiftStringFromClass(type)
            self.predicates[filterId] = predicate
            self.cachingLastWrite[filterId] = NSDate()
            self.cachingChangesCount[filterId] = 0
            self.cachingStrategies[filterId] = cachingStrategy

            // Wrapping (Type and optional) the generic function so that we can add it to the collection and prevent nil reference exceptions
            if insertedHandler != nil {
                func insertedHandlerWrapper(item: EVCloudKitDataObject) -> Void {
                    if let insertedItem = item as? T {
                        insertedHandler!(item: insertedItem)
                    }
                }
                self.insertedHandlers[filterId] = insertedHandlerWrapper
            } else {
                func insertedHandlerWrapper(item: EVCloudKitDataObject) -> Void { }
                self.insertedHandlers[filterId] = insertedHandlerWrapper
            }

            if updatedHandler != nil {
                func updatedHandlerWrapper(item: EVCloudKitDataObject, dataIndex: Int) -> Void {
                    if let updatedItem = item as? T {
                        updatedHandler!(item: updatedItem, dataIndex: dataIndex)
                    }
                }
                self.updateHandlers[filterId] = updatedHandlerWrapper
            } else {
                func updatedHandlerWrapper(item: EVCloudKitDataObject, dataIndex: Int) -> Void { }
                self.updateHandlers[filterId] = updatedHandlerWrapper
            }

            if deletedHandler != nil {
                self.deletedHandlers[filterId] = deletedHandler!
            } else {
                func emptyDeletedHandler(recordId: String, dataIndex: Int) -> Void {}
                self.deletedHandlers[filterId] = emptyDeletedHandler
            }

            if dataChangedHandler != nil {
                self.dataChangedHandlers[filterId] = dataChangedHandler!
            } else {
                func emptyDataChangedHandler() -> Void {}
                self.dataChangedHandlers[filterId] = emptyDataChangedHandler
            }

            dao.subscribe(type, predicate:predicate, filterId: filterId, configureNotificationInfo:configureNotificationInfo ,errorHandler: errorHandler)

            dao.query(type, predicate: predicate, completionHandler: { results in
                if self.data[filterId] != nil && self.data[filterId]! == results && self.data[filterId]!.count > 0 {
                    return false // Result was already returned from cache
                }

                var continueReading: Bool = false
                self.data[filterId] = results
                let sema = dispatch_semaphore_create(0)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    if completionHandler != nil {
                        continueReading = completionHandler!(results: results)
                    }
                    dispatch_semaphore_signal(sema);
                    if dataChangedHandler != nil {
                        dataChangedHandler!()
                    }
                }
                if self.cachingStrategies[filterId]! != CachingStrategy.None {
                    self.backupDataForFilter(filterId)
                }
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                return continueReading
            }, errorHandler: {error in
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    if errorHandler != nil {
                        errorHandler!(error: error)
                    }
                }
            })
    }

    /**
    Disconnect an existing connection. When a connect is made, then at least in the deinit you must do a disconnect for that same filterId.

    - parameter filterId: The filterId
    */
    public func disconnect(filterId: String) {
        let changed = dataChangedHandlers[filterId]
        insertedHandlers.removeValueForKey(filterId)
        updateHandlers.removeValueForKey(filterId)
        deletedHandlers.removeValueForKey(filterId)
        dataChangedHandlers.removeValueForKey(filterId)
        predicates.removeValueForKey(filterId)
        data.removeValueForKey(filterId)
        if changed != nil {
            changed!()
        }
    }

    /**
    Disconnect all connections
    */
    public func disconnectAll() {
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
    public func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject], executeIfNonQuery:() -> Void, completed:()-> Void) {
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
    public func fetchChangeNotifications(completed:()-> Void) {
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
    func EVindexOf (condition: Element -> Bool) -> Int? {
        for (index, element) in self.enumerate() {
            if condition(element) {
                return index
            }
        }

        return nil
    }
}
