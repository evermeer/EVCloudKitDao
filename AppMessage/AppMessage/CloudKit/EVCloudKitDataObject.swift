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
open class EVCloudKitDataObject: EVObject {
    /**
    The unique ID of the record.
    */
    open var recordID: CKRecordID = CKRecordID(recordName: UUID().uuidString)

    /**
    The app-defined string that identifies the type of the record.
    */
    open var recordType: String!

    /**
    The time when the record was first saved to the server.
    */
    open var creationDate: Date = Date()

    /**
    The ID of the user who created the record.
    */
    open var creatorUserRecordID: CKRecordID?

    /**
    The time when the record was last saved to the server.
    */
    open var modificationDate: Date = Date()

    /**
    The ID of the user who last modified the record.
    */
    open var lastModifiedUserRecordID: CKRecordID?

    /**
    A string containing the server change token for the record.
    */
    open var recordChangeTag: String?

    /**
    Encoding the system fields so that we can create a new CKRecord based on this
    */
    open var encodedSystemFields: Data?
}
