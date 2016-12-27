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
            case .Metric:
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
        waveHeight = jsonData["WaveHeight"].doubleValue
        period = jsonData["Period"].doubleValue
        direction = jsonData["Direction"].doubleValue
        compassDirection = jsonData["CompassDirection"].stringValue
        units = Units(rawValue: jsonData["Units"].stringValue)!
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
