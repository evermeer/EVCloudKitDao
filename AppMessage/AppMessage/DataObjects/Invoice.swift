//
//  Invoice.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 12/24/15.
//  Copyright © 2015 mirabeau. All rights reserved.
//

import Foundation

class Invoice: EVCloudKitDataObject {
    var InvoiceNumber: String?
    var InvoiceAddress: Address?
    var DeliveryAddress: Address?
    var PostalAddress: Address?
}

class Address: EVCloudKitDataObject {
    var Street: String = ""
    var HouseNumber: String = ""
    var PostalCode: String = ""
    var City: String = ""
    var State: String = ""
    var Country: String = ""
}