//
//  Message.swift
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import CloudKit

class Message : NSObject {
    // From which Channel is this message
    var From : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    // To what Channel or Group is this message
    var To : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    // Message text
    var Text : String = ""
    // is there a (media) attachment
    var HasAttachments : Bool = false
}