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
    @IBOutlet weak var locationButton: UIButton!
    
    let cacheManager = CachedBuoyManager()
    var variable: String = "WAVES"
    var units = kGTLRStationUnitsEnglish
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.init(suiteName: "group.com.mpiannucci.BuoyFinder")
        
        if let unit = userDefaults?.string(forKey: "units") {
            self.units = unit
            self.cacheManager.setDefaultUnits(newUnits: unit)
        }
        
        if let defaultBuoyID = userDefaults?.string(forKey: "defaultBuoy") {
            if !self.cacheManager.checkDefaultBuoyID(buoyID: defaultBuoyID) {
                self.cacheManager.getDefaultBuoy(buoyId: defaultBuoyID) {
                    (_) in
                    self.updateUI()
                }
            }
        }
        
        if let todayVariable = userDefaults?.string(forKey: "todayVariable") {
            self.variable = todayVariable
        }
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
    
    @IBAction func forceUpdate(_ sender: Any) {
        self.cacheManager.fetchUpdate(forceUpdate: true) { (_) in
            self.updateUI()
        }
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            guard let buoy = self.cacheManager.defaultBuoy, let data = buoy.data?.first else {
                return
            }
            
            self.dataVariableLabel.text = self.variable.capitalized
            self.dataLabel.text = data.waveSummary?.simpleDescription
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            self.locationButton.setTitle(buoy.name! + ": " + formatter.string(from: data.date!.date), for: UIControlState.normal) 
        }
    }
    
    func variableDataText(dataVariable: String, data: GTLRStation_ApiApiMessagesDataMessage) -> String {
        switch dataVariable.uppercased() {
        case "WIND":
            return data.windSummary
        case "WAVES":
            return data.waveSummary?.simpleDescription ?? ""
        case "PRESSURE":
            return data.pressureSummary
        default:
            return ""
        }
    }
}
