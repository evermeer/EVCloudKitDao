//
//  Channel.swift
//
//  Created by Edwin Vermeer on 14-09-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import CloudKit


enum ChannelType: String {
    case User = "User"
    case Group = "Group"
    case Organisation = "Organisation"
    case Event = "Event"
    case Add = "Add"
}

class Channel : NSObject {
    //iCloud user reference
    var User : CKReference = CKReference(recordID: CKRecordID(recordName: "N/A"), action: CKReferenceAction.None)
    var Type : String = ChannelType.User.rawValue
    var Name : String = ""
    var About : String = ""
    var HasAttachments : Bool = false
}
