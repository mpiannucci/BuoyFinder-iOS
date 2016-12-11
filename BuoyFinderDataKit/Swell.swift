//
//  Swell.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Swell {
    var waveHeight: Double
    var period: Double
    var direction: Double?
    var compassDirection: String?
    var units: Units {
        willSet(newUnits) {
            if newUnits == self.units {
                return
            }
            
            switch newUnits {
            case .Metric:
                convertToMetric()
            default:
                convertToEnglish()
            }
        }
    }
    
    init (jsonData: JSON) {
        waveHeight = jsonData["WaveHeight"].doubleValue
        period = jsonData["Period"].doubleValue
        direction = jsonData["Direction"].doubleValue
        compassDirection = jsonData["CompassDirection"].stringValue
        units = Units(rawValue: jsonData["Units"].stringValue)!
    }
}

extension Swell: UnitsProtocol {

    // Assumes everything is in english -> going to metric
    public mutating func convertToMetric() {
        self.waveHeight = self.waveHeight / 3.28
    }
    
    // Assumes everything is in metric -> going to english
    public mutating func convertToEnglish() {
        self.waveHeight = self.waveHeight * 3.28
    }
}
