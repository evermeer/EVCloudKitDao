//
//  SettingsViewController.swift
//
//  Created by Edwin Vermeer on 25-07-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    func pushViewController(_ sender: UIViewController) {
        let viewController = UIViewController()
        viewController.title = "Pushed Controller"
        viewController.view.backgroundColor = UIColor.white
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
