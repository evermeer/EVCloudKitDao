//
//  CKAsset+UIImage.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 14/01/2017.
//  Copyright © 2017 mirabeau. All rights reserved.
//

import CloudKit
import UIKit

public extension CKAsset {
    public func image() -> UIImage? {
        if let data = try? Data(contentsOf: self.fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}
