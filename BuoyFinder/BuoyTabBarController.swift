//
//  BuoyTabBarViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 5/14/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import Foundation
import UIKit


class BuoyTabBarController : UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        let initialView = SyncManager.instance.initialView
        switch initialView {
        case .explore:
            self.selectedIndex = 0
        case .favorites:
            self.selectedIndex = 1
        case .defaultBuoy:
            self.selectedIndex = 1
        }
    }
}
