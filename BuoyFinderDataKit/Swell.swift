//
//  Swell.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

public class Swell: NSCoding {
    public var waveHeight: Double
    public var period: Double
    public var direction: Double?
    public var compassDirection: String?
    var units: Units {
        didSet(oldValue) {
            if oldValue == self.units {
                return
            }
            
            switch self.units {
            case .metric:
                convertToMetric()
            default:
                convertToEnglish()
            }
        }
    }
    
    init (waveHeight: Double, period: Double, direction: Double? = nil, compassDirection: String? = nil, units: Units) {
        self.waveHeight = waveHeight
        self.period = period
        self.direction = direction
        self.compassDirection = compassDirection
        self.units = units
    }
    
    init (jsonData: JSON) {
        self.waveHeight = jsonData["wave_height"].doubleValue
        self.period = jsonData["period"].doubleValue
        self.direction = jsonData["direction"].double
        self.compassDirection = jsonData["compass_direction"].string
        self.units = Units(rawValue: jsonData["unit"].stringValue)!
    }
    
    // MARK: NSCoding
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if let height = aDecoder.decodeObject(forKey: "waveHeight") as? Double,
            let per = aDecoder.decodeObject(forKey: "period") as? Double,
            let unit = aDecoder.decodeObject(forKey: "units") as? Units {
            self.init(waveHeight: height, period: per, units: unit)
        } else {
            return nil
        }
        
        self.direction = aDecoder.decodeObject(forKey: "direction") as? Double
        self.compassDirection = aDecoder.decodeObject(forKey: "compassDirection") as? String
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.waveHeight, forKey: "waveHeight")
        aCoder.encode(self.period, forKey: "period")
        aCoder.encode(self.direction, forKey: "direction")
        aCoder.encode(self.compassDirection, forKey: "compassDirection")
        aCoder.encode(self.units, forKey: "units")
    }
    
    public func simpleDescription() -> String {
        return String(format: "%.01f", self.waveHeight) + " " + self.units.lengthUnit() + " @ " + String(format: "%.01f", self.period) + " s " + self.compassDirection!
    }
    
    public func detailedDescription() -> String {
        return String(format: "%.01f", self.waveHeight) + " " + self.units.lengthUnit() + " @ " + String(format: "%.01f", self.period) + " s " + String(format: "%3.0f", self.direction!) + self.units.degreesUnit() + " " + self.compassDirection!
    }
}

extension Swell: UnitsProtocol {

    // Assumes everything is in english -> going to metric
    public func convertToMetric() {
        self.waveHeight = Units.feetToMeters(feetValue: self.waveHeight)
    }
    
    // Assumes everything is in metric -> going to english
    public func convertToEnglish() {
        self.waveHeight = Units.metersToFeet(metricValue: self.waveHeight)
    }
}
