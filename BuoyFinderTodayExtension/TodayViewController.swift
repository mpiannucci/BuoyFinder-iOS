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
    var variable = BuoyDataItem.Variable.waves
    var units = Units.english
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.init(suiteName: "group.com.mpiannucci.BuoyFinder")
        
        if let defaultBuoyID = userDefaults?.string(forKey: "defaultBuoy") {
            if !self.cacheManager.checkDefaultBuoyID(buoyID: defaultBuoyID) {
                self.cacheManager.getDefaultBuoy(buoyID: defaultBuoyID) {
                    (_) in
                    self.updateUI()
                }
            }
        }
        
        if let todayVariable = userDefaults?.string(forKey: "todayVariable") {
            self.variable = BuoyDataItem.Variable(rawValue: todayVariable)!
        }
        
        if let unit = userDefaults?.string(forKey: "units") {
            self.units = Units(rawValue: unit)!
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
                    data.convert(sourceUnits: data.units, destUnits: self.units)
                    self.dataVariableLabel.text = self.variable.rawValue.capitalized
                    self.dataLabel.text = self.variableDataText(dataVariable: self.variable, data: data)
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    formatter.dateStyle = .short
                    self.locationLabel.text = buoy.name + ": " + formatter.string(from: data.date)
                }
            }
        }
    }
    
    func variableDataText(dataVariable: BuoyDataItem.Variable, data: BuoyDataItem) -> String {
        switch dataVariable {
        case .wind:
            return data.windSummary
        case .waves:
            return data.waveSummary?.simpleDescription() ?? ""
        default:
            break
        }
        
        return ""
    }
}
