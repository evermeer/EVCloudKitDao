//
//  Helper.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 11/23/14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import Foundation
import CRToast
import Async

class Helper {

    class func showMessage(_ message: String, color: UIColor) {
        let options: NSDictionary = [
            kCRToastTextKey : message,
            kCRToastNotificationTypeKey : CRToastType.navigationBar.rawValue,
            kCRToastNotificationPresentationTypeKey : CRToastPresentationType.cover.rawValue,
            kCRToastTimeIntervalKey: 5.0,
            kCRToastTextAlignmentKey : NSTextAlignment.center.rawValue,
            kCRToastBackgroundColorKey : color,
            kCRToastAnimationInTypeKey : CRToastAnimationType.spring.rawValue,
            kCRToastAnimationOutTypeKey : CRToastAnimationType.spring.rawValue,
            kCRToastAnimationInDirectionKey : CRToastAnimationDirection.top.rawValue,
            kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.bottom.rawValue,
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
