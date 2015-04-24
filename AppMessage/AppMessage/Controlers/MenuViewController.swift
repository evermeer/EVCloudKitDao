//
//  MenuViewController.swift
//
//  Created by Edwin Vermeer on 04-10-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

import UIKit

class MenuViewController: SSASideMenu {
        
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setupMenu()
    }
    
    func setupMenu() {
        // Setting menu properties
//        self.delegate = self
        self.animationDuration = 0.2
//        self.menuPreferredStatusBarStyle = .LightContent
        self.contentViewShadowColor = .blackColor()
        self.contentViewShadowOffset = CGSizeMake(0, 0)
        self.contentViewShadowOpacity = 0.6
        self.contentViewShadowRadius = 12
        self.contentViewShadowEnabled = true
        self.backgroundImage = UIImage(named:"Default-568h")
        
//        // Setting the views
//        self.contentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("homeViewController") as! HomeViewController
//        var leftMenu = self.storyboard?.instantiateViewControllerWithIdentifier("leftMenuViewController") as! LeftMenuViewController
//        self.leftMenuViewController = leftMenu as UIViewController
//        var rightMenu:RightMenuViewController = self.storyboard?.instantiateViewControllerWithIdentifier("rightMenuViewController")! as! RightMenuViewController
//        self.rightMenuViewController = rightMenu as UIViewController

        (self.rightMenuViewController as! RightMenuViewController).leftMenu = self.leftMenuViewController as! LeftMenuViewController
    }
    
}