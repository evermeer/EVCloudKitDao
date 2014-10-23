//
//  Asset.swift
//
//  Created by Edwin Vermeer on 23-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit
import UIKit

//TODO: valueForAny does not work yet for nulable types.
class Asset : NSObject {
    var AttachedTo : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var File : CKAsset = CKAsset(fileURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("image-not-available", ofType: "jpg")!))
    var FileName : String = ""
    var FileType : String = ""
    
    func image() -> UIImage {
        return UIImage(contentsOfFile: File.fileURL.absoluteString!)!
    }
}