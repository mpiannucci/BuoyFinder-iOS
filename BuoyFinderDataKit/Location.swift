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
    
    init(latitude: Double, longitude: Double, altitude: Double? = nil, locationName: String? = nil) {
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
}
