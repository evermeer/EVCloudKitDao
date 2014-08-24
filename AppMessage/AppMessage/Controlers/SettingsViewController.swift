//
//  SettingsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 mirabeau. All rights reserved.
//

class SettingsViewController : UIViewController {
    func pushViewController(sender: UIViewController) {
        var viewController = UIViewController()
        viewController.title = "Pushed Controller"
        viewController.view.backgroundColor = UIColor.whiteColor()
        self.navigationController.pushViewController(viewController, animated: true)
    }
}