//
//  Folowing.swift
//
//  Created by Edwin Vermeer on 15-09-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit
import Foundation

class Folowing : NSObject {
    // The Channel that we are folowing
    var Channel : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
}