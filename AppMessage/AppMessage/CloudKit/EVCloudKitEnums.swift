//
//  EVCloudKitEnums.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 12/5/15.
//  Copyright © 2015 mirabeau. All rights reserved.
//

import Foundation
import CloudKit


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

/**
 Internal implementor of opaque token protocol returned by add..DBInitializationCompleteHandler methods. Used instead of directly storing handler references so removeToken can be implemented by filtering instances by comparing to self.
 */
internal class ConnectStatusCompletionHandlerWrapper: DBInitializationCompleteHandlerToken {
    /**
     The collection that this wrapper is assigned to. Used when releaseToken is called.
     */
    private var collection: [ConnectStatusCompletionHandlerWrapper]
    /**
     The originally-passed handler that should be invoked.
     */
    private let handler: DBInitializationCompleteHandler
    
    /**
     Boolean that indicates if the handler has been invoked yet. Used to determine if a handler should be explicitly called when a reference (publicDB, privateDB, etc.) that has already been initialized is retrieved.
     */
    var hasBeenInvoked: Bool = false
    
    /**
     We modify the passed collection by inserting/appending ourselves, thus requiring it be defined as an inout var
     */
    init(inout collection: [ConnectStatusCompletionHandlerWrapper],  insert: Bool, handler: DBInitializationCompleteHandler) {
        self.collection = collection
        self.handler = handler
        
        if insert {
            collection.insert(self, atIndex: 0)
        } else {
            collection.append(self)
        }
    }
    
    /**
     Method called to invoke the originally-passed handler and to set our hasBeenInvoked flag to true
     */
    func invoke(status: CKAccountStatus, error: NSError?) {
        hasBeenInvoked = true
        handler(status: status, error: error)
    }
    
    /**
     Method called to release our instance from the collection we were assigned to
     */
    func releaseToken() {
        collection = collection.filter { $0 !== self }
    }
}

internal class HandlerCollection {
    var collection = [ConnectStatusCompletionHandlerWrapper]()
    var hasNewHandlers = false
    
    func addHandlerToCollection(handler: DBInitializationCompleteHandler) -> ConnectStatusCompletionHandlerWrapper {
        hasNewHandlers = true
        return ConnectStatusCompletionHandlerWrapper(collection: &collection, insert: false, handler: handler)
    }
    
    func insertHandlerIntoCollection(handler: DBInitializationCompleteHandler) -> ConnectStatusCompletionHandlerWrapper {
        hasNewHandlers = true
        return ConnectStatusCompletionHandlerWrapper(collection: &collection, insert: true, handler: handler)
    }
}
