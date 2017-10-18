
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
