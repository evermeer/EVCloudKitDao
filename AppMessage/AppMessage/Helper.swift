//
//  Helper.swift
//  AppMessage
//
//  Created by Edwin Vermeer on 11/23/14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import Foundation

class Helper {
    class func showError(message:String) {
        var options: NSDictionary = [
            kCRToastTextKey : message,
            kCRToastNotificationTypeKey : CRToastType.NavigationBar.rawValue,
            kCRToastNotificationPresentationTypeKey : CRToastPresentationType.Cover.rawValue,
            kCRToastTimeIntervalKey: 5.0,
            kCRToastTextAlignmentKey : NSTextAlignment.Center.rawValue,
            kCRToastBackgroundColorKey : UIColor.redColor(),
            kCRToastAnimationInTypeKey : CRToastAnimationType.Spring.rawValue,
            kCRToastAnimationOutTypeKey : CRToastAnimationType.Spring.rawValue,
            kCRToastAnimationInDirectionKey : CRToastAnimationDirection.Top.rawValue,
            kCRToastAnimationOutDirectionKey : CRToastAnimationDirection.Bottom.rawValue,
        ]
        CRToastManager.showNotificationWithOptions(options, completionBlock: { })
        NSLog("Error: \(message)")

    }
}

