//
//  EVCloudKitDataObject.swift
//
//  Created by Edwin Vermeer on 11/30/14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

/**
*/
class EVCloudKitDataObject : NSObject {
    /**
    The unique ID of the record.
    */
    var recordID: CKRecordID!
    
    /**
    The app-defined string that identifies the type of the record.
    */
    var recordType: String!
    
    /**
    The time when the record was first saved to the server.
    */
    var creationDate: NSDate!
    
    /**
    The ID of the user who created the record.
    */
    var creatorUserRecordID: CKRecordID!
    
    /**
    The time when the record was last saved to the server.
    */
    var modificationDate: NSDate!
    
    /**
    The ID of the user who last modified the record.
    */
    var lastModifiedUserRecordID: CKRecordID!

    /**
    A string containing the server change token for the record.
    */
    var recordChangeTag: String!
}