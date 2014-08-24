//
//  Group.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import CloudKit

class Group : NSObject {
    var Initiator : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var Name : String = ""
}