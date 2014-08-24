//
//  Message.swift
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import CloudKit

class Message : NSObject {
    var From : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var To : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var Text : String = ""
    var HasAttachments : Bool = false
}