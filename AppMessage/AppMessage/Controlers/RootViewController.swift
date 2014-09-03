//
//  RootViewController.swift
//
//  Created by Edwin Vermeer on 24-07-14.
//  Copyright (c) 2014. All rights reserved.
//

import UIKit

class RootViewController: RESideMenu, RESideMenuDelegate {
    internal var x:String?
    private var y:String?
    
    override func viewDidLoad() {

        self.animationDuration = 0.2
        self.menuPreferredStatusBarStyle = .LightContent
        self.contentViewShadowColor = .blackColor()
        self.contentViewShadowOffset = CGSizeMake(0, 0)
        self.contentViewShadowOpacity = 0.6
        self.contentViewShadowRadius = 12
        self.contentViewShadowEnabled = true

        self.contentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("homeViewController") as UIViewController
        self.leftMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("leftMenuViewController") as UIViewController
        self.rightMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("rightMenuViewController") as UIViewController
        self.backgroundImage = UIImage(named:"Default-568h")
        self.delegate = self
        
        super.viewDidLoad()
        
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
    
}
