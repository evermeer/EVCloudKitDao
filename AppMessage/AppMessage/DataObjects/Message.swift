//
//  Message.swift
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

class Message : EVCloudKitDataObject {
    // From which Channel is this message
    var From : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var From_ID : String = ""
    func setFrom(id:String) {
        self.From_ID = id
        self.From = CKReference(recordID: CKRecordID(recordName: id), action: CKReferenceAction.None)
    }
    // To what Channel or Group is this message
    var To : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var To_ID : String = ""
    func setTo(id:String) {
        self.To_ID = id
        self.To = CKReference(recordID: CKRecordID(recordName: id), action: CKReferenceAction.None)
    }
    // Message text
    var Text : String = ""
    // is there a (media) attachment
    var HasAttachments : Bool = false
}