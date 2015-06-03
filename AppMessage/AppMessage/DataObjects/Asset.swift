//
//  Asset.swift
//
//  Created by Edwin Vermeer on 23-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//
// SwiftLint ignore variable_name

import CloudKit
import UIKit

class Asset: EVCloudKitDataObject {
    var File: CKAsset?  // = CKAsset(fileURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("image-not-available", ofType: "jpg")!))
    var FileName: String = ""
    var FileType: String = ""

    func image() -> UIImage? {
        if let file = File {
            if let data = NSData(contentsOfURL: file.fileURL) {
                return UIImage(data: data)
            }
        }
        return nil
    }
}
