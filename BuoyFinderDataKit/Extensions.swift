
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

extension GTLRStation_ApiApiMessagesStationMessage {
    // TODO: Buoy station extensions
    
    public var needsUpdate: Bool {
        get {
            guard let data = self.data, data.count > 0, let latestUpdateTime = data[0].date else {
                return true
            }
            
            return latestUpdateTime.date.timeIntervalSinceNow > 30*60
        }
    }
    
    public func importData(newData: GTLRStation_ApiApiMessagesDataMessage, dataType: String? = nil) {
        switch dataType {
        case .some(kGTLRStationDataTypeSpectra):
            break
        case .some(kGTLRStationDataTypeWaves):
            break
        case .some(kGTLRStationDataTypeWeather):
            break
        case .none:
            break
        default:
            return
        }
    }
}
