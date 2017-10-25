
//
//  File.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 10/17/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import Foundation


extension GTLRStation_ApiApiMessagesLocationMessage {
    private func earthsRadius(units: String) -> Double {
        if units == kGTLRStationUnitsMetric {
            return 6373
        } else {
            return 3961
        }
    }
    
    public func distance(location: GTLRStation_ApiApiMessagesLocationMessage, units: String = kGTLRStationUnitsMetric) -> Double {
        let latDist = self.latitude!.doubleValue - location.latitude!.doubleValue
        let lonDist = self.longitude!.doubleValue - location.longitude!.doubleValue
        
        // Haversine formula
        let a = pow(sin((latDist.degreesToRadians)/2.0), 2.0) + cos(self.latitude!.doubleValue.degreesToRadians) * cos(location.latitude!.doubleValue.degreesToRadians) * pow(sin(lonDist.degreesToRadians/2), 2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return abs(c * self.earthsRadius(units: units))
    }
}

extension GTLRStation_ApiApiMessagesUnitLabelMessage {
    public func label(measurement: String) -> String {
        guard let measurements = self.measurements else {
            return ""
        }
        
        for measure in measurements {
            if measure.measurement == measurement {
                return measure.label ?? ""
            }
        }
        
        return ""
    }
}

extension GTLRStation_ApiApiMessagesSwellMessage {
    public var simpleDescription: String {
        get {
            return String(format: "%.01f", self.waveHeight!.doubleValue) + " " + self.unit!.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Length)  + " @ " + String(format: "%.01f", self.period!.doubleValue) + " s " + self.compassDirection!
        }
    }
    
    public var detailedDescription: String {
        get {
            return String(format: "%.01f", self.waveHeight!.doubleValue) + " " + self.unit!.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Length) + " @ " + String(format: "%.01f", self.period!.doubleValue) + " s " + String(format: "%3.0f", self.direction!.doubleValue) + self.unit!.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Direction) + " " + self.compassDirection!
        }
    }
}

extension GTLRStation_ApiApiMessagesDataMessage {
    
    public var pressureTendencyString: String {
        get {
            guard let tendency = self.pressureTendency else {
                return ""
            }
            
            if tendency.doubleValue > 0 {
                return "RISING"
            } else if tendency.doubleValue < 0 {
                return "FALLING"
            } else {
                return "STEADY"
            }
        }
    }
    
    public var windSummary: String {
        get {
            guard let speed = self.windSpeed, let gust = self.windGust, let dir = self.windCompassDirection, let units = self.units else {
                return ""
            }
            
            return String(format: "%d (Gust %d) ", speed.intValue, gust.intValue) + units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Speed) + " " + dir
        }
    }
    
    public var pressureSummary: String {
        get {
            guard let pressure = self.pressure, let units = self.units else {
                return ""
            }
            
            return String(format: "%.2f ", pressure.doubleValue) + units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Pressure) + " " + self.pressureTendencyString
        }
    }
    
    public var weatherData: [String:String] {
        get {
            var data: [String:String] = [:]
            
            guard let units = self.units else {
                return data
            }
            
            if let windSpd = self.windSpeed, let windDir = self.windCompassDirection {
                data["Wind"] = String(format: "%.1f \(units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Speed)) %.0f\(units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Direction)) \(windDir)", windSpd.doubleValue)
            }
            if let windGst = self.windGust {
                data["Wind Gust"] = String(format: "%.1f \(units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Speed))", windGst.doubleValue)
            }
            if let waterTemp = self.waterTemperature {
                data["Water Temperature"] = String(format: "%.2f \(units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Temperature))", waterTemp.doubleValue)
            }
            if let airTemp = self.airTemperature {
                data["Air Temperature"] = String(format: "%.2f \(units.label(measurement: kGTLRStation_ApiApiMessagesMeasurementLabelMessage_Measurement_Temperature))", airTemp.doubleValue)
            }
            if let _ = self.pressure {
                data["Pressure"] = self.pressureSummary
            }
            if let level = self.waterLevel {
                data["Water Level"] = String(format: "%.1f ft", level.doubleValue)
            }
            
            return data
        }
    }
    
    public func mergeData(newData: GTLRStation_ApiApiMessagesDataMessage, dataType: String) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        switch (dataType) {
        case kGTLRStationDataTypeSpectra:
            self.waveSummary = newData.waveSummary
            self.swellComponents = newData.swellComponents
            self.steepness = newData.steepness
            self.averagePeriod = newData.averagePeriod
            self.waveSpectra = newData.waveSpectra
            self.energySpectraPlot = newData.energySpectraPlot
            self.directionSpectraPlot = newData.directionSpectraPlot
        case kGTLRStationDataTypeWeather:
            self.windSpeed = newData.windSpeed
            self.windGust = newData.windGust
            self.windDirection = newData.windDirection
            self.windCompassDirection = newData.windCompassDirection
            self.waterTemperature = newData.waterTemperature
            self.airTemperature = newData.airTemperature
            self.dewpointTemperature = newData.dewpointTemperature
            self.pressure = newData.pressure
            self.pressureTendency = newData.pressureTendency
            self.waterLevel = newData.waterLevel
        default:
            break
        }
    }
}

extension GTLRStation_ApiApiMessagesStationMessage {
    
    public var latestUpdateTime: Date? {
        get {
            return self.data?.first?.date?.date
        }
    }
    
    public func addData(newData: GTLRStation_ApiApiMessagesDataMessage) {
        guard let _ = self.data else {
            self.data = [newData]
            return
        }
        
        self.data!.append(newData)
        self.data = self.data?.filter({ (data) -> Bool in
            return data.units?.unit == newData.units?.unit
        })
        self.data!.sort(by: { (first, second) -> Bool in
            return first.date!.date.compare(second.date!.date) == .orderedDescending
        })
    }
    
    public func setData(newData: [GTLRStation_ApiApiMessagesDataMessage]) {
        self.data = newData
        self.data!.sort(by: { (first, second) -> Bool in
            return first.date!.date.compare(second.date!.date) == .orderedDescending
        })
    }
}

extension Double {
    var degreesToRadians: Double {
        get {
            return self * .pi / 180
        }
    }
    
    var radiansToDegrees: Double {
        get {
            return self * 180 / .pi
            
        }
    }
}

extension UIColor {
    // From https://stackoverflow.com/questions/11598043/get-slightly-lighter-and-darker-color-from-uicolor
    public func darker() -> UIColor {
        
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
        
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: max(r - 0.4, 0.0), green: max(g - 0.4, 0.0), blue: max(b - 0.4, 0.0), alpha: a)
        }
        
        return UIColor()
    }
    
    public func lighter() -> UIColor {
        
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
        
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: min(r + 0.4, 1.0), green: min(g + 0.4, 1.0), blue: min(b + 0.4, 1.0), alpha: a)
        }
        
        return UIColor()
    }
}
