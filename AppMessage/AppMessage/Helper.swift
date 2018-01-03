//
//  Helper.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 11/23/14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import Foundation
import CRToast
import EVCloudKitDao

class Helper {

    class func showMessage(_ message: String, color: UIColor) {
        let options: NSDictionary = [
            kCRToastTextKey : message,
            kCRToastNotificationTypeKey : NSNumber(value: CRToastType.navigationBar.rawValue),
            kCRToastNotificationPresentationTypeKey : NSNumber(value: CRToastPresentationType.cover.rawValue),
            kCRToastTimeIntervalKey: NSNumber(value: 5.0),
            kCRToastTextAlignmentKey : NSNumber(value: NSTextAlignment.center.rawValue),
            kCRToastBackgroundColorKey : color,
            kCRToastAnimationInTypeKey : NSNumber(value: CRToastAnimationType.spring.rawValue),
            kCRToastAnimationOutTypeKey : NSNumber(value: CRToastAnimationType.spring.rawValue),
            kCRToastAnimationInDirectionKey : NSNumber(value: CRToastAnimationDirection.top.rawValue),
            kCRToastAnimationOutDirectionKey : NSNumber(value: CRToastAnimationDirection.bottom.rawValue),
        ]
        Async.main {
            CRToastManager.showNotification(options: options as! [AnyHashable: Any], completionBlock: { })
        }
    }

    class func showError(_ message: String) {
        EVLog("ERROR: \(message)")
        showMessage(message, color: UIColor.red)
    }

    class func showStatus(_ message: String) {
        EVLog("\(message)")
        showMessage(message, color: UIColor.green)
    }
}
