//
//  BuoyDataItem.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

public class BuoyDataItem: NSCoding {
    
    // Date
    public var date: Date
    
    // Wind
    public var windDirection: Double?
    public var windSpeed: Double?
    public var windGust: Double?
    
    // Waves
    public var waveSummary: Swell?
    public var swellComponents: [Swell]?
    public var steepness: String?
    public var averagePeriod: Double?
    public var directionalSpectraPlotURL: String?
    public var spectralDistributionPlotURL: String?
    
    // Weather
    public var pressure: Double?
    public var airTemperature: Double?
    public var waterTemperature: Double?
    public var dewpointTemperature: Double?
    public var visibility: Double?
    public var pressureTendency: Double?
    public var waterLevel: Double?
    public var pressureTendencyString: String {
        get {
            if self.pressureTendency == nil {
                return ""
            }
            
            if self.pressureTendency! > 0 {
                return "RISING"
            } else if self.pressureTendency! < 0 {
                return "FALLING"
            } else {
                return "STEADY"
            }
        }
    }
    
    public var weatherData: [String:String] {
        get {
            var data: [String:String] = [:]
            
            if let windSpd = self.windSpeed, let windDir = self.windDirection {
                data["Wind"] = String(format: "%.1f \(self.units.string(meas: .speed)) %.0f\(self.units.string(meas: .degrees))", windSpd, windDir)
            }
            if let windGst = self.windGust {
                data["Wind Gust"] = String(format: "%.1f \(self.units.string(meas: .speed))", windGst)
            }
            if let waterTemp = self.waterTemperature {
                data["Water Temperature"] = String(format: "%.2f \(self.units.string(meas: .temperature))", waterTemp)
            }
            if let airTemp = self.airTemperature {
                data["Air Temperature"] = String(format: "%.2f \(self.units.string(meas: .temperature))", airTemp)
            }
            if let press = self.pressure {
                data["Pressure"] = String(format: "%.2f \(self.units.string(meas: .pressure)) \(self.pressureTendencyString)", press)
            }
            if let vis = self.visibility {
                data["Visibility"] = String(format: "%.1f \(self.units.string(meas: .visibility))", vis)
            }
            if let level = self.waterLevel {
                data["Water Level"] = String(format: "%.1f ft", level)
            }
            
            return data
        }
    }
    
    // Units
    public var units: Units {
        didSet(oldValue) {
            if oldValue == self.units {
                return
            }
            
            self.convert(sourceUnits: oldValue, destUnits: self.units)
        }
    }
    
    init(newDate: Date) {
        self.date = newDate
        self.units = Units.metric
        
        // Initialize everything else to nil as a shortcut
        self.windDirection = nil
        self.windSpeed = nil
        self.windGust = nil
        self.waveSummary = nil
        self.swellComponents = nil
        self.steepness = nil
        self.averagePeriod = nil
        self.directionalSpectraPlotURL = nil
        self.spectralDistributionPlotURL = nil
        self.pressure = nil
        self.airTemperature = nil
        self.waterTemperature = nil
        self.dewpointTemperature = nil
        self.visibility = nil
        self.pressureTendency = nil
        self.waterLevel = nil
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if let unit = aDecoder.decodeObject(forKey: "units") as? Units,
            let date_ = aDecoder.decodeObject(forKey: "date") as? Date {
            self.init(newDate: date_)
            self.units = unit
        } else {
            return nil
        }
        
        self.windDirection = aDecoder.decodeObject(forKey: "windDirection") as? Double
        self.windSpeed = aDecoder.decodeObject(forKey: "windSpeed") as? Double
        self.windGust = aDecoder.decodeObject(forKey: "windGust") as? Double
        self.waveSummary = aDecoder.decodeObject(forKey: "waveSummary") as? Swell
        self.swellComponents = aDecoder.decodeObject(forKey: "swellComponents") as? [Swell]
        self.steepness = aDecoder.decodeObject(forKey: "steepness") as? String
        self.averagePeriod = aDecoder.decodeObject(forKey: "averagePeriod") as? Double
        self.directionalSpectraPlotURL = aDecoder.decodeObject(forKey: "directionalSpectraPlotURL") as? String
        self.spectralDistributionPlotURL = aDecoder.decodeObject(forKey: "spectralDistributionPlotURL") as? String
        self.pressure = aDecoder.decodeObject(forKey: "pressure") as? Double
        self.airTemperature = aDecoder.decodeObject(forKey: "airTemperature") as? Double
        self.waterTemperature = aDecoder.decodeObject(forKey: "waterTemperature") as? Double
        self.dewpointTemperature = aDecoder.decodeObject(forKey: "dewpointTemperature") as? Double
        self.visibility = aDecoder.decodeObject(forKey: "visibility") as? Double
        self.pressureTendency = aDecoder.decodeObject(forKey: "pressureTendency") as? Double
        self.waterLevel = aDecoder.decodeObject(forKey: "waterLevel") as? Double
    }
    
    // MARK: NSCoder
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.date, forKey: "date")
        aCoder.encode(self.units, forKey: "units")
        aCoder.encode(self.windDirection, forKey: "windDirection")
        aCoder.encode(self.windSpeed, forKey: "windSpeed")
        aCoder.encode(self.windGust, forKey: "windGust")
        aCoder.encode(self.waveSummary, forKey: "waveSummary")
        aCoder.encode(self.swellComponents, forKey: "swellComponents")
        aCoder.encode(self.steepness, forKey: "steepness")
        aCoder.encode(self.averagePeriod, forKey: "averagePeriod")
        aCoder.encode(self.directionalSpectraPlotURL, forKey: "directionalSpectraPlotURL")
        aCoder.encode(self.spectralDistributionPlotURL, forKey: "spectralDistributionPlotURL")
        aCoder.encode(self.pressure, forKey: "pressure")
        aCoder.encode(self.airTemperature, forKey: "airTemperature")
        aCoder.encode(self.waterTemperature, forKey: "waterTemperature")
        aCoder.encode(self.dewpointTemperature, forKey: "dewpointTemperature")
        aCoder.encode(self.visibility, forKey: "visibility")
        aCoder.encode(self.pressureTendency, forKey: "pressureTendency")
        aCoder.encode(self.waterLevel, forKey: "waterLevel")
    }
    
    public func resetWaveData() {
        self.waveSummary = nil
        self.swellComponents = nil
        self.steepness = nil
        self.averagePeriod = nil
        self.directionalSpectraPlotURL = nil
        self.spectralDistributionPlotURL = nil
    }
    
    public func resetWeatherData() {
        self.windDirection = nil
        self.windSpeed = nil
        self.windGust = nil
        self.pressure = nil
        self.airTemperature = nil
        self.waterTemperature = nil
        self.dewpointTemperature = nil
        self.visibility = nil
        self.pressureTendency = nil
        self.waterLevel = nil
    }
    
    // Variables
    public enum Variable: String {
        case wind = "wind"
        case waves = "waves"
        case pressure = "pressure"
        case airTemperature = "air temperature"
        case waterTemperature = "water temperature"
        case dewpointTempurature = "dewpoint temperature"
        case visibility = "visibility"
        case waterLevel = "water level"
    }
    
    public func getDataSummary(variable: Variable) -> String? {
        // TODO
        return nil
    }
}

extension BuoyDataItem: UnitsProtocol {
    
    public func convert(sourceUnits: Units, destUnits: Units) {
        if let uWindSpeed = self.windSpeed {
            self.windSpeed = Units.convert(meas: .speed, sourceUnit: sourceUnits, destUnit: destUnits, value: uWindSpeed)
        }
        if let uWindGust = self.windGust {
            self.windGust = Units.convert(meas: .speed, sourceUnit: sourceUnits, destUnit:destUnits, value: uWindGust)
        }
        if let uAirTemp = self.airTemperature {
            self.airTemperature = Units.convert(meas: .temperature, sourceUnit: sourceUnits, destUnit: destUnits, value: uAirTemp)
        }
        if let uWaterTemp = self.waterTemperature {
            self.waterTemperature = Units.convert(meas: .temperature, sourceUnit: sourceUnits, destUnit: destUnits, value: uWaterTemp)
        }
        if let uDewpointTemp = self.dewpointTemperature {
            self.dewpointTemperature = Units.convert(meas: .temperature, sourceUnit: sourceUnits, destUnit: destUnits, value: uDewpointTemp)
        }
        if let uPressure = self.pressure {
            self.pressure = Units.convert(meas: .pressure, sourceUnit: sourceUnits, destUnit: destUnits, value: uPressure)
        }
        if let uPressureTendency = self.pressureTendency {
            self.pressureTendency = Units.convert(meas: .pressure, sourceUnit: sourceUnits, destUnit: destUnits, value: uPressureTendency)
        }
        
        self.waveSummary?.units = self.units
        if self.swellComponents != nil {
            for i in self.swellComponents!.indices {
                self.swellComponents![i].units = self.units
            }
        }
    }
}
