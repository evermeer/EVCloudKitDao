//
//  EVCloudKitDataObject.swift
//
//  Created by Edwin Vermeer on 11/30/14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

/**
*/
public class EVCloudKitDataObject : NSObject, NSCoding, Printable, Hashable, Equatable {
    /**
    The unique ID of the record.
    */
    public var recordID: CKRecordID?
    
    /**
    The app-defined string that identifies the type of the record.
    */
    public var recordType: String?
    
    /**
    The time when the record was first saved to the server.
    */
    public var creationDate: NSDate?
    
    /**
    The ID of the user who created the record.
    */
    public var creatorUserRecordID: CKRecordID?
    
    /**
    The time when the record was last saved to the server.
    */
    public var modificationDate: NSDate?
    
    /**
    The ID of the user who last modified the record.
    */
    public var lastModifiedUserRecordID: CKRecordID?

    /**
    A string containing the server change token for the record.
    */
    public var recordChangeTag: String?
    

    /**
    Decode any object
    
    :param: theObject The object that we want to decode.
    :param: aDecoder The NSCoder that will be used for decoding the object.
    */
    public required convenience init(coder: NSCoder) {
        self.init()
        EVReflection.decodeObjectWithCoder(self, aDecoder: coder)
    }
    
    /**
    Encode this object using a NSCoder
    
    :param: aCoder The NSCoder that will be used for encoding the object
    */
    public func encodeWithCoder(aCoder: NSCoder) {
        EVReflection.encodeWithCoder(self, aCoder: aCoder)
    }
    
    /**
    Returns the pritty description of this object
    
    :return: The pritty description
    */
    public func description() -> String {
        return EVReflection.description(self)
    }
    
    /**
    Returns the hashvalue of this object
    
    :return: The hashvalue of this object
    */
    public override var hashValue : Int {
        get {
            return EVReflection.hashValue(self)
        }
    }
    
    /**
    Function for returning the hash for the NSObject based functionality
    
    :return: The hashvalue of this object
    */
    public func hash() -> Int {
        return self.hashValue
    }
    
    /**
    Implementation of the NSObject isEqual comparisson method
    
    :param: object The object where you want to compare with
    :return: Returns true if the object is the same otherwise false
    */
    override public func isEqual(object: AnyObject?) -> Bool { // for isEqual:
        if let dataObject = object as? EVCloudKitDataObject {
            return dataObject == self // just use our "==" function
        } else { return false }
    }
}

/**
Equality operator for comparing all fields of a class that has EVCloudKitDataObject as its base class

:param: lhs Object to compare
:param: rhs Object to compare
:return: true if objects are equal, otherwise false
*/
public func ==(lhs: EVCloudKitDataObject, rhs: EVCloudKitDataObject) -> Bool {
    return EVReflection.areEqual(lhs, rhs: rhs)
}


