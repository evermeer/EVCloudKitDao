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
open class EVCloudKitDao {

    // ------------------------------------------------------------------------
    // MARK: - For getting the various instances
    // ------------------------------------------------------------------------

    /**
    Singleton access to EVCloudKitDao public database that can be called from Swift

    :return: The EVCLoudKitDao object
    */
    open class var publicDB: EVCloudKitDao {
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
    open class func sharedPublicDB() -> EVCloudKitDao {
        return publicDB
    }

    /**
    Singleton access to EVCloudKitDao private database that can be called from Swift

    :return: The EVCLoudKitDao object
    */
    open class var privateDB: EVCloudKitDao {
        struct Static { static let instance: EVCloudKitDao = EVCloudKitDao() }
        Static.instance.isType = .isPrivate
        Static.instance.database = Static.instance.container.privateCloudDatabase
        return Static.instance
    }

    /**
    Singleton access to EVCloudKitDao private database that can be called from Objective C

    :return: The EVCLoudKitDao object
    */
    open class func sharedPrivateDB() -> EVCloudKitDao {
        return privateDB
    }

    /**
    Singleton acces to the wrapper class with the dictionaries with public and private containers.

    :return: The container wrapper class
    */
    fileprivate class var containerWrapperInstance: DaoContainerWrapper {
        struct Static { static var instance: DaoContainerWrapper = DaoContainerWrapper()}
        return Static.instance
    }

    /**
    Singleton acces to a specific named public container
    - parameter containterIdentifier: The identifier of the public container that you want to use.

    :return: The public container for the identifier.
    */
    open class func publicDBForContainer(_ containterIdentifier: String) -> EVCloudKitDao {
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
    open class func privateDBForContainer(_ containterIdentifier: String) -> EVCloudKitDao {
        if let containerInstance = containerWrapperInstance.privateContainers[containterIdentifier] {
            return containerInstance
        }
        let dao = EVCloudKitDao(containerIdentifier: containterIdentifier)
        dao.isType = .isPrivate
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
    fileprivate var container: CKContainer!


    /**
    Access to the public database

    :return: The public database
    */
    fileprivate var database: CKDatabase!

    /**
    The iClout account status of the current user

    :return: The account status of the current user
    */
    open var accountStatus: CKAccountStatus?

    /**
    The iCloud account information of the current user

    :return: The account information of the current user
    */
    open var activeUser: AnyObject!  // CKDiscoverUserInfo or CKUserIdentity


    /**
    For regestering if this class is for the public or the private database

    :return: Public or private
    */
    open var isType: InstanceType = .isPublic

    // Fast access to the file directory
    fileprivate var fileDirectory: NSString!
    // Fast access to the filemanager
    fileprivate var filemanager: FileManager!
    // Fast access to the queue
    fileprivate var ioQueue: DispatchQueue!

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
    open func initializeDatabase(_ containerIdentifier: String? = nil) {
        let pathDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if pathDir.count > 0 {
            fileDirectory = pathDir[0] as NSString!
        } else {
            fileDirectory = ""
        }
        filemanager = FileManager.default
        ioQueue = DispatchQueue(label: "NL.EVICT.CloudKit.ioQueue", attributes: []) as DispatchQueue

        if let identifier = containerIdentifier {
            container = CKContainer(identifier: identifier)
        } else {
            container = CKContainer.default()
        }
        if self.isType == .isPublic {
            database = container.publicCloudDatabase
        } else {
            database = container.privateCloudDatabase
        }

        let sema = DispatchSemaphore(value: 0)
        container.accountStatus(completionHandler: {status, error in
            if error != nil {
                EVLog("Error: Initialising EVCloudKitDao - accountStatusWithCompletionHandler.\n\(error!.localizedDescription)")
            } else {
                self.accountStatus = status
            }
            EVLog("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
            sema.signal()
        })
        let _ = sema.wait(timeout: DispatchTime.distantFuture)
        EVLog("Container identifier = \(container.containerIdentifier.debugDescription)")
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
    internal func handleCallback(_ error: Error?, errorHandler: ((_ error: Error) -> Void)? = nil, completionHandler: () -> Void) {
        if error != nil {
            EVLog("Error: \(error?._code ?? 0) = \(error?.localizedDescription.debugDescription ?? "")")
            if let handler = errorHandler {
                handler(error!)
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
    internal func nilNotAllowed(_ error: Error?, value: AnyObject?) -> Error? {
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
    open static func handleCloudKitErrorAs(_ error: Error?, retryAttempt: Double = 1) -> HandleCloudKitErrorAs {
        // There is no error
        if error == nil {
            return .success
        }

        // Or if there is a retry delay specified in the error, then use that.
        if let userInfo = error?._userInfo as? NSDictionary {
            if let retry = userInfo[CKErrorRetryAfterKey] as? NSNumber {
                let seconds = Double(retry)
                NSLog("Debug: Should retry in \(seconds) seconds. \(error?.localizedDescription ?? "")")
                return .retry(afterSeconds: seconds)
            }
        }

        let errorCode: CKError = CKError(_nsError: error! as NSError)
        switch errorCode.code {
        case .notAuthenticated, .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .resultsTruncated:
            // Probably handled by the userInfo[CKErrorRetryAfterKey] but if not, then:
            // Use an exponential retry delay which maxes out at half an hour.
            var seconds = Double(pow(2, Double(retryAttempt)))
            if seconds > 1800 {
                seconds = 1800
            }
            NSLog("Debug: Should retry in \(seconds) seconds. \(error?.localizedDescription ?? "")")
            return .retry(afterSeconds: seconds)
        case .unknownItem, .invalidArguments, .incompatibleVersion, .badContainer, .missingEntitlement, .permissionFailure, .badDatabase, .assetFileNotFound, .operationCancelled, .assetFileModified, .batchRequestFailed, .zoneNotFound, .userDeletedZone, .internalError, .serverRejectedRequest, .constraintViolation:
            NSLog("Error: \(error?.localizedDescription ?? "")")
            return .fail
        case .quotaExceeded, .limitExceeded:
            NSLog("Warning: \(error?.localizedDescription ?? "")")
            return .fail
        case .changeTokenExpired,  .serverRecordChanged:
            NSLog("Info: \(error?.localizedDescription ?? "")")
            return .recoverableError
        default:
            NSLog("Error: \(error?.localizedDescription ?? "")") //New error introduced in iOS...?
            return .fail
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
    @discardableResult
  internal func queryRecords<T: CKDataObject>(_ type: T, query: CKQuery, completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
        if !(query.sortDescriptors != nil) {
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        let operation = CKQueryOperation(query: query)
        operation.qualityOfService = .userInitiated
        operation.queuePriority = .veryHigh
        var results = [T]()
        operation.recordFetchedBlock = { record in
            if let parsed = record.toDataObject() as? T {
                results.append(parsed)
            }
        }

    operation.queryCompletionBlock = { cursor, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
              if completionHandler(results, cursor == nil) {
                    if cursor != nil {
                        self.queryRecords(cursor!, continueWithResults: results, completionHandler: completionHandler, errorHandler: errorHandler)
                    }
                }
            })
        } as ((CKQueryCursor?, Error?) -> Void)
        operation.resultsLimit = CKQueryOperationMaximumResults
        database.add(operation)
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
    @discardableResult
    fileprivate func queryRecords<T: CKDataObject>(_ cursor: CKQueryCursor, continueWithResults: [T], completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
        var results = continueWithResults
        let operation = CKQueryOperation(cursor: cursor)
        operation.qualityOfService = .userInitiated
        operation.recordFetchedBlock = { record in
            if let parsed = record.toDataObject() as? T {
                results.append(parsed)
            }
        }

        operation.queryCompletionBlock = { cursor, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                if completionHandler(results, cursor == nil) {
                    if cursor != nil {
                        self.queryRecords(cursor!, continueWithResults: results, completionHandler: completionHandler, errorHandler: errorHandler)
                    }
                }
            })
        }
        operation.resultsLimit = CKQueryOperationMaximumResults
        database.add(operation)
        return operation
    }



    /**
    Helper method for getting a reference (with delete action)

    - parameter recordId: The record id that will be converted to a CKReference
    :return: The CKReference that is created from the recordId
    */
    open func referenceForId(_ recordId: String) -> CKReference {
        return CKReference(recordID: CKRecordID(recordName: recordId), action: CKReferenceAction.deleteSelf)
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
    open func createRecordTypes(_ types: [CKDataObject]) {
        for item in types {
            let sema = DispatchSemaphore(value: 0)
            saveItem(item, completionHandler: {record in
                    EVLog("saveItem \(item): \(record.recordID.recordName)")
                    sema.signal()
                }, errorHandler: {error in
                    EVLog("ERROR: saveItem\n\(error.localizedDescription)")
                    sema.signal()
                })
            let _ = sema.wait(timeout: DispatchTime.distantFuture)
        }
        NSException(name: NSExceptionName(rawValue: "RunOnlyOnce"), reason: "Call this method only once. Only here for easy debugging reasons for fast generation of the iCloud recordTypes. Sorry for the hard crash. Now disable the call to this method in the AppDelegate!  Then go to the iCloud dashboard and make all metadata for each recordType queryable and sortable!", userInfo: nil).raise()
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
    open func requestDiscoverabilityPermission(_ completionHandler: @escaping (_ granted: Bool) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
        container.requestApplicationPermission(CKApplicationPermissions.userDiscoverability, completionHandler: { (status: CKApplicationPermissionStatus, error: Error?) -> Void in

            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                completionHandler(status == CKApplicationPermissionStatus.granted)
            })
        } )
    }

    /**
    Get the info of the current user

    - parameter completionHandler: The function that will be called with the CKDiscoveredUserInfo object
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func discoverUserInfo(_ completionHandler: @escaping (_ user: AnyObject) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
        container.fetchUserRecordID(completionHandler: {recordID, error in
            self.handleCallback(self.nilNotAllowed(error as Error?, value: recordID), errorHandler: errorHandler, completionHandler: {
                if #available(iOS 10.0, *, tvOS 10.0, *, OSX 10.12, *) {
                    self.container.discoverUserIdentity(withUserRecordID: recordID!) { (user, error) in
                        self.handleCallback(self.nilNotAllowed(error as Error?, value: user), errorHandler: errorHandler, completionHandler: {
                            self.activeUser = user
                            completionHandler(user!) // CKUserIdentity
                        })
                    }
                } else {
                    self.container.discoverUserInfo(withUserRecordID: recordID!, completionHandler: { user, error in
                        self.handleCallback(self.nilNotAllowed(error as Error?, value: user), errorHandler: errorHandler, completionHandler: {
                            self.activeUser = user
                            completionHandler(user!) // CKDiscoverUserInfo
                        })
                    })
                }
            })
        })
    }

    // discoverAllContactUserInfosWithCompletionHandler not available on tvOS
    #if os(tvOS)
    public func allContactsUserInfo(completionHandler: (_ users: [CKDiscoveredUserInfo]?) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
        assert(true, "Sorry, discoverAllContactUserInfosWithCompletionHandler does not work on tvOS")
    }
    #else
    /**
    Who or our contacts is using the same app (will get a system popup requesting permitions)

    - parameter completionHandler: The function that will be called with an array of CKDiscoveredUserInfo objects
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func allContactsUserInfo(_ completionHandler: @escaping (_ users: [AnyObject]?) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
		if #available(iOS 10.0, *, tvOS 10.0, *, OSX 10.12, *) {
            container.discoverAllIdentities { (users, error) in
                self.handleCallback(error as Error?, errorHandler:errorHandler, completionHandler: {
                    if let returnData = users {
                        if returnData.count == 0 {
                            if let restoreData = self.restoreData("allContactsUserInfo10.bak") as? [CKUserIdentity] {
                                completionHandler(restoreData)
                            } else {
                                completionHandler(returnData)
                            }
                        } else {
                            self.backupData(returnData as AnyObject, toFile: "allContactsUserInfo10.bak")
                            completionHandler(returnData)
                        }
                        
                    } else {
                        if let restoreData = self.restoreData("allContactsUserInfo10.bak") as? [CKUserIdentity] {
                            completionHandler(restoreData)
                        }
                    }
                })
            }
        } else {
            container.discoverAllContactUserInfos(completionHandler: {users, error in
                self.handleCallback(error as Error?, errorHandler:errorHandler, completionHandler: {
                    if let returnData = users {
                        if returnData.count == 0 {
                            if let restoreData = self.restoreData("allContactsUserInfo.bak") as? [CKDiscoveredUserInfo] {
                                completionHandler(restoreData)
                            } else {
                                completionHandler(returnData)
                            }
                        } else {
                            self.backupData(returnData as AnyObject, toFile: "allContactsUserInfo.bak")
                            completionHandler(returnData)
                        }
                        
                    } else {
                        if let restoreData = self.restoreData("allContactsUserInfo.bak") as? [CKDiscoveredUserInfo] {
                            completionHandler(restoreData)
                        }
                    }
                })
            })
        }
    }
    #endif

    // ------------------------------------------------------------------------
    // MARK: - Reading and writing to file
    // ------------------------------------------------------------------------


    /**
     Write data to a file

     - parameter data: The data that will be written to the file (Needs to implement NSCoding like the CKDataObject)
     - parameter toFile: The file that will be written to
     */
    open func backupData(_ data: AnyObject, toFile: String) {
        let filePath = fileDirectory.appendingPathComponent(toFile)
        ioQueue.sync {
            NSKeyedArchiver.archiveRootObject(data, toFile: filePath)
            addSkipBackupAttributeToItemAtPath(filePath)
            EVLog("Data is written to \(filePath))")
        }
    }

    /**
     Read a backup file and return it as an unarchived object

     - parameter fromFile: The file that will be read and parsed to objects
     */
    open func restoreData(_ fromFile: String) -> AnyObject? {
        let filePath = fileDirectory.appendingPathComponent(fromFile)
        var result: AnyObject? = nil
        ioQueue.sync {
            if self.filemanager.fileExists(atPath: filePath) {
                result = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as AnyObject?
                EVLog("Data is restored from \(filePath))")
            }
        }
        return result
    }

    /**
     Remove a backup file

     - parameter file: The file that will be removed from the backup folder (EVCloudDataBackup)
     */
    open func removeBackup(_ file: String) {
        let filePath = fileDirectory.appendingPathComponent(file)
        ioQueue.sync {
            if self.filemanager.fileExists(atPath: filePath) {
                do {
                    try self.filemanager.removeItem(atPath: filePath)
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
    @discardableResult
    open func getItem(_ recordId: String, completionHandler: @escaping (_ result: CKDataObject) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) -> CKFetchRecordsOperation {
        let operation = CKFetchRecordsOperation(recordIDs: [CKRecordID(recordName: recordId)])
        operation.qualityOfService = .userInitiated
        operation.queuePriority = .veryHigh
        operation.perRecordCompletionBlock = { record, id, error in
            if let parsed = record?.toDataObject() {
                completionHandler(parsed)
            } else {
                if let handler = errorHandler {
                    let error = NSError(domain: "EVCloudKitDao", code: 1, userInfo:nil)
                    handler(error)
                }
            }
        }
        database.add(operation)
        return operation
    }

    /**
     Get multiple Items for their recordIds
     - parameter recordIds: The CloudKit record ids that we want to get.
     - parameter completionHandler: The function that will be called with the objects that we aksed for
     - parameter errorHandler: The function that will be called when there was an error
     :return: No return value
     */
    @discardableResult
    open func getItems(_ recordIds: [String], completionHandler: @escaping (_ results: [CKDataObject]) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) -> CKFetchRecordsOperation {
        let operation = CKFetchRecordsOperation(recordIDs: recordIds.map({CKRecordID(recordName: $0)}))
        operation.qualityOfService = .userInitiated
        operation.queuePriority = .veryHigh
        operation.fetchRecordsCompletionBlock = { result, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                let r: [CKDataObject] = result!.map({ (key, value) in value.toDataObject()!})
                completionHandler(r)
            })
        }
        database.add(operation)
        return operation
    }

    /**
    Save an item. Relate to other objects with property CKReference or save an asset using CKAsset

    - parameter item: object that we want to save
    - parameter completionHandler: The function that will be called with a CKRecord representation of the saved object
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func saveItem(_ item: CKDataObject, completionHandler: @escaping (_ record: CKRecord) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
        let theRecord = item.toCKRecord()
        database.save(theRecord, completionHandler: { record, error in
            self.handleCallback(self.nilNotAllowed(error, value: record), errorHandler: errorHandler, completionHandler: {
                completionHandler(record!)
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
    @discardableResult
    open func saveItems(_ items: [CKDataObject], completionHandler: @escaping (_ records: [CKRecord]) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) -> CKModifyRecordsOperation {
        let recordsToSave: [CKRecord] = items.map({$0.toCKRecord()})
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        operation.isAtomic = false
        operation.database = database
        operation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecordID]?, operationError: Error?) -> Void in
            self.handleCallback(self.nilNotAllowed(operationError, value: savedRecords as AnyObject?), errorHandler: errorHandler, completionHandler: {
                completionHandler(savedRecords!)
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
    open func deleteItem(_ recordId: String, completionHandler: @escaping (_ recordID: CKRecordID) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
        database.delete(withRecordID: CKRecordID(recordName: recordId), completionHandler: {recordID, error in
            self.handleCallback(self.nilNotAllowed(error as Error?, value: recordID), errorHandler: errorHandler, completionHandler: {
                completionHandler(recordID!)
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
    @discardableResult
    open func deleteItems(_ items: [CKDataObject], completionHandler: @escaping (_ records: [CKRecord]) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) -> CKModifyRecordsOperation {
        let recordsToDelete: [CKRecordID] = items.map({$0.recordID})
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsToDelete)
        operation.isAtomic = false
        operation.database = database
        operation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecordID]?, operationError: Error?) -> Void in
            self.handleCallback(self.nilNotAllowed(operationError, value: savedRecords as AnyObject?), errorHandler: errorHandler, completionHandler: {
                completionHandler(savedRecords!)
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
    @discardableResult
    open func query<T: CKDataObject>(_ type: T, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
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
    @discardableResult
    open func query<T: CKDataObject>(_ type: T, referenceRecordName: String, referenceField: String, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
        let recordType = EVReflection.swiftStringFromClass(type)
        let parentId = CKRecordID(recordName: referenceRecordName)
        let parent = CKReference(recordID: parentId, action: CKReferenceAction.none)
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "%K == %@", referenceField, parent))
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
    @discardableResult
    open func query<T: CKDataObject>(_ type: T, predicate: NSPredicate, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
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
    @discardableResult
    open func query<T: CKDataObject>(_ type: T, tokens: String, orderBy: OrderBy = Descending(field: "creationDate"), completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
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
    @discardableResult
    open func query<T: CKDataObject>(_ type: T, fieldname: String, latitude: Double, longitude: Double, distance: Int, completionHandler: @escaping (_ results: [T], _ isFinished: Bool) -> Bool, errorHandler:((_ error: Error) -> Void)? = nil) -> CKQueryOperation {
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
    open func subscribe(_ type: CKDataObject, predicate: NSPredicate, filterId: String, configureNotificationInfo:((_ notificationInfo: CKNotificationInfo ) -> Void)? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        let recordType = EVReflection.swiftStringFromClass(type)
        let key = "type_\(recordType)_id_\(filterId)"

        let createSubscription = { () -> () in
            let subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID:key, options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
            subscription.notificationInfo = CKNotificationInfo()
// tvOS does not have visible remote notifications. This property is not available.
#if os(tvOS)
#else
            subscription.notificationInfo!.shouldSendContentAvailable = true
#endif

            if let configure = configureNotificationInfo {
                configure(subscription.notificationInfo!)
            }
            self.database.save(subscription, completionHandler: { savedSubscription, error in
                self.handleCallback(error as Error?, errorHandler: errorHandler, completionHandler: {
                    EVLog("Subscription created for key \(key)")
                })
            })
        }

        // If the subscription exists and the predicate is the same, then we don't need to create this subscrioption. If the predicate is difrent, then we first need to delete the old
        database.fetch(withSubscriptionID: key, completionHandler: { (subscription, error) in
            if let deleteSubscription: CKSubscription = subscription {
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
    open func unsubscribe(_ type: CKDataObject, filterId: String, completionHandler:(()->())? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        let recordType = EVReflection.swiftStringFromClass(type)
        let key = "type_\(recordType)_id_\(filterId)"

        database.fetch(withSubscriptionID: key, completionHandler: { (subscription, error) in
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
    fileprivate func unsubscribeWithoutTest(_ key: String, completionHandler:(()->())? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        let modifyOperation = CKModifySubscriptionsOperation()
        modifyOperation.subscriptionIDsToDelete = [key]
        modifyOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptions, error in
            self.handleCallback(error, errorHandler: errorHandler, completionHandler: {
                if let handler = completionHandler {
                    handler()
                }
                EVLog("Subscription with id \(key) was removed : \(savedSubscriptions?.debugDescription ?? "")")
            })
        }
        self.database.add(modifyOperation)
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
    open func subscribe(_ type: CKDataObject, referenceRecordName: String, referenceField: String, configureNotificationInfo:((_ notificationInfo: CKNotificationInfo) -> Void)? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        let parentId = CKRecordID(recordName: referenceRecordName)
        let parent = CKReference(recordID: parentId, action: CKReferenceAction.none)
        let predicate = NSPredicate(format: "%K == %@", referenceField, parent)
        subscribe(type, predicate:predicate, filterId: "reference_\(referenceField)_\(referenceRecordName)", configureNotificationInfo: configureNotificationInfo, errorHandler: errorHandler)
    }

    /**
    Unsubscribe for modifications to a recordType with a reference to the user

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter referenceRecordName: The CloudKit record id that we are looking for
    - parameter referenceField: The name of the field that we will query for the referenceRecordName
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func unsubscribe(_ type: CKDataObject, referenceRecordName: String, referenceField: String, completionHandler:(()->())? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        unsubscribe(type, filterId:"reference_\(referenceField)_\(referenceRecordName)", completionHandler:completionHandler, errorHandler: errorHandler)
    }

    /**
    Subscribe for modifications to a recordType

    - parameter type: An instance of the Object for what we want to subscribe for
    - parameter configureNotificationInfo: The function that will be called with the CKNotificationInfo object so that we can configure it
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func subscribe(_ type: CKDataObject, configureNotificationInfo:((_ notificationInfo: CKNotificationInfo) -> Void)? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        subscribe(type, predicate: NSPredicate(value: true), filterId: "all", configureNotificationInfo: configureNotificationInfo, errorHandler: errorHandler)
    }

    /**
    Unsubscribe for modifications to a recordType

    - parameter type: An instance of the Object for what we want to query the record type
    - parameter errorHandler: The function that will be called when there was an error
    :return: No return value
    */
    open func unsubscribe(_ type: CKDataObject, completionHandler:(()->())? = nil, errorHandler:((_ error: Error) -> Void)? = nil) {
        unsubscribe(type, filterId:"all", completionHandler:completionHandler, errorHandler:errorHandler)
    }

    /**
    Unsubscribe for all modifications

    - parameter errorHandler: The function that will be called when there was an error
    - parameter completionHandler: The function that will be called with a number which is the count of messages removed.
    :return: No return value
    */
    open func unsubscribeAll(_ completionHandler:@escaping (_ subscriptionCount: Int) -> Void, errorHandler:((_ error: Error) -> Void)? = nil) {
        database.fetchAllSubscriptions(completionHandler: {subscriptions, error in
            self.handleCallback(self.nilNotAllowed(error as Error?, value: subscriptions as AnyObject?), errorHandler: errorHandler, completionHandler: {
                for subscription: CKSubscription in subscriptions! {
                    self.database.delete(withSubscriptionID: subscription.subscriptionID, completionHandler: {subscriptionId, error in
                        self.handleCallback(error as Error?, errorHandler: errorHandler, completionHandler: {
                            EVLog("Subscription with id \(subscriptionId.debugDescription) was removed : \(subscription.debugDescription)")
                        })
                    })
                }
                completionHandler(subscriptions!.count)
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
    open func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], executeIfNonQuery:() -> Void, inserted:@escaping (_ recordID: String, _ item: CKDataObject) -> Void, updated:@escaping (_ recordID: String, _ item: CKDataObject) -> Void, deleted:@escaping (_ recordId: String) -> Void, completed:@escaping ()-> Void) {
        var converedUserInfo: [String:NSObject] = [String:NSObject]()
        for (key, value) in userInfo {
            if let setValue = value as? NSObject {
                converedUserInfo[key as! String] = setValue
            }
        }

        let cloudNotification = CKNotification(fromRemoteNotificationDictionary: converedUserInfo)
        //EVLog("Notification alert body : \(cloudNotification.alertBody)")

        // Handle CloudKit subscription notifications
        var recordID: CKRecordID?
        if cloudNotification.notificationType == CKNotificationType.query {
            if let queryNotification = cloudNotification as? CKQueryNotification {
                if queryNotification.recordID != nil {
                    recordID = queryNotification.recordID
                    EVLog("recordID of notified record = \(recordID.debugDescription)")
                    if queryNotification.queryNotificationReason == .recordDeleted {
                        deleted(recordID!.recordName)
                    } else {
                        // Notification could be for pulbic and private db. Errors are ignored
                        getItem(recordID!.recordName, completionHandler: { item in
                            EVLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                            EVReflection.logObject(item)
                            if queryNotification.queryNotificationReason == CKQueryNotificationReason.recordCreated {
                                inserted(recordID!.recordName, item)
                            } else if queryNotification.queryNotificationReason == CKQueryNotificationReason.recordUpdated {
                                updated(recordID!.recordName, item)
                            }
                            }, errorHandler: { error in
                                EVLog("ERROR: getItem for notification.\n\(error.localizedDescription)")
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
        fetchChangeNotifications(recordID, inserted: inserted, updated: updated, deleted: deleted, completed:completed)
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
    open func fetchChangeNotifications(_ skipRecordID: CKRecordID?, inserted:@escaping (_ recordID: String, _ item: CKDataObject) -> Void, updated:@escaping (_ recordID: String, _ item: CKDataObject) -> Void, deleted:@escaping (_ recordId: String) -> Void, completed:@escaping ()-> Void) {
        var array: [CKNotificationID] = [CKNotificationID]()
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: self.previousChangeToken)
        operation.notificationChangedBlock = { notification in
            if notification.notificationType == .query {
                if let queryNotification = notification as? CKQueryNotification {
                    array.append(notification.notificationID!)
                    if skipRecordID != nil && skipRecordID?.recordName != queryNotification.recordID?.recordName {
                        if queryNotification.queryNotificationReason == .recordDeleted {
                            deleted(queryNotification.recordID!.recordName)
                        } else {
                            self.getItem(queryNotification.recordID!.recordName, completionHandler: { item in
                                EVLog("getItem: recordType = \(EVReflection.swiftStringFromClass(item)), with the keys and values:")
                                EVReflection.logObject(item)
                                if queryNotification.queryNotificationReason == .recordCreated {
                                    inserted(queryNotification.recordID!.recordName, item)
                                } else if queryNotification.queryNotificationReason == .recordUpdated {
                                    updated(queryNotification.recordID!.recordName, item)
                                }
                            }, errorHandler: { error in
                                EVLog("ERROR: getItem for change notification.\n\(error.localizedDescription)")
                            })
                        }
                    }
                }
            }
        }
        operation.fetchNotificationChangesCompletionBlock = { changetoken, error in
            let op = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: array)
            op.start()
            EVLog("changetoken = \(changetoken.debugDescription)")
            self.previousChangeToken = changetoken

            if operation.moreComing {
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
    fileprivate var previousChangeToken: CKServerChangeToken? {
        get {

            let encodedObjectData = UserDefaults.standard.object(forKey: "\(container.containerIdentifier.debugDescription)_lastFetchNotificationId") as? Data
            var decodedData: CKServerChangeToken? = nil
            if encodedObjectData != nil {
                decodedData = NSKeyedUnarchiver.unarchiveObject(with: encodedObjectData!) as? CKServerChangeToken
            }
            return decodedData
        }
        set(newToken) {
            if newToken != nil {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: newToken!), forKey:"\(container.containerIdentifier.debugDescription)_lastFetchNotificationId")
            }
        }
    }

    /**
    Setting the application badge count to a specific number
    - parameter count: The number for the badge
    */
    open func setBadgeCounter(_ count: Int) {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: count)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            func handleError(_ error: Error) -> Void {
                EVLog("Error: could not reset badge: \n\(error)")
            }
            self.handleCallback(error as Error?, errorHandler: handleError, completionHandler: {
                #if os(iOS)
                    OperationQueue.main.addOperation {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                #elseif os(OSX)
                    //TODO: Set badge?
                    NSLog("How to set the badge on OSX?")
                #endif
                })
        }
        container.add(badgeResetOperation)
    }
}
