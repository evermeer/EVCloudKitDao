//
//  Message.swift
//
//  Created by Edwin Vermeer on 01-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//
// SwiftLint ignore variable_name

import CloudKit
import EVReflection

enum MessageTypeEnum: String {
    case Text = "T",
    Picture = "P",
    Location = "L"
}

class Message: CKDataObject {
    // From which Channel is this message
    var From: CKRecord.Reference? // = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var From_ID: String = ""
    func setFromFields(_ id: String) {
        self.From_ID = id
        self.From = CKRecord.Reference(recordID: CKRecord.ID(recordName: id), action: CKRecord.Reference.Action.deleteSelf)
    }
    var FromFirstName: String = ""
    var FromLastName: String = ""

    // To what Channel or Group is this message
    var To: CKRecord.Reference? // = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var To_ID: String = ""
    func setToFields(_ id: String) {
        self.To_ID = id
        self.To = CKRecord.Reference(recordID: CKRecord.ID(recordName: id), action: CKRecord.Reference.Action.deleteSelf)
    }
    var ToFirstName: String = ""
    var ToLastName: String = ""

    // Message text
    var Text: String = ""

    // is there a (media) attachment
    var MessageType: String = MessageTypeEnum.Text.rawValue

    // From which Channel is this message
    var Asset: CKRecord.Reference? // = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var Asset_ID: String = ""
    func setAssetFields(_ id: String) {
        self.Asset_ID = id
        self.Asset = CKRecord.Reference(recordID: CKRecord.ID(recordName: id), action: CKRecord.Reference.Action.none)
    }

    var Latitude: Double = 52.8350711
    var Longitude: Double = 4.8653827
}
