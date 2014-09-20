//
//  Participant.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit

class Participant : NSObject {
    // reference to a group channel
    var Group : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var Participant : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
}