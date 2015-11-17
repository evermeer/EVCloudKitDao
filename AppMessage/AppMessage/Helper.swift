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

    class func showMessage(message: String, color: UIColor) {
        let options: NSDictionary = [
            kCRToastTextKey : message,
            kCRToastNotificationTypeKey : CRToastType.NavigationBar.rawValue,
            kCRToastNotificationPresentationTypeKey : CRToastPresentationType.Cover.rawValue,
            kCRToastTimeIntervalKey: 5.0,
            kCRToastTextAlignmentKey : NSTextAlignment.Center.rawValue,
            kCRToastBackgroundColorKey : color,
            kCRToastAnimationInTypeKey : CRToastAnimationType.Spring.rawValue,
            kCRToastAnimationOutTypeKey : CRToastAnimationType.Spring.rawValue,
            kCRToastAnimationInDirectionKey : CRToastAnimationDirection.Top.rawValue,
            kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.Bottom.rawValue,
        ]
        Async.main {
            CRToastManager.showNotificationWithOptions(options as [NSObject : AnyObject], completionBlock: { })
        }
    }

    class func showError(message: String) {
        EVLog("ERROR: \(message)")
        showMessage(message, color: UIColor.redColor())
    }

    class func showStatus(message: String) {
        EVLog("\(message)")
        showMessage(message, color: UIColor.greenColor())
    }
}
