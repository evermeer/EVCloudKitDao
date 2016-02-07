//
//  EVCloudKitEnums.swift
//
//  Created by Edwin Vermeer on 12/5/15.
//  Copyright © 2015 mirabeau. All rights reserved.
//


// ------------------------------------------------------------------------
// MARK: - EVCloudKitDao enums
// ------------------------------------------------------------------------

/**
Wrapper class for being able to use a class instance Dictionary
*/
internal class DaoContainerWrapper {
    /**
     Wrapping the public containers
     */
    var publicContainers : Dictionary<String,EVCloudKitDao> = Dictionary<String,EVCloudKitDao>()
    /**
     Wrapping the private containers
     */
    var privateContainers : Dictionary<String,EVCloudKitDao> = Dictionary<String,EVCloudKitDao>()
}

/**
 The functional statuses for a CloudKit error
 */
public enum HandleCloudKitErrorAs {
    case Success,
    Retry(afterSeconds:Double),
    RecoverableError,
    Fail
}

/**
Indicates if a dao is setup as private or public
*/
public enum InstanceType {
    case IsPrivate,
    IsPublic
}


// ------------------------------------------------------------------------
// MARK: - EVCloudKitData enums
// ------------------------------------------------------------------------


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
 The enum for getting the notification key to subscribe to when observing changes
 */
public enum DataChangeNotificationType {
    /**
     Data retrieval is progressing/finished
     */
    case Completed,
    /**
    New item has been inserted
    */
    Inserted,
    /**
    Existing item has been updated
    */
    Updated,
    /**
    Notification of any data modification (completion, inserted, updated or deleted)
    */
    DataChanged,
    /**
    Existing item has been deleted
    */
    Deleted,
    /**
    An error occurred while attempting a data operation
    */
    Error
}

/**
 The enum for determining the current state of data retrieval in the Completion handler and/or NSNotificationManager push notification
 */
public enum CompletionStatus: Int {
    /**
     The results were returned from the local cache
     */
    case FromCache,
    /**
    The requested data wasn't found in the local cache. It will be requested from iCloud
    */
    Retrieving,
    /**
    Some data was received from iCloud, but more results are available if wanted (return true to request more results)
    */
    PartialResult,
    /**
    All available data has been successfully retrieved from iCloud
    */
    FinalResult
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


