//
//  Asset.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 23-07-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import CloudKit

//TODO: valueForAny does not work yet for nulable types.
class Asset : NSObject {
    var Message : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var File : CKAsset = CKAsset(fileURL: NSURL(fileURLWithPath: "/"))
    var FileName : String = ""
    var FileType : String = ""
}