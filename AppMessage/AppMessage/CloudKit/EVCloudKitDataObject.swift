//
//  EVCloudKitDataObject.swift
//
//  Created by Edwin Vermeer on 11/30/14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

/**
*/
public class EVCloudKitDataObject : NSObject, NSCoding {
    /**
    The unique ID of the record.
    */
    public var recordID: CKRecordID!
    
    /**
    The app-defined string that identifies the type of the record.
    */
    public var recordType: String!
    
    /**
    The time when the record was first saved to the server.
    */
    public var creationDate: NSDate!
    
    /**
    The ID of the user who created the record.
    */
    public var creatorUserRecordID: CKRecordID!
    
    /**
    The time when the record was last saved to the server.
    */
    public var modificationDate: NSDate!
    
    /**
    The ID of the user who last modified the record.
    */
    public var lastModifiedUserRecordID: CKRecordID!

    /**
    A string containing the server change token for the record.
    */
    public var recordChangeTag: String!
    

    /**
    Decode any object
    
    :param: theObject The object that we want to decode.
    :param: aDecoder The NSCoder that will be used for decoding the object.
    */
    public required convenience init(coder aDecoder: NSCoder) {
        self.init()
        EVReflection.decodeObjectWithCoder(self, aDecoder: aDecoder)
    }
    
    /**
    Encode this object using a NSCoder
    
    :param: aCoder The NSCoder that will be used for encoding the object
    */
    public func encodeWithCoder(aCoder: NSCoder) {
        EVReflection.encodeWithCoder(self, aCoder: aCoder)
    }
}