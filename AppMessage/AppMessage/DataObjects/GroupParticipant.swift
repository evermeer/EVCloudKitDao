//
//  GroupParticipant.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import CloudKit

class GroupParticipant : NSObject {
    var Group : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var Participant : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
}