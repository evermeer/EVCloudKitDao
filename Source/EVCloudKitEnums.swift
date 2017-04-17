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
    case success,
    retry(afterSeconds:Double),
    recoverableError,
    fail
}

/**
Indicates if a dao is setup as private or public
*/
public enum InstanceType {
    case isPrivate,
    isPublic
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
    case none,
    /**
    Always write changes to the cache immediately
    */
    direct,
    /**
    Only write to the cache once every .. minutes when there are changes (initial query result will always be written directly)
    */
    every(minute:Int)
}

/**
 The enum for getting the notification key to subscribe to when observing changes
 */
public enum DataChangeNotificationType {
    /**
     Data retrieval is progressing/finished
     */
    case completed,
    /**
    New item has been inserted
    */
    inserted,
    /**
    Existing item has been updated
    */
    updated,
    /**
    Notification of any data modification (completion, inserted, updated or deleted)
    */
    dataChanged,
    /**
    Existing item has been deleted
    */
    deleted,
    /**
    An error occurred while attempting a data operation
    */
    error
}

/**
 The enum for determining the current state of data retrieval in the Completion handler and/or NSNotificationManager push notification
 */
public enum CompletionStatus: Int {
    /**
     The results were returned from the local cache
     */
    case fromCache,
    /**
    The requested data wasn't found in the local cache. It will be requested from iCloud
    */
    retrieving,
    /**
    Some data was received from iCloud, but more results are available if wanted (return true to request more results)
    */
    partialResult,
    /**
    All available data has been successfully retrieved from iCloud
    */
    finalResult
}

/**
 Strange enough by default Swift does not implement the Equality operator for enums. So we just made one ourselves.
 
 - parameter leftPart: The CachingStrategy value at the left of the equality operator.
 - parameter rightPart: The CachingStrategy value at the right of the equality operator.
 */
func ==(leftPart: CachingStrategy, rightPart: CachingStrategy) -> Bool {
    switch(leftPart) {
    case .none:
        switch(rightPart) {
        case .none: return true
        default: return false
        }
    case .direct:
        switch(rightPart) {
        case .direct: return true
        default: return false
        }
    case .every(let minutea):
        switch(rightPart) {
        case .every(let minuteb): return minutea == minuteb
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


