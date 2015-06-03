//
//  EVCloudKitDataObject.swift
//
//  Created by Edwin Vermeer on 11/30/14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit
import EVReflection

/**
*/
public class EVCloudKitDataObject: EVObject {
    /**
    The unique ID of the record.
    */
    public var recordID: CKRecordID = CKRecordID(recordName: NSUUID().UUIDString)

    /**
    The app-defined string that identifies the type of the record.
    */
    public var recordType: String!

    /**
    The time when the record was first saved to the server.
    */
    public var creationDate: NSDate = NSDate()

    /**
    The ID of the user who created the record.
    */
    public var creatorUserRecordID: CKRecordID?

    /**
    The time when the record was last saved to the server.
    */
    public var modificationDate: NSDate = NSDate()

    /**
    The ID of the user who last modified the record.
    */
    public var lastModifiedUserRecordID: CKRecordID?

    /**
    A string containing the server change token for the record.
    */
    public var recordChangeTag: String?

    /**
    Encoding the system fields so that we can create a new CKRecord based on this
    */
    public var encodedSystemFields: NSData?
}
