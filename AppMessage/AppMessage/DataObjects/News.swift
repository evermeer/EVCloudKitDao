//
//  News.swift
//
//  Created by Edwin Vermeer on 23-08-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//
// SwiftLint ignore variable_name

import CloudKit
import EVReflection

class News: CKDataObject {
    var Subject: String = ""
    var Body: String = ""
    var ActionUrl: String = ""
}
