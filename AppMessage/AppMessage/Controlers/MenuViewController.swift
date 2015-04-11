//
//  MenuViewController.swift
//
//  Created by Edwin Vermeer on 04-10-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import UIKit
import RESideMenu

class MenuViewController: RESideMenu, RESideMenuDelegate {
    
    override func viewDidLoad() {
        setupMenu()

        super.viewDidLoad()
        
        //TODO: Why need to reload in order to show the navigationbar?
        self.setContentViewController(UINavigationController(rootViewController: self.storyboard?.instantiateViewControllerWithIdentifier("homeViewController") as! UIViewController), animated: true)
    }
    
    func setupMenu() {
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
        self.contentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("homeViewController") as! UIViewController
        var leftMenu:LeftMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("leftMenuViewController") as! LeftMenuViewController
        self.leftMenuViewController = leftMenu as UIViewController
        var rightMenu:RightMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("rightMenuViewController")! as! RightMenuViewController
        self.rightMenuViewController = rightMenu as UIViewController
        rightMenu.leftMenu = leftMenu
    }
    
    
    func sideMenu(sideMenu:RESideMenu, willShowMenuViewController:UIViewController) {
        //EVLog("willShowMenuViewController: \(willShowMenuViewController)")
    }
    func sideMenu(sideMenu:RESideMenu, didShowMenuViewController:UIViewController) {
        //EVLog("willShowMenuViewController: \(didShowMenuViewController)")
    }
    func sideMenu(sideMenu:RESideMenu, willHideMenuViewController:UIViewController) {
        //EVLog("willShowMenuViewController: \(willHideMenuViewController)")
    }
    func sideMenu(sideMenu:RESideMenu, didHideMenuViewController:UIViewController) {
        //EVLog("willShowMenuViewController: \(didHideMenuViewController)")
    }
    
        
}