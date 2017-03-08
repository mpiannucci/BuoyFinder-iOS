//
//  Location.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

public class Location: NSCoding {
    
    public var latitude: Double
    public var longitude: Double
    
    // Optional
    public var altitude: Double?
    public var locationName: String?
    
    public init(latitude: Double, longitude: Double, altitude: Double? = nil, locationName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.locationName = locationName
    }
    
    // MARK: NSCoding
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if let lat = aDecoder.decodeObject(forKey: "latitude") as? Double,
            let lon = aDecoder.decodeObject(forKey: "longitude") as? Double {
            self.init(latitude: lat, longitude: lon)
        } else {
            return nil
        }
        
        self.altitude = aDecoder.decodeObject(forKey: "altitude") as? Double
        self.locationName = aDecoder.decodeObject(forKey: "locationName") as? String
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.latitude, forKey: "latitude")
        aCoder.encode(self.longitude, forKey: "longitude")
        aCoder.encode(self.altitude, forKey: "altitude")
        aCoder.encode(self.locationName, forKey: "locationName")
    }
    
    public func distance(location: Location, units: Units = .metric) -> Double {
        let latDist = self.latitude - location.latitude
        let lonDist = self.longitude - location.longitude
        
        // Haversine formula
        let a = pow(sin((latDist.degreesToRadians)/2.0), 2.0) + cos(self.latitude.degreesToRadians) * cos(location.latitude.degreesToRadians) * pow(sin(lonDist.degreesToRadians/2), 2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return abs(c * units.earthRadius())
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
