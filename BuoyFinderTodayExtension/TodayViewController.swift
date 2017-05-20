//
//  TodayViewController.swift
//  BuoyFinderTodayExtension
//
//  Created by Matthew Iannucci on 5/16/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import UIKit
import NotificationCenter
import BuoyFinderDataKit


class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var dataVariableLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    let cacheManager = CachedBuoyManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let defaultBuoyID = UserDefaults.init(suiteName: "group.com.mpiannucci.BuoyFinder")?.string(forKey: "defaultBuoy") {
            if !self.cacheManager.checkDefaultBuoyID(buoyID: defaultBuoyID) {
                self.cacheManager.getDefaultBuoy(buoyID: defaultBuoyID) {
                    (_) in
                    self.updateUI()
                }
            }
        }
        
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        self.cacheManager.fetchUpdate(forceUpdate: false) { (_) in
            self.updateUI()
        }
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            if let buoy = self.cacheManager.defaultBuoy {
                if let data = buoy.latestData {
                    self.dataVariableLabel.text = "Waves"
                    self.dataLabel.text = data.waveSummary?.simpleDescription()
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    formatter.dateStyle = .short
                    self.locationLabel.text = buoy.name + ": " + formatter.string(from: data.date)
                }
            }
        }
    }
}
