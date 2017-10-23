
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
        if units == kGTLRStation_ApiApiMessagesSwellMessage_Unit_Metric {
            return 6373
        } else {
            return 3961
        }
    }
    
    public func distance(location: GTLRStation_ApiApiMessagesLocationMessage, units: String = kGTLRStation_ApiApiMessagesSwellMessage_Unit_Metric) -> Double {
        let latDist = self.latitude!.doubleValue - location.latitude!.doubleValue
        let lonDist = self.longitude!.doubleValue - location.longitude!.doubleValue
        
        // Haversine formula
        let a = pow(sin((latDist.degreesToRadians)/2.0), 2.0) + cos(self.latitude!.doubleValue.degreesToRadians) * cos(location.latitude!.doubleValue.degreesToRadians) * pow(sin(lonDist.degreesToRadians/2), 2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return abs(c * self.earthsRadius(units: units))
    }
}

extension GTLRStation_ApiApiMessagesDataMessage {
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
    public func addData(newData: GTLRStation_ApiApiMessagesDataMessage) {
        self.data?.append(newData)
        self.data?.sort(by: { (first, second) -> Bool in
            return first.date!.date.compare(second.date!.date) == .orderedDescending
        })
    }
}
