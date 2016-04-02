//
//  EVCloudKitDao.swift
//
//  Created by Edwin Vermeer on 04-06-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation
import CloudKit
import EVReflection



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
    public class var publicDB: EVCloudKitDao {
        /**
        Singleton structure
        */
        struct Static { static let instance: EVCloudKitDao = EVCloudKitDao() }
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
    public class var privateDB: EVCloudKitDao {
        struct Static { static let instance: EVCloudKitDao = EVCloudKitDao() }
        Static.instance.isType = .IsPrivate
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
    private class var containerWrapperInstance: DaoContainerWrapper {
        struct Static { static var instance: DaoContainerWrapper = DaoContainerWrapper()}
        return Static.instance
    }

    /**
    Singleton acces to a specific named public container
    - parameter containterIdentifier: The identifier of the public container that you want to use.

    :return: The public container for the identifier.
    */
    public class func publicDBForContainer(containterIdentifier: String) -> EVCloudKitDao {
        if let containerInstance = containerWrapperInstance.publicContainers[containterIdentifier] {
            return containerInstance
        }
        containerWrapperInstance.publicContainers[containterIdentifier] =  EVCloudKitDao(containerIdentifier: containterIdentifier)
        return containerWrapperInstance.publicContainers[containterIdentifier]!
    }

    /**
    Singleton acces to a specific named private container
    - parameter containterIdentifier: The identifier of the private container that you want to use.

    :return: The private container for the identifier.
    */
    public class func privateDBForContainer(containterIdentifier: String) -> EVCloudKitDao {
        if let containerInstance = containerWrapperInstance.privateContainers[containterIdentifier] {
            return containerInstance
        }
        let dao = EVCloudKitDao(containerIdentifier: containterIdentifier)
        dao.isType = .IsPrivate
        dao.database = dao.container.privateCloudDatabase
        containerWrapperInstance.privateContainers[containterIdentifier] = dao
        return dao
    }


    // ------------------------------------------------------------------------
    // MARK: - Initialisation
    // ------------------------------------------------------------------------

    /**
    Access to the default CloudKit container

    :return: The default CloudKit container
    */
    private var container: CKContainer!


    /**
    Access to the public database

    :return: The public database
    */
    private var database: CKDatabase!

    /**
    The iClout account status of the current user

    :return: The account status of the current user
    */
    public var accountStatus: CKAccountStatus?

    /**
    The iCloud account information of the current user

    :return: The account information of the current user
    */
    public var activeUser: CKDiscoveredUserInfo!


    /**
    For regestering if this class is for the public or the private database
     
    :return: Public or private
    */
    public var isType: InstanceType = .IsPublic
    
    // Fast access to the file directory
    private var fileDirectory: NSString!
    // Fast access to the filemanager
    private var filemanager: NSFileManager!
    // Fast access to the queue
    private var ioQueue: dispatch_queue_t!

    /**
    On init set a quick refrence to the container and database
    */
    init() {
        self.initializeDatabase()
    }

    /**
    On init set a quick reference to the container and database for a specific container.

     - parameter containerIdentifier: Passing on the name of the container
    */
    init(containerIdentifier: String) {
        self.initializeDatabase(containerIdentifier)
    }

    /**
    Set or reset the quick reference to the container and database

    - parameter containerIdentifier: Passing on the name of the container
    */
    public func initializeDatabase(containerIdentifier: String? = nil) {
        let pathDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        if pathDir.count > 0 {
            fileDirectory = pathDir[0]
        } else
        {
            fileDirectory = ""
        }
        filemanager = NSFileManager.defaultManager()
        ioQueue = dispatch_queue_create("NL.EVICT.CloudKit.ioQueue", DISPATCH_QUEUE_SERIAL) as dispatch_queue_t

        if let identifier = containerIdentifier {
            container = CKContainer(identifier: identifier)
        } else {
            container = CKContainer.defaultContainer()
        }
        if self.isType == .IsPublic {
            database = container.publicCloudDatabase
        } else {
            database = container.privateCloudDatabase
        }

        let sema = dispatch_semaphore_create(0)
        container.accountStatusWithCompletionHandler({status, error in
            if error != nil {
                EVLog("Error: Initialising EVCloudKitDao - accountStatusWithCompletionHandler.\n\(error!.description)")
            } else {
                self.accountStatus = status
            }
            EVLog("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
            dispatch_semaphore_signal(sema);
        })
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        EVLog("Container identifier = \(container.containerIdentifier)")
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Helper methods
    // ------------------------------------------------------------------------

    //
    /**
    Generic CloudKit callback handling

    - parameter error: Passing on the error
    - parameter errorHandler: The error handler function that will be called if there is an error
    - parameter completionHandler: The function that will be called if ther is no error
    :return: No return value
    */
    internal func handleCallback(error: NSError?, errorHandler: ((error: NSError) -> Void)? = nil, completionHandler: () -> Void) {
        if error != nil {
            EVLog("Error: \(error?.code) = \(error?.description) \n\(error?.userInfo)")
            if let handler = errorHandler {
                handler(error: error!)
            }
        } else {
            completionHandler()
        }
    }
    
    /**
     When both error and value are nil, you will get a custom error
     
     - parameter error: The original error
     - parameter value: The value that should not be nil
     */
    internal func nilNotAllowed(error: NSError?, value: AnyObject?) -> NSError? {
        if error != nil || value != nil {
            return error
        }
        return NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : "function returend nil without an error"])
    }

    
    /**
    Categorise CloudKit errors into a functional status that will tell you how it should be handled.
    
    - parameter error: The CloudKit error for which you want a functional status.
    - parameter retryAttempt: In case we are retrying a function this parameter has to be incremented each time.
    */
    public static func handleCloudKitErrorAs(error:NSError?, retryAttempt:Double = 1) -> HandleCloudKitErrorAs {
        // There is no error
        if error == nil {
            return .Success
        }
        
        // Or if there is a retry delay specified in the error, then use that.
        if let userInfo = error?.userInfo {
            if let retry = userInfo[CKErrorRetryAfterKey] as? NSNumber {
                let seconds = Double(retry)
                NSLog("Debug: Should retry in \(seconds) seconds. \(error)")
                return .Retry(afterSeconds: seconds)
            }
        }
        
        let errorCode:CKErrorCode = CKErrorCode(rawValue: error!.code)!
        switch errorCode {
        case .NotAuthenticated, .NetworkUnavailable, .NetworkFailure, .ServiceUnavailable, .RequestRateLimited, .ZoneBusy, .ResultsTruncated:
            // Probably handled by the userInfo[CKErrorRetryAfterKey] but if not, then:
            // Use an exponential retry delay which maxes out at half an hour.
            var seconds = Double(pow(2, Double(retryAttempt)))
            if seconds > 1800 {
                seconds = 1800
            }
            NSLog("Debug: Should retry in \(seconds) seconds. \(error)")
            return .Retry(afterSeconds: seconds)
        case .UnknownItem, .InvalidArguments, .IncompatibleVersion, .BadContainer, .MissingEntitlement, .PermissionFailure, .BadDatabase, .AssetFileNotFound, .OperationCancelled, .AssetFileModified, .BatchRequestFailed, .ZoneNotFound, .UserDeletedZone, .InternalError, .ServerRejectedRequest, .ConstraintViolation:
            NSLog("Error: \(error)")
            return .Fail;
        case .QuotaExceeded, .LimitExceeded:
            NSLog("Warning: \(error)")
            return .Fail;
        case .ChangeTokenExpired,  .ServerRecordChanged:
            NSLog("Info: \(error)")
            return .RecoverableError
        default:
            NSLog("Error: \(error)") //New error introduced in iOS...?
            return .Fail;
        }
    }
    
    
    /**
    Generic query handling

    - parameter type: An object instance that will be used as the type of the records that will be returned
    - parameter query: The CloudKit query that will be executed
    - parameter completionHandler: The function that will be called with the result of the query
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
  internal func queryRecords<T:EVCloudKitDataObject>(type:T, query: CKQuery, completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation {
        if !(query.sortDescriptors != nil) {
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        let operation = CKQueryOperation(query: query)
        operation.qualityOfService = .UserInitiated
        operation.queuePriority = .VeryHigh
        var results = [T]()
        operation.recordFetchedBlock = { record in
            if let parsed = self.fromCKRecord(record) as? T  {
                results.append(parsed)
            }
        }

        operation.queryCompletionBlock = { cursor, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
              if completionHandler(results: results, isFinished: cursor == nil) {
                    if cursor != nil {
                        self.queryRecords(cursor!, continueWithResults: results, completionHandler: completionHandler, errorHandler: errorHandler)
                    }
                }
            })
        }
        operation.resultsLimit = CKQueryOperationMaximumResults;
        database.addOperation(operation)
        return operation
    }


    /**
    Generic query handling continue from cursor
    
    - parameter type: An object instance that will be used as the type of the records that will be returned
    - parameter cursor: the cursor to read from
    - parameter completionHandler: The function that will be called with the result of the query
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    private func queryRecords<T:EVCloudKitDataObject>(cursor: CKQueryCursor, continueWithResults:[T], completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation {
        var results = continueWithResults
        let operation = CKQueryOperation(cursor: cursor)
        operation.qualityOfService = .UserInitiated
        operation.recordFetchedBlock = { record in
            if let parsed = self.fromCKRecord(record) as? T  {
                results.append(parsed)
            }
        }

        operation.queryCompletionBlock = { cursor, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                if completionHandler(results: results, isFinished: cursor == nil) {
                    if cursor != nil {
                        self.queryRecords(cursor!, continueWithResults: results, completionHandler: completionHandler, errorHandler: errorHandler)
                    }
                }
            })
        }
        operation.resultsLimit = CKQueryOperationMaximumResults;
        database.addOperation(operation)
        return operation
    }



    /**
    Helper method for getting a reference (with delete action)

    - parameter recordId: The record id that will be converted to a CKReference
    :return: The CKReference that is created from the recordId
    */
    public func referenceForId(recordId: String) -> CKReference {
        return CKReference(recordID: CKRecordID(recordName: recordId), action: CKReferenceAction.DeleteSelf)
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - initialize record types
    // ------------------------------------------------------------------------

    /**
    This is a helper method that inserts and removes records in order to create the recordtypes in the iCloud
    You only need to call this method once, ever.

    - parameter types: An array of objects for which CloudKit record types should be generated
    :return: No return value
    */
    public func createRecordTypes(types: [EVCloudKitDataObject]) {
        for item in types {
            let sema = dispatch_semaphore_create(0);
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
    Are we allowed to call the discoverAllContactUserInfosWithCompletionHandler function?

    - parameter completionHandler: The function that will be called with the result of the query (true or false)
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func requestDiscoverabilityPermission(completionHandler: (granted: Bool) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        container.requestApplicationPermission(CKApplicationPermissions.UserDiscoverability, completionHandler: { (status:CKApplicationPermissionStatus, error:NSError?) -> Void in

            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                completionHandler(granted: status == CKApplicationPermissionStatus.Granted)
            })
        })
    }

    /**
    Get the info of the current user

    - parameter completionHandler: The function that will be called with the CKDiscoveredUserInfo object
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func discoverUserInfo(completionHandler: (user: CKDiscoveredUserInfo) -> Void, errorHandler:((error:NSError) -> Void)? = nil) {
        container.fetchUserRecordIDWithCompletionHandler({recordID, error in
            self.handleCallback(self.nilNotAllowed(error, value: recordID), errorHandler: errorHandler, completionHandler: {
                self.container.discoverUserInfoWithUserRecordID(recordID!, completionHandler: { user, error in
                    self.handleCallback(self.nilNotAllowed(error, value: user), errorHandler: errorHandler, completionHandler: {
                        self.activeUser = user
                        completionHandler(user: user!)
                    })
                })
            })
        })
    }
    
    
    // discoverAllContactUserInfosWithCompletionHandler not available on tvOS
    #if os(tvOS)
    public func allContactsUserInfo(completionHandler: (users: [CKDiscoveredUserInfo]!) -> Void, errorHandler:((error:NSError) -> Void)? = nil) {
        assert(true, "Sorry, discoverAllContactUserInfosWithCompletionHandler does not work on tvOS")
    }
    #else
    /**
    Who or our contacts is using the same app (will get a system popup requesting permitions)

    - parameter completionHandler: The function that will be called with an array of CKDiscoveredUserInfo objects
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func allContactsUserInfo(completionHandler: (users: [CKDiscoveredUserInfo]!) -> Void, errorHandler:((error:NSError) -> Void)? = nil) {
        container.discoverAllContactUserInfosWithCompletionHandler({users, error in
            self.handleCallback(error, errorHandler:errorHandler, completionHandler: {
                if let returnData = users {
                    if returnData.count == 0 {
                        if let restoreData = self.restoreData("allContactsUserInfo.bak") as? [CKDiscoveredUserInfo] {
                            completionHandler(users:restoreData)
                        } else {
                            completionHandler(users:returnData)
                        }
                    } else {
                        self.backupData(returnData, toFile: "allContactsUserInfo.bak")
                        completionHandler(users:returnData)
                    }

                } else {
                    if let restoreData = self.restoreData("allContactsUserInfo.bak") as? [CKDiscoveredUserInfo] {
                        completionHandler(users:restoreData)
                    }
                }
            })
        })
    }
    #endif

    
    
    
    
    
    
    // ------------------------------------------------------------------------
    // MARK: - Reading and writing to file
    // ------------------------------------------------------------------------
    
    
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
    // MARK: - Data methods - CRUD
    // ------------------------------------------------------------------------

    /**
    Get an Item for a recordId

    - parameter recordId: The CloudKit record id that we want to get.
    - parameter completionHandler: The function that will be called with the object that we aksed for
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func getItem(recordId: String, completionHandler: (result: EVCloudKitDataObject) -> Void, errorHandler:((error: NSError) -> Void)? = nil) -> CKFetchRecordsOperation {
        let operation = CKFetchRecordsOperation(recordIDs: [CKRecordID(recordName: recordId)])
        operation.qualityOfService = .UserInitiated
        operation.queuePriority = .VeryHigh
        operation.perRecordCompletionBlock = { record, id, error in
            if let parsed = self.fromCKRecord(record) {
                completionHandler(result: parsed);
            } else {
                if let handler = errorHandler {
                    let error = NSError(domain: "EVCloudKitDao", code: 1, userInfo:nil)
                    handler(error: error)
                }
            }
        }
        database.addOperation(operation)
        return operation
    }
    
    /**
     Get multiple Items for their recordIds
     - parameter recordIds: The CloudKit record ids that we want to get.
     - parameter completionHandler: The function that will be called with the objects that we aksed for
     - parameter errorHandler: The function that will be called when there was an error
     :return: No return value
     */
    public func getItems(recordIds: [String], completionHandler: (results: [EVCloudKitDataObject]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) -> CKFetchRecordsOperation {
        let operation = CKFetchRecordsOperation(recordIDs: recordIds.map({CKRecordID(recordName: $0)}))
        operation.qualityOfService = .UserInitiated
        operation.queuePriority = .VeryHigh
        operation.fetchRecordsCompletionBlock = { result, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                let r: [EVCloudKitDataObject] = result!.map({ (key, value) in self.fromCKRecord(value)!})
                completionHandler(results: r)
            })
        }
        database.addOperation(operation)
        return operation
    }

    /**
    Save an item. Relate to other objects with property CKReference or save an asset using CKAsset

    - parameter item: object that we want to save
    - parameter completionHandler: The function that will be called with a CKRecord representation of the saved object
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func saveItem(item: EVCloudKitDataObject, completionHandler: (record: CKRecord) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        let theRecord = self.toCKRecord(item)
        database.saveRecord(theRecord, completionHandler: { record, error in
            self.handleCallback(self.nilNotAllowed(error, value: record), errorHandler: errorHandler, completionHandler: {
                completionHandler(record: record!);
            })
        })
    }

    /**
     Save an array of items.
     
     - parameter items:             the items to save
     - parameter completionHandler: The function that will be called with a CKRecord representation of the saved object
     - parameter errorHandler:      The function that will be called when there was an error
     :return: No return value
     */
    public func saveItems(items: [EVCloudKitDataObject], completionHandler: (records: [CKRecord]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) -> CKModifyRecordsOperation {
        let recordsToSave: [CKRecord] = items.map({self.toCKRecord($0)})
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        operation.atomic = false
        operation.database = database
        operation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecordID]?, operationError: NSError?) -> Void in
            self.handleCallback(self.nilNotAllowed(operationError, value: savedRecords), errorHandler: errorHandler, completionHandler: {
                completionHandler(records: savedRecords!);
            })
        }
        operation.start()
        return operation
    }
    
    
    /**
    Delete an Item for a recordId

    - parameter recordId: The CloudKit record id of the record that we want to delete
    - parameter completionHandler: The function that will be called with a record id of the deleted object
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func deleteItem(recordId: String, completionHandler: (recordID: CKRecordID) -> Void, errorHandler:((error: NSError) -> Void)? = nil) {
        database.deleteRecordWithID(CKRecordID(recordName: recordId), completionHandler: {recordID, error in
            self.handleCallback(self.nilNotAllowed(error, value: recordID), errorHandler: errorHandler, completionHandler: {
                completionHandler(recordID: recordID!);
            })
        })
    }

    
    /**
     Delete an array of items.
     
     - parameter items:             the items to save
     - parameter completionHandler: The function that will be called with a CKRecord representation of the saved object
     - parameter errorHandler:      The function that will be called when there was an error
     :return: No return value
     */
    public func deleteItems(items: [EVCloudKitDataObject], completionHandler: (records: [CKRecord]) -> Void, errorHandler:((error: NSError) -> Void)? = nil) -> CKModifyRecordsOperation {
        let recordsToDelete: [CKRecordID] = items.map({$0.recordID})
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsToDelete)
        operation.atomic = false
        operation.database = database
        operation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecordID]?, operationError: NSError?) -> Void in
            self.handleCallback(self.nilNotAllowed(operationError, value: savedRecords), errorHandler: errorHandler, completionHandler: {
                completionHandler(records: savedRecords!);
            })
        }
        operation.start()
        return operation
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - Data methods - Query
    // ------------------------------------------------------------------------

    /**
    Query a record type

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter completionHandler: The function that will be called with an array of the requested objects.
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation {
       let recordType = EVReflection.swiftStringFromClass(type)
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = orderBy.sortDescriptors()
        return queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /**
    Query child object of a recordType

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter referenceRecordName: The CloudKit record id that we are looking for
    - parameter referenceField: The name of the field that we will query for the referenceRecordName
    - parameter completionHandler: The function that will be called with an array of the requested objects
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, referenceRecordName: String, referenceField: String, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation {
        let recordType = EVReflection.swiftStringFromClass(type)
        let parentId = CKRecordID(recordName: referenceRecordName)
        let parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "%K == %@", referenceField ,parent))
        query.sortDescriptors = orderBy.sortDescriptors()
        return queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    
    
    
    
    /**
    Query a recordType with a predicate

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter predicate: The predicate with the filter for our query
    - parameter completionHandler: The function that will be called with an array of the requested objects
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, predicate: NSPredicate, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation{
        let recordType = EVReflection.swiftStringFromClass(type)
        let query: CKQuery = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = orderBy.sortDescriptors()
        return queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /**
    Query a recordType for some tokens

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter tokens: The tokens that we will query for (words seperated by a space)
    - parameter completionHandler: The function that will be called with an array of the requested objects
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func query<T:EVCloudKitDataObject>(type:T, tokens: String, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation {
        let recordType = EVReflection.swiftStringFromClass(type)
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "allTokens TOKENMATCHES[cdl] %@", tokens))
        query.sortDescriptors = orderBy.sortDescriptors()
        return queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /**
    Query a recordType for a location and sort on distance

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter fieldname: The field that contains the location data
    - parameter latitude: The latitude that will be used to query
    - parameter longitude: The longitude that will be used to query
    - parameter distance: The maximum distance to the location that will be returned
    - parameter completionHandler: The function that will be called with an array of the requested objects
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func query<T: EVCloudKitDataObject>(type: T, fieldname: String, latitude: Double, longitude: Double, distance: Int ,completionHandler: (results: [T], isFinished: Bool) -> Bool, errorHandler:((error: NSError) -> Void)? = nil) -> CKQueryOperation{
        let recordType: String = EVReflection.swiftStringFromClass(type)
        let location: CLLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        let predecate: NSPredicate =  NSPredicate(format: "distanceToLocation:fromLocation:(%K, %@) < %@", [fieldname, location, distance])
        let query = CKQuery(recordType:recordType, predicate:predecate)
        query.sortDescriptors = [CKLocationSortDescriptor(key: fieldname, relativeLocation: location)]
        return queryRecords(type, query:query, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    // ------------------------------------------------------------------------
    // MARK: - Data methods - Subscriptions
    // ------------------------------------------------------------------------

    /**
    Subscribe for modifications to a recordType and predicate (and register it under filterId)

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter predicate: The predicate with the filter for our subscription
    - parameter configureNotificationInfo: The function that will be called with the CKNotificationInfo object so that we can configure it
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func subscribe(type: EVCloudKitDataObject, predicate: NSPredicate, filterId: String, configureNotificationInfo:((notificationInfo: CKNotificationInfo ) -> Void)? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        let recordType = EVReflection.swiftStringFromClass(type)
        let key = "type_\(recordType)_id_\(filterId)"

        let createSubscription = { () -> () in
            let subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID:key, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
            subscription.notificationInfo = CKNotificationInfo()
// tvOS does not have visible remote notifications. This property is not available.
#if os(tvOS)
#else
            subscription.notificationInfo!.shouldSendContentAvailable = true
#endif
            
            if let configure = configureNotificationInfo {
                configure(notificationInfo: subscription.notificationInfo!)
            }
            self.database.saveSubscription(subscription, completionHandler: { savedSubscription, error in
                self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                    EVLog("Subscription created for key \(key)")
                })
            })
        }

        // If the subscription exists and the predicate is the same, then we don't need to create this subscrioption. If the predicate is difrent, then we first need to delete the old
        database.fetchSubscriptionWithID(key, completionHandler: { (subscription, error) in
            if let deleteSubscription:CKSubscription = subscription {
                if predicate.predicateFormat != deleteSubscription.predicate?.predicateFormat {
                    self.unsubscribeWithoutTest(key, completionHandler:createSubscription, errorHandler: errorHandler)
                }
            } else {
                createSubscription()
            }
        })
    }
    
    

    /**
    Unsubscribe for modifications to a recordType and predicate (and unregister is under filterId)

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter filterId: The id of the filter that you want to unsubscibe
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func unsubscribe(type: EVCloudKitDataObject, filterId: String, completionHandler:(()->())? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        let recordType = EVReflection.swiftStringFromClass(type)
        let key = "type_\(recordType)_id_\(filterId)"

        database.fetchSubscriptionWithID(key, completionHandler: { (subscription, error) in
            if  subscription != nil {
                self.unsubscribeWithoutTest(key, completionHandler: completionHandler, errorHandler: errorHandler)
            } else {
                if let handler = completionHandler {
                    handler()
                }
            }
        })
    }
    
    /**
    Unsubscribe for modifications to a recordType while assuming the subscription exists and predicate (and unregister is under filterId)
    
    - parameter type: An instance of the Object for what we want to query the record type
    - parameter filterId: The id of the filter that you want to unsubscibe
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    private func unsubscribeWithoutTest(key: String, completionHandler:(()->())? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        let modifyOperation = CKModifySubscriptionsOperation()
        modifyOperation.subscriptionIDsToDelete = [key]
        modifyOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptions, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                if let handler = completionHandler {
                    handler()
                }
                EVLog("Subscription with id \(key) was removed : \(savedSubscriptions?.description)")
            })
        }
        self.database.addOperation(modifyOperation)
    }
    
    /**
    Subscribe for modifications to child object of a record

    - parameter type: An instance of the Object for what we want to subscribe for
    - parameter referenceRecordName: The CloudKit record id that we are looking for
    - parameter referenceField: The name of the field that we will query for the referenceRecordName
    - parameter configureNotificationInfo: The function that will be called with the CKNotificationInfo object so that we can configure it
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func subscribe(type: EVCloudKitDataObject, referenceRecordName: String, referenceField: String, configureNotificationInfo:((notificationInfo: CKNotificationInfo) -> Void)? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        let parentId = CKRecordID(recordName: referenceRecordName)
        let parent = CKReference(recordID: parentId, action: CKReferenceAction.None)
        let predicate = NSPredicate(format: "%K == %@", referenceField ,parent)
        subscribe(type, predicate:predicate, filterId: "reference_\(referenceField)_\(referenceRecordName)",configureNotificationInfo: configureNotificationInfo ,errorHandler: errorHandler)
    }

    /**
    Unsubscribe for modifications to a recordType with a reference to the user

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter referenceRecordName: The CloudKit record id that we are looking for
    - parameter referenceField: The name of the field that we will query for the referenceRecordName
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func unsubscribe(type: EVCloudKitDataObject, referenceRecordName: String, referenceField: String, completionHandler:(()->())? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        unsubscribe(type, filterId:"reference_\(referenceField)_\(referenceRecordName)", completionHandler:completionHandler, errorHandler: errorHandler)
    }

    /**
    Subscribe for modifications to a recordType

    - parameter type: An instance of the Object for what we want to subscribe for
    - parameter configureNotificationInfo: The function that will be called with the CKNotificationInfo object so that we can configure it
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func subscribe(type: EVCloudKitDataObject, configureNotificationInfo:((notificationInfo: CKNotificationInfo) -> Void)? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        subscribe(type, predicate: NSPredicate(value: true), filterId: "all", configureNotificationInfo: configureNotificationInfo ,errorHandler: errorHandler)
    }

    /**
    Unsubscribe for modifications to a recordType

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    public func unsubscribe(type: EVCloudKitDataObject, completionHandler:(()->())? = nil, errorHandler:((error: NSError) -> Void)? = nil) {
        unsubscribe(type, filterId:"all", completionHandler:completionHandler, errorHandler:errorHandler)
    }

    /**
    Unsubscribe for all modifications

    - parameter errorHandler: The function that will be called when there was an error
    - parameter completionHandler: The function that will be called with a number which is the count of messages removed.
    :return: No return value
    */
    public func unsubscribeAll(completionHandler:(subscriptionCount: Int) -> Void , errorHandler:((error: NSError) -> Void)? = nil) {
        database.fetchAllSubscriptionsWithCompletionHandler({subscriptions, error in
            self.handleCallback(self.nilNotAllowed(error, value: subscriptions), errorHandler: errorHandler, completionHandler: {
                for subscriptionObject in subscriptions! {
                    if let  subscription: CKSubscription = subscriptionObject {
                        self.database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {subscriptionId, error in
                            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                                EVLog("Subscription with id \(subscriptionId) was removed : \(subscription.description)")
                            })
                        })
                    }
                }
                completionHandler(subscriptionCount: subscriptions!.count)
            })
        })
    }

    // ------------------------------------------------------------------------
    // MARK: - Handling remote notifications
    // ------------------------------------------------------------------------

    /**
    Method for processing remote notifications. Call this from the AppDelegate didReceiveRemoteNotification

    - parameter userInfo: CKNotification dictionary
    - parameter executeIfNonQuery: Function that will be executed if the notification was not for a subscription
    - parameter inserted: Executed if the notification was for an inserted object
    - parameter updated: Executed if the notification was for an updated object
    - parameter deleted: Executed if the notification was for an deleted object
    - parameter completed: Executed if all notifications are processed
    :return: No return value
    */
    public func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject], executeIfNonQuery:() -> Void, inserted:(recordID:String, item: EVCloudKitDataObject) -> Void, updated:(recordID:String, item: EVCloudKitDataObject) -> Void, deleted:(recordId: String) -> Void, completed:()-> Void) {
        var converedUserInfo:[String:NSObject] = [String:NSObject]()
        for (key, value) in userInfo {
            if let setValue = value as? NSObject {
                converedUserInfo[key as! String] = setValue                
            }
        }

        let cloudNotification = CKNotification(fromRemoteNotificationDictionary: converedUserInfo)
        //EVLog("Notification alert body : \(cloudNotification.alertBody)")

        // Handle CloudKit subscription notifications
        var recordID: CKRecordID?
        if cloudNotification.notificationType == CKNotificationType.Query {
            if let queryNotification = cloudNotification as? CKQueryNotification {
                if queryNotification.recordID != nil {
                    recordID = queryNotification.recordID
                    EVLog("recordID of notified record = \(recordID)")
                    if queryNotification.queryNotificationReason == .RecordDeleted {
                        deleted(recordId: recordID!.recordName)
                    } else {
                        // Notification could be for pulbic and private db. Errors are ignored
                        getItem(recordID!.recordName, completionHandler: { item in
                            EVLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                            EVReflection.logObject(item)
                            if queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordCreated {
                                inserted(recordID: recordID!.recordName, item: item)
                            } else if queryNotification.queryNotificationReason == CKQueryNotificationReason.RecordUpdated {
                                updated(recordID: recordID!.recordName, item: item)
                            }
                            }, errorHandler: { error in
                                EVLog("ERROR: getItem for notification.\n\(error.description)")
                        })
                    }
                } else {
                    EVLog("WARNING: CKQueryNotification without a recordID.\n===>userInfo = \(userInfo)\nnotification = \(cloudNotification)")
                }
            } else {
                executeIfNonQuery()
                EVLog("WARNING: notificationType is Query but the notification is not a CKQueryNotification.\n===>userInfo = \(userInfo)\nnotification = \(cloudNotification)")
            }
        } else {
            executeIfNonQuery()
            EVLog("WARNING: The retrieved notification is not a CloudKit query notification.\n===>userInfo = \(userInfo)\nnotification = \(cloudNotification)")
        }
        fetchChangeNotifications(recordID, inserted: inserted , updated: updated, deleted: deleted, completed:completed)
    }

    /**
    Method for pulling all subscription notifications.
    Call this in the AppDelegate didFinishLaunchingWithOptions to handle not yet handled notifications.
    Also call this in the AppDelegate didReceiveRemoteNotification because not all notifications will be pushed if there are multiple.

    - parameter inserted: Executed if the notification was for an inserted object
    - parameter updated: Executed if the notification was for an updated object
    - parameter deleted: Executed if the notification was for an deleted object
    - parameter completed: Executed if all notifications are processed
    :return: No return value
    */
    public func fetchChangeNotifications(skipRecordID: CKRecordID?, inserted:(recordID:String, item: EVCloudKitDataObject) -> Void, updated:(recordID: String, item: EVCloudKitDataObject) -> Void, deleted:(recordId: String) -> Void, completed:()-> Void) {
        var array: [CKNotificationID] = [CKNotificationID]()
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: self.previousChangeToken)
        operation.notificationChangedBlock = { notification in
            if notification.notificationType == .Query  {
                if let queryNotification = notification as? CKQueryNotification {
                    array.append(notification.notificationID!)
                    if skipRecordID != nil && skipRecordID?.recordName != queryNotification.recordID?.recordName {
                        if queryNotification.queryNotificationReason == .RecordDeleted {
                            deleted(recordId: queryNotification.recordID!.recordName)
                        } else {
                            self.getItem(queryNotification.recordID!.recordName, completionHandler: { item in
                                EVLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                                EVReflection.logObject(item)
                                if queryNotification.queryNotificationReason == .RecordCreated {
                                    inserted(recordID: queryNotification.recordID!.recordName, item: item)
                                } else if queryNotification.queryNotificationReason == .RecordUpdated {
                                    updated(recordID: queryNotification.recordID!.recordName, item: item)
                                }
                            }, errorHandler: { error in
                                EVLog("ERROR: getItem for change notification.\n\(error.description)")
                            })
                        }
                    }
                }
            }
        }
        operation.fetchNotificationChangesCompletionBlock = { changetoken, error in
            let op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: array)
            op.start()
            EVLog("changetoken = \(changetoken)")
            self.previousChangeToken = changetoken

            if operation.moreComing  {
                self.fetchChangeNotifications(skipRecordID, inserted: inserted, updated: updated, deleted: deleted, completed:completed)
            } else {
                completed()
            }
        }
        operation.start()
    }

    /**
    Property for saving the changetoken in the userdefaults
    */
    private var previousChangeToken: CKServerChangeToken? {
        get {
            
            let encodedObjectData = NSUserDefaults.standardUserDefaults().objectForKey("\(container.containerIdentifier)_lastFetchNotificationId") as? NSData
            var decodedData: CKServerChangeToken? = nil
            if encodedObjectData != nil {
                decodedData = NSKeyedUnarchiver.unarchiveObjectWithData(encodedObjectData!) as? CKServerChangeToken
            }
            return decodedData
        }
        set(newToken) {
            if newToken != nil {
                NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(newToken!), forKey:"\(container.containerIdentifier)_lastFetchNotificationId")
            }
        }
    }

    /**
    Setting the application badge count to a specific number
    - parameter count: The number for the badge
    */
    public func setBadgeCounter(count: Int) {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: count)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            func handleError(error: NSError) -> Void {
                EVLog("Error: could not reset badge: \n\(error)")
            }
            self.handleCallback(error, errorHandler: handleError, completionHandler: {
                #if os(iOS)
                    UIApplication.sharedApplication().applicationIconBadgeNumber = count
                #elseif os(OSX)
                    //TODO: Set badge?
                    NSLog("How to set the badge on OSX?")
                #endif
                })
        }
        container.addOperation(badgeResetOperation)
    }

    // ------------------------------------------------------------------------
    // MARK: - Converting a CKRecord from and to an object
    // ------------------------------------------------------------------------

    /**
    Convert a CKrecord to an object

    - parameter record: The CKRecord that will be converted to an object
    :return: The object that is created from the record
    */
    public func fromCKRecord(record: CKRecord!) -> EVCloudKitDataObject? {
        if record == nil {
            return nil
        }
        if let theObject = EVReflection.fromDictionary(CKRecordToDictionary(record), anyobjectTypeString: record.recordType) as? EVCloudKitDataObject {
            theObject.recordID = record.recordID
            theObject.recordType = record.recordType
            theObject.creationDate = record.creationDate ?? NSDate()
            theObject.creatorUserRecordID = record.creatorUserRecordID
            theObject.modificationDate = record.modificationDate ?? NSDate()
            theObject.lastModifiedUserRecordID = record.lastModifiedUserRecordID
            theObject.recordChangeTag = record.recordChangeTag

            let data = NSMutableData()
            let coder = NSKeyedArchiver(forWritingWithMutableData: data)
            record.encodeSystemFieldsWithCoder(coder)
            theObject.encodedSystemFields = data
            coder.finishEncoding()
            return theObject
        }
        return nil
    }

    /**
    Convert an object to a CKRecord

    - parameter theObject: The object that will be converted to a CKRecord
    :return: The CKRecord that is created from theObject
    */
    public func toCKRecord(theObject: EVCloudKitDataObject) -> CKRecord {
        var record: CKRecord!
        if theObject.encodedSystemFields != nil {
            let coder = NSKeyedUnarchiver(forReadingWithData: theObject.encodedSystemFields!)
            record = CKRecord(coder: coder)
            coder.finishDecoding()
        }
        if record == nil {
            record = CKRecord(recordType: EVReflection.swiftStringFromClass(theObject), recordID: theObject.recordID)
        }
        let (fromDict, _) = EVReflection.toDictionary(theObject)
        dictToCKRecord(record, dict: fromDict)
        
        return record
    }

    /**
     Put a dictionary recursively in a CKRecord
     
     - parameter record: the record
     - parameter dict:   the dictionary
     - parameter root:   used for expanding the property name
     */
    private func dictToCKRecord(record: CKRecord, dict: NSDictionary, root:String = "") {
        for (key, value) in dict {
            if !(["recordID", "recordType", "creationDate", "creatorUserRecordID", "modificationDate", "lastModifiedUserRecordID", "recordChangeTag", "encodedSystemFields"]).contains(key as! String) {
                if value is NSNull {
                    // record.setValue(nil, forKey: key) // Swift can not set a value on a nulable type.
                } else if let dict = value as? NSDictionary {
                    dictToCKRecord(record, dict: dict, root: "\(root)\(key as! String)__")
                } else if key as! String != "recordID" {
                    record.setValue(value, forKey: "\(root)\(key as! String)")
                }
            }
        }
    }
    
    /**
    Convert CKRecord to dictionary

    - parameter record: The CKRecord that will be converted to a dictionary
    :return: The dictionary that is created from the record
    */
    public func CKRecordToDictionary(record: CKRecord) -> NSDictionary {
        let dictionary = NSMutableDictionary()
        for key in record.allKeys() {
            if let value = record.objectForKey(key) {
                var path:[String] = key.componentsSeparatedByString("__")
                if path.count == 1 {
                    dictionary.setObject(value, forKey: key)
                } else {
                    var tempDict = dictionary
                    var tempKey = key
                    let lastKey = path[path.count - 1]
                    path.removeLast()
                    for item in path {
                        tempKey = item
                        if tempDict[tempKey] == nil {
                            tempDict.setObject(NSMutableDictionary(), forKey: tempKey)
                        }
                        tempDict = (tempDict[tempKey] as? NSMutableDictionary) ?? NSMutableDictionary()
                    }
                    tempDict.setObject(value, forKey: lastKey)
               }
            }
        }
        return dictionary
    }
}





