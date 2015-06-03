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
        self.animationDuration = 0.2
        self.contentViewShadowColor = .blackColor()
        self.contentViewShadowOffset = CGSizeMake(0, 0)
        self.contentViewShadowOpacity = 0.6
        self.contentViewShadowRadius = 12
        self.contentViewShadowEnabled = true
        self.backgroundImage = UIImage(named:"Default-568h")

        if let rightMenu = self.rightMenuViewController as? RightMenuViewController {
            if let leftMenu = self.leftMenuViewController as? LeftMenuViewController {
                rightMenu.leftMenu = leftMenu
            }
        }
    }
}
