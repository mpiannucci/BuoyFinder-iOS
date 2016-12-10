//
//  Buoy.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

class Buoy: NSObject {
    
    // Required
    var stationID: String
    var location: Location
    
    // Optional
    var owner: String?
    var program: String?
    var buoyType: String?
    var active: Bool?
    var currents: Bool?
    var waterQuality: Bool?
    var dart: Bool?
    
    // Data
    var latestData: [BuoyDataItem]?
    
    init(stationID_: String, location_: Location) {
        self.stationID = stationID_
        self.location = location_
        
        super.init()
    }
    
    init(jsonData: JSON) {
        self.stationID = jsonData["StationID"].stringValue
        self.location = Location(latitude: jsonData["Latitude"].doubleValue, longitude: jsonData["Longitude"].doubleValue, altitude: jsonData["Elevation"].doubleValue, locationName: jsonData["LocationName"].stringValue)
        
        self.owner = jsonData["Owner"].string
        self.program = jsonData["PGM"].string
        self.buoyType = jsonData["Type"].string
        
        self.active = (jsonData["Active"].stringValue == "y") as Bool?
        self.currents = (jsonData["Currents"].stringValue == "y") as Bool?
        self.waterQuality = (jsonData["WaterQuality"].stringValue == "y") as Bool?
        self.dart = (jsonData["Dart"].stringValue == "y") as Bool?
        
        self.latestData = nil
    }
}
