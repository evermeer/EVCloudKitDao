//
//  MenuViewController.swift
//
//  Created by Edwin Vermeer on 04-10-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import UIKit

class MenuViewController: RESideMenu, RESideMenuDelegate {
    
    override func viewDidLoad() {
        
        self.connectToNews()
        
        // Only already setup CloudKit connect's will receive these notifications (like the News above)
        EVCloudData.instance.fetchChangeNotifications()
        
        // Setting menu properties
        self.delegate = self
        self.animationDuration = 0.2
        self.menuPreferredStatusBarStyle = .LightContent
        self.contentViewShadowColor = .blackColor()
        self.contentViewShadowOffset = CGSizeMake(0, 0)
        self.contentViewShadowOpacity = 0.6
        self.contentViewShadowRadius = 12
        self.contentViewShadowEnabled = true
        self.backgroundImage = UIImage(named:"Default-568h")
        
        // Setting the views
        self.contentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("homeViewController") as UIViewController
        self.leftMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("leftMenuViewController") as UIViewController
        self.rightMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("rightMenuViewController") as UIViewController
        
        super.viewDidLoad()
        
        //TODO: Why need to reload in order to show the navigationbar?
        self.setContentViewController(UINavigationController(rootViewController: self.storyboard?.instantiateViewControllerWithIdentifier("homeViewController") as UIViewController), animated: true)
        
    }
    
    
    func sideMenu(sideMenu:RESideMenu, willShowMenuViewController:UIViewController) {
        NSLog("willShowMenuViewController: \(willShowMenuViewController)")
    }
    func sideMenu(sideMenu:RESideMenu, didShowMenuViewController:UIViewController) {
        NSLog("willShowMenuViewController: \(didShowMenuViewController)")
    }
    func sideMenu(sideMenu:RESideMenu, willHideMenuViewController:UIViewController) {
        NSLog("willShowMenuViewController: \(willHideMenuViewController)")
    }
    func sideMenu(sideMenu:RESideMenu, didHideMenuViewController:UIViewController) {
        NSLog("willShowMenuViewController: \(didHideMenuViewController)")
    }
    
    
    
    func connectToNews() {
        EVCloudData.instance.connect(News()
            , predicate: NSPredicate(value: true)
            , filterId: "News_All"
            , configureNotificationInfo: { notificationInfo in
                notificationInfo.alertBody = "New news item"
                notificationInfo.shouldSendContentAvailable = true
                // notificationInfo.alertLocalizationKey = "subscriptionMessage"
                // notificationInfo.alertLocalizationArgs = [recordType, filterId]
                // notificationInfo.alertActionLocalizationKey = "subscrioptionActionMessage"
                // notificationInfo.alertLaunchImage = "alertImage"
                // notificationInfo.soundName = "alertSound"
                // notificationInfo.shouldBadge = true
                // notificationInfo.desiredKeys = [""]
            }
            , completionHandler: { results in
                NSLog("There are \(results.count) existing news items")
                self.refreshNewsVieuw()
            }, insertedHandler: {item in
                NSLog("New News item received with subject '\((item as News).Subject)'")
                self.refreshNewsVieuw()
            }, updatedHandler: {item in
                NSLog("Updated News item received with subject '\((item as News).Subject)'")
                self.refreshNewsVieuw()
            }, deletedHandler: {recordId in
                NSLog("News item removed")
                self.refreshNewsVieuw()
            }, errorHandler: {error in
                NSLog("<-- ERROR connect")
        })
    }
    
    func refreshNewsVieuw() {
        NSOperationQueue.mainQueue().addOperationWithBlock({
            // If news view is loaded, then refresh the data (on the main queue) For this demo, just log it
            var news:Dictionary<String, NSObject> = EVCloudData.instance.data["News_All"]!
            for (key, value) in news {
                NSLog("key = \(key), Subject = \((value as News).Subject), Body = \((value as News).Body), ActionUrl = \((value as News).ActionUrl)")
            }
        })
    }
    
}